(ns proc-test
  (require proc p [defproc defun do let const >> list])
  (require testing t))

;; This module is responsible for defining procedural, or imperative constructs for Muon.
;; This is done in terms of the `p/step` predicate, which implements a state-machine using the [QEPL](muon-clj/qepl.md).

;; ## Terminology
;; We use the term _state_ to refer to a legal first argument of `p/step`.
;; One common but specific case for state is a _procedural expressions_, or _PExpr_ for short.
;; This is a term which corresponds to some computation that needs to take place (possibly, including side effects),
;; which evaluates to some value.
;; The building blocks of computation, the smallest, indivisible pieces of the interpretation of a PExpr are
;; _native expressions_, or _NExprs_ for short.
;; NExprs are expressions in the host language (Clojure in the original implementation of Muon) which are
;; often simple, primitive operations, evaluated by the QEPL.

;; ## Constants and Pass Through
;; A `(const :value)` PExpr simply returns the constant it holds as argument.
(t/test-value const-returns-value
              (p/step (const 42) some-input-to-be-ignored (return :value))
              :value
              42)

;; An `input` PExpr will return whatever input it is given.
(t/test-value input-returns-its-input
              (p/step p/input 42 (return :value))
              :value
              42)

;; # NExpr as PExpr
;; The `>>` operator turns NExprs into PExprs.
;; For example, the PExpr `(>> println "hello, world")` represents the NExpr `(println "hello, world")`.
;; `step`ping through it will result in a transition to an `input` state,
;; such that the value the NExpr evaluates to is returned.
(t/test-value >>-turns-nexpr-to-pexpr
              (t/qepl-sim (>> some-nexpr 1 2 3) () :retval
                          (t/sequential
                           (some-nexpr 1 2 3) 42)) :retval 42)

;; ## Doing Things in Sequence
;; The `do` PExpr contains zero or more PExprs that are evaluated in sequence.
;; The `do` PExpr evaluates to the value returned by its last element.
(t/test-value do-empty-is-done
              (t/qepl-sim (do) () :retval
                          (t/sequential)) :retval ())
(t/test-value do-executes-in-sequence
              (t/qepl-sim (do
                            (>> println "one")
                            (do (>> println "two")
                                (>> println "three"))
                            (const 42)) () :retval
                          (t/sequential
                           (println "one") 1
                           (println "two") 2
                           (println "three") 3)) :retval 42)

;; ## Constructing Lists
;; The `list` PExpr takes zero or more PExprs, evaluates them and returns a list of their values.
(t/test-value list-empty
              (t/qepl-sim (list) () :retval
                          (t/sequential)) :retval ())
(t/test-value list-one-elem
              (t/qepl-sim (p/list (const 42)) () :retval
                          (t/sequential)) :retval (42))
(t/test-value list-non-empty
              (t/qepl-sim (p/list (const 42) (>> input-line)) () :retval
                          (t/sequential
                           (input-line) "foo")) :retval (42 "foo"))

;; ## Letting Values be Captured
;; The `let` PExpr takes a vector of bindings ((variable, PExpr) pairs) and zero or more PExprs.
;; It evaluates each PExpr in the bindings and binds the result to the associated variable.
;; Then it evaluates the PExprs in the body for their side effects, just like a `do`,
;; returning the value returned by the last of them.
(t/test-value let-as-do
              (t/qepl-sim (let []
                            (>> println "one")
                            (>> println "two")
                            (>> println "three")) () :retval
                          (t/sequential
                           (println "one") 1
                           (println "two") 2
                           (println "three") 3)) :retval 3)

(t/test-value let-binds-vars
              (t/qepl-sim (let [:name (do (>> println "What is your name?")
                                          (>> input-line))
                                :greeting (>> strcat "Hello, " :name)]
                            (>> println :greeting)) () :retval
                          (t/sequential
                           (println "What is your name?") ()
                           (input-line) "Muon"
                           (strcat "Hello, " "Muon") "Hello, Muon"
                           (println "Hello, Muon") ())) :retval ())

;; ## Procedures
;; Procedures are abstractions over PExprs.
;; A procedure is defined using the `defproc` predicate, which takes a PExpr as head and zero or more PExprs as its body.
;; This defines the head as a new PExpr.
(defproc (prompt :prompt)
  (>> println :prompt)
  (>> input-line))

(defproc (greet :name)
  (let [:text (>> strcat "Hello, " :name)]
    (>> println :text)))

(t/test-value procedure-call
              (t/qepl-sim (let [:name (prompt "What is your name?")]
                            (greet :name)) () :retval
                          (t/sequential
                           (println "What is your name?") ()
                           (input-line) "Muon"
                           (strcat "Hello, " "Muon") "Hello, Muon"
                           (println "Hello, Muon") ())) :retval ())

;; Procedures can be recursive and can have different definitions for different patterns (e.g., different number of arguments).

(defproc (greet-all))
(defproc (greet-all :name :names ...)
  (greet :name)
  (greet-all :names ...))
(t/test-value procedure-recursive-call
              (t/qepl-sim (greet-all "Clojure" "Muon") () :retval
                          (t/sequential
                           (strcat "Hello, " "Clojure") "Hello, Clojure"
                           (println "Hello, Clojure") ()
                           (strcat "Hello, " "Muon") "Hello, Muon"
                           (println "Hello, Muon") ())) :retval ())

;; __Note:__ Procedures are a low-level concept and should be used with care.
;; If you are looking for an abstraction more in line with functions in imperative/functional programming languages look at [functions](#functions).

;; ## Functions
;; Functions, like procedures are an abstraction that allow programmers to define new PExprs.
;; However, unlike procedures, they work in a way that is more in line with the way functions work in other languages.
;; This means that they follow [eager evaluation](https://en.wikipedia.org/wiki/Eager_evaluation),
;; evaluating all parameters before the body of the function.
;;
;; At the core of the semantics of a function is the binding of arguments to parameters.
;; The predicate `(p/bind-args :params :args :bindings)` creates a `let`-style bindings out of a vector of parameters declared by a function
;; and a list of arguments given by a function.
(t/test-value bind-args-empty-params-empty-args
              (p/bind-args [] () :bindings)
              :bindings [])
(t/test-value bind-args-matching-number-of-params-and-args
              (p/bind-args [one two three] (1 2 3) :bindings)
              :bindings [one 1
                         two 2
                         three 3])
;; For variadic functions, replace the `:params` vector with the form `(p/var :positional :others)`, where
;; `:positional` is a params vector as in the default and `:others` is a variable intended to capture the rest of the list of arguments.
(t/test-value bind-args-variadic
              (p/bind-args (p/var [one] twothree) (1 2 3) :bindings)
              :bindings [one 1
                         twothree (const (2 3))])

;; `(defun :name :params :body ...)` defines a function.
;; For example, the following function takes any number of strings and prints them.
(defun print-all [])
(defun print-all (p/var [:str] :strs)
  (>> println :str)
  (print-all :strs ...))

(t/test-value defun-defines-function
              (t/qepl-sim (print-all (const "one")
                                     (const "two")) () :retval
                          (t/sequential
                           (println "one") ()
                           (println "two") ())) :retval ())
