  * [Terminology](#terminology)
  * [Constants and Pass Through](#constants-and-pass-through)
* [NExpr as PExpr](#nexpr-as-pexpr)
  * [Doing Things in Sequence](#doing-things-in-sequence)
  * [Constructing Lists](#constructing-lists)
  * [Letting Values be Captured](#letting-values-be-captured)
  * [Procedures](#procedures)
  * [Functions](#functions)
  * [Functional Programming](#functional-programming)
```clojure
(ns proc-test
  (require proc p [defproc defun do let ' >> list partial])
  (require testing t))

```
This module is responsible for defining procedural, or imperative 'ructs for Muon.
This is done in terms of the `p/step` predicate, which implements a state-machine using the [QEPL](muon-clj/qepl.md).

## Terminology
We use the term _state_ to refer to a legal first argument of `p/step`.
One common but specific case for state is a _procedural expressions_, or _PExpr_ for short.
This is a term which corresponds to some computation that needs to take place (possibly, including side effects),
which evaluates to some value.
The building blocks of computation, the smallest, indivisible pieces of the interpretation of a PExpr are
_native expressions_, or _NExprs_ for short.
NExprs are expressions in the host language (Clojure in the original implementation of Muon) which are
often simple, primitive operations, evaluated by the QEPL.

## Constants and Pass Through
A `(' :value)` PExpr simply returns the constant it holds as argument.
```clojure
(t/test-value '-returns-value
              (p/step (' 42) some-input-to-be-ignored (return :value))
              :value
              42)

```
An `input` PExpr will return whatever input it is given.
```clojure
(t/test-value input-returns-its-input
              (p/step p/input 42 (return :value))
              :value
              42)

```
# NExpr as PExpr
The `>>` operator turns NExprs into PExprs.
For example, the PExpr `(>> println "hello, world")` represents the NExpr `(println "hello, world")`.
`step`ping through it will result in a transition to an `input` state,
such that the value the NExpr evaluates to is returned.
```clojure
(t/test-model >>-turns-nexpr-to-pexpr
              (>> some-nexpr 1 2 3) 42
              (t/sequential
               (some-nexpr 1 2 3) 42))

```
## Doing Things in Sequence
The `do` PExpr contains zero or more PExprs that are evaluated in sequence.
The `do` PExpr evaluates to the value returned by its last element.
```clojure
(t/test-model do-empty-is-done
              (do) ()
              (t/sequential))
(t/test-model do-executes-in-sequence
              (do
                (>> println "one")
                (do (>> println "two")
                    (>> println "three"))
                (' 42)) 42
              (t/sequential
               (println "one") 1
               (println "two") 2
               (println "three") 3))

```
## Constructing Lists
The `list` PExpr takes zero or more PExprs, evaluates them and returns a list of their values.
```clojure
(t/test-model list-empty
              (list) ()
              (t/sequential))
(t/test-model list-one-elem
              (p/list (' 42)) (42)
              (t/sequential))
(t/test-model list-non-empty
              (p/list (' 42) (>> input-line)) (42 "foo")
              (t/sequential
               (input-line) "foo"))

```
## Letting Values be Captured
The `let` PExpr takes a vector of bindings ((variable, PExpr) pairs) and zero or more PExprs.
It evaluates each PExpr in the bindings and binds the result to the associated variable.
Then it evaluates the PExprs in the body for their side effects, just like a `do`,
returning the value returned by the last of them.
```clojure
(t/test-model let-as-do
              (let []
                (>> println "one")
                (>> println "two")
                (>> println "three")) 3
              (t/sequential
               (println "one") 1
               (println "two") 2
               (println "three") 3))

(t/test-model let-binds-vars
              (let [:name (do (>> println "What is your name?")
                              (>> input-line))
                    :greeting (>> strcat "Hello, " :name)]
                (>> println :greeting)) ()
              (t/sequential
               (println "What is your name?") ()
               (input-line) "Muon"
               (strcat "Hello, " "Muon") "Hello, Muon"
               (println "Hello, Muon") ()))

```
## Procedures
Procedures are abstractions over PExprs.
A procedure is defined using the `defproc` predicate, which takes a PExpr as head and zero or more PExprs as its body.
This defines the head as a new PExpr.
```clojure
(defproc (prompt :prompt)
  (>> println :prompt)
  (>> input-line))

(defproc (greet :name)
  (let [:text (>> strcat "Hello, " :name)]
    (>> println :text)))

(t/test-model procedure-call
              (let [:name (prompt "What is your name?")]
                (greet :name)) ()
              (t/sequential
               (println "What is your name?") ()
               (input-line) "Muon"
               (strcat "Hello, " "Muon") "Hello, Muon"
               (println "Hello, Muon") ()))

```
Procedures can be recursive and can have different definitions for different patterns (e.g., different number of arguments).

```clojure
(defproc (greet-all))
(defproc (greet-all :name :names ...)
  (greet :name)
  (greet-all :names ...))
(t/test-model procedure-recursive-call
              (greet-all "Clojure" "Muon") ()
              (t/sequential
               (strcat "Hello, " "Clojure") "Hello, Clojure"
               (println "Hello, Clojure") ()
               (strcat "Hello, " "Muon") "Hello, Muon"
               (println "Hello, Muon") ()))

```
__Note:__ Procedures are a low-level concept and should be used with care.
If you are looking for an abstraction more in line with functions in imperative/functional programming languages look at [functions](#functions).

## Functions
Functions, like procedures are an abstraction that allow programmers to define new PExprs.
However, unlike procedures, they work in a way that is more in line with the way functions work in other languages.
This means that they follow [eager evaluation](https://en.wikipedia.org/wiki/Eager_evaluation),
evaluating all parameters before the body of the function.
At the core of the semantics of a function is the binding of arguments to parameters.
The predicate `(p/bind-args :params :args :bindings)` creates a `let`-style bindings out of a vector of parameters declared by a function
and a list of arguments given by a function.
```clojure
(t/test-value bind-args-empty-params-empty-args
              (p/bind-args [] () :bindings)
              :bindings [])
(t/test-value bind-args-matching-number-of-params-and-args
              (p/bind-args [one two three] (1 2 3) :bindings)
              :bindings [one 1
                         two 2
                         three 3])
```
For variadic functions, replace the `:params` vector with the form `(p/var :positional :others)`, where
`:positional` is a params vector as in the default and `:others` is a variable intended to capture the rest of the list of arguments.
```clojure
(t/test-value bind-args-variadic
              (p/bind-args (p/var [one] twothree) (1 2 3) :bindings)
              :bindings [one 1
                         twothree (' (2 3))])

```
`(defun :name :params :body ...)` defines a function.
For example, the following function takes any number of strings and prints them.
```clojure
(defun print-all [])
(defun print-all (p/var [:str] :strs)
  (>> println :str)
  (print-all :strs ...))

(t/test-model defun-defines-function
              (print-all ('"one")
                         ('"two")) ()
              (t/sequential
               (println "one") ()
               (println "two") ()))

```
## Functional Programming

To support functional programming we are required to treat functions as first-class values.
This is achievable without any explicit support, just by the fact that both expressions and values are Muon terms.
Consider the following two functions, `foo` and `bar`, which print "foo" and "bar", respectively.
```clojure
(defun foo []
  (>> println "foo"))
(defun bar []
  (>> println "bar"))

```
Now, consider another function `do-something`, which takes as parameter a function and calls it.
```clojure
(defun do-something [:f]
  (>> println "And the function is:")
  (:f))

```
Calling `do-something` with `foo` will print "foo" and calling `do-something` with `bar` will print "bar".
```clojure
(t/test-model using-function-name-as-parameter
              (do
                (do-something foo)
                (do-something bar))
              ()
              (t/sequential
               (println "And the function is:") ()
               (println "foo") ()
               (println "And the function is:") ()
               (println "bar") ()))

```
Note that we did not have to quote the function names because a function name evaluates to itself.
```clojure
(t/test-model function-name-evaluates-to-itself
              foo
              foo
              (t/sequential))

```
The `partial` function takes a name of a function and zero or more parameters.
It evaluates the parameters and returns a closure that specifies the function and parameter values.
```clojure
(t/test-model partial-returns-closure
              (partial print-all (>> input-line) (>> input-line))
              (p/closure print-all ("foo" "bar"))
              (t/sequential
               (input-line) "foo"
               (input-line) "bar"))

```
A list that has a `closure` as its first element is a PExpr and is equivalent to calling the function
associated with the closure with a concatenation of the parameters from the closure (quoted) and the
parameters in the list.
For example, the following call to `print-all` will print both the closure parameters and the actual parameters.
```clojure
(t/test-model closure-call
              ((p/closure print-all ("foo" "bar")) (' "baz"))
              ()
              (t/sequential
               (println "foo") ()
               (println "bar") ()
               (println "baz") ()))

```
The following example puts this together.
```clojure
(t/test-model partial-call
              (let [:f (partial print-all (>> input-line) (>> input-line))]
                (:f (' "baz")))
              ()
              (t/sequential
               (input-line) "foo"
               (input-line) "bar"
               (println "foo") ()
               (println "bar") ()
               (println "baz") ()))
```

