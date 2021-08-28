(ns expr-test
  (require testing t)
  (require expr ex [quote >> list do let let-value defexpr defun if partial])
  (use proc p [step]))

;; # expr: A Lisp-like Language

;; This module defines a Lisp-like expression language, facilitating impure functional programming.
;; Evaluation of such expressions is done through the [QEPL](muon-clj/qepl.md).
;; It works by defining solutions to the `step` predicate, which is queried by the QEPL.
;; Every expression should have a solution to the `step` predicate, either returning a value or
;; providing a continuation that consists of an _action_, which is an expression in the implementation
;; language (e.g., Clojure) and a next expression to evaluate, given the result of that action.

;; In this doc we use [QEMU simulation](testing.md#qepl-simulation) to demonstrate the evaluation
;; of expressions.

;; ## Quotation and Self Evaluation

;; As in most Lisps, the `quote` expression evaluates to its (one and only) argument.
(ex/test-expr quote-evaluates-to-argument
              (quote (foo bar)) ;; This expression
              (foo bar)         ;; evaluates to this value
              t/pure)   ;; by computing these steps (none).

;; Literal types do not need to be quoted. They evaluate to themselves.
(ex/test-expr int-evaluates-to-itself
              42 42 t/pure)
(ex/test-expr float-evaluates-to-itself
              3.14 3.14 t/pure)
(ex/test-expr string-evaluates-to-itself
              "foo" "foo" t/pure)
(ex/test-expr bool-evaluates-to-itself
              true true t/pure)

;; ## Actions
;; Actions are lists containing an _action name_ as a first element and zero or more arguments following it.
;; The action names are host-language-agnostic, with a translation layer translating them to function names
;; in the host language.
;; The arguments should be _values_, not _expressions_.
;; This means that each action corresponds to _exactly one_ operation to be performed
;; by the host language.
;; Complex expressions are broken down into a sequence of actions by this expression language.

;; To call an action from an expression, use the `>>` operator.
;; An expression that uses the `>>` operator evaluates to the value returned by the action.

;; **Note**: In the examples provided in this doc we use made-up actions, as the language is agnostic to which
;; actions are actually used. Documentation on which actions are actually available is TBD.
(t/test-value >>-calls-an-action
              (step (ex/bind (>> some-action 1 2 3) [some bindings]) () (continue :action :_next))
              :action
              (some-action 1 2 3))

(ex/test-expr >>-returns-action-result
              (>> the-big-question-of "life" "universe" "everything")
              42
              (t/sequential
               (the-big-question-of "life" "universe" "everything") 42))

;; ## List Construction

;; A `list` expression takes zero or more expressions as arguments, evaluates them and returns a list of their respective values.
(ex/test-expr list-creates-list
              (list (>> get-foo) (>> get-bar))
              ("foo" "bar")
              (t/by-def (2)))

(t/defaction (get-foo) "foo")
(t/defaction (get-bar) "bar")

;; ## Control Flow

;; The `do` expression takes zero or more sub-expressions and evaluates them in-order.
;; It returns the value of the last expression.
(ex/test-expr do-with-no-subexprs
              (do)
              ()
              t/pure)
(ex/test-expr do-with-subexprs
              (do
                (>> do-something)
                (>> do-something-else))
              3
              (t/sequential
               (do-something) 2
               (do-something-else) 3))

;; The `let` expression takes a vector of bindings (variable-expression pairs) and zero or more expressions.
;; With no bindings, it works exactly like a `do` expression.
(ex/test-expr let-without-bindings
              (let []
                (>> do-something)
                (>> do-something-else))
              3
              (t/sequential
               (do-something) 2
               (do-something-else) 3))

;; Given bindings, the bound expressions are being evaluated in order before evaluating the body.
(ex/test-expr let-evaluates-bindings-in-order
              (let [foo (>> get-foo)
                    bar (>> get-bar)]
                (>> do-something))
              2
              (t/sequential
               (get-foo) "foo"
               (get-bar) "bar"
               (do-something) 2))

;; The variable in each pair is bound to the result of evaluating the expression.
(ex/test-expr let-binds-vars-to-expr-results
              (let [foo (>> get-foo)]
                foo)
              "foo"
              (t/by-def (1)))

;; `let-value` is similar to `let` with a few differences:

;; 1. It uses `:logic-variables` rather than symbols as the binding variables.
;; 2. Rather than creating a [binding](#bindings) between the variable and the value, `let-value` actually binds the logic variable to the value.
;; 3. The logic variable is bound to a _value_ and not an _expression_, making it suitable for use in certain places (e.g., inside [quotes](#quotation-and-self-evaluation)) but not in general expressions.

;; Without bindings, it behaves like a `do`.
(ex/test-expr let-value-without-bindings
              (let-value []
                         (>> do-something)
                         (>> do-something-else))
              3
              (t/sequential
               (do-something) 2
               (do-something-else) 3))

(ex/test-expr let-value-evaluates-bindings-in-order
              (let-value [:foo (>> get-foo)
                          :bar (>> get-bar)]
                         (>> do-something))
              2
              (t/sequential
               (get-foo) "foo"
               (get-bar) "bar"
               (do-something) 2))

;; `let-value` is very useful for constructing actions
(ex/test-expr let-value-constructs-actions
              (let-value [:foo (>> get-foo)
                          :bar (>> get-bar)]
                         (>> do-something :foo :bar))
              2
              (t/sequential
               (get-foo) "foo"
               (get-bar) "bar"
               (do-something "foo" "bar") 2))

;; ## Definitions

;; In this section we describe the ways in which new expression types can be introduced.
;; Definitions are done through predicates that are being consulted during the evaluation
;; process of expressions. By defining new solutions for said predicates we can introduce
;; new types of expressions.

;; ### Expression Definitions

;; `defepxr` allows us to define one (new) expression in terms of another.
;; It takes a pattern of the expression to be defined and a pattern of the pattern
;; it would be defined as. Both the defined expression and the expression used for defining
;; it share `:logic-variables` which are bound to sub-expressions.

;; In the following example we define the `println` expression, which takes one
;; expression as parameter, evaluates it (using a `let-value` expression) and invokes
;; the fictional `println` action with the result as parameter.
(defexpr (println :str)
  (let-value [:str-val :str]
    (>> println :str-val)))

;; Now we can call the new `println` expression.
(ex/test-expr defexpr-defines-expr
              (println "foo")
              ()
              (t/sequential
               (println "foo") ()))

;; Since `defexpr` takes a pattern of the expression it defines,
;; it is very useful for defining variadic expressions.
;; The following example extends the previous definition of `println`, adding support for
;; two arguments and above.
(defexpr (println :first :second :rest ...)
  (do
    (println :first)
    (println :second :rest ...)))

;; Now we can call `println` with any number of arguments.
(ex/test-expr defexpr-defines-variadic-expr
              (println "one" "two" "three")
              ()
              (t/sequential
               (println "one") ()
               (println "two") ()
               (println "three") ()))

;; In comparison to other Lisps, `defexpr` is similar to a macro definition in that it operates at the
;; expression level. The expression being defined shares the call-site's lexical scope.
(ex/test-expr defexpr-shares-lexical-scope
              (let [x "foo"]
                (println x))
              ()
              (t/sequential
               (println "foo") ()))

;; In the above example, the definition of `println` received the expression `x` as parameter.
;; Then, `x` was evaluated as part of the expression `println` translated into.

;; Obviosly, this behavior can also be abused, as in the following example.
(defexpr do-something-surprising
  (println some-message))

;; In the above definition we defined the expression `do-something-surprising` as a printing of
;; `some-message`, a variable we did not define in this scope. Now, if we bind `some-message` to a string
;; `do-something-surprising` will print it.
(ex/test-expr defexpr-lexical-scope2
              (let [some-message "don't do this!"]
                do-something-surprising)
              ()
              (t/sequential
               (println "don't do this!") ()))

;; ### Function Definitions

;; In contrast to `defexpr`, which is comparable with a macro definition, `defun` is a function definition.
;; Simlalr to its counterpart in other Lisps, the syntax of `defun` consists of a function name,
;; a vector of parameters (symbols, not logic variables) and zero or more expressions acting as the body.
;; A call to a function defined using `defun` will always start by evaluating the arguments first,
;; and only then will the body be evaluated as well.

;; In the following example we define two functions. The first is `strcat` which wraps around
;; the (imaginary) `strcat` action. It unquotes the parameters to be able to use the plain strings
;; in an action.
(defun strcat [s1 s2]
  (let-value [:s1 s1
              :s2 s2]
             (>> strcat :s1 :s2)))

;; Then we define the function `greet` which takes a name of a person as parameter and prints a
;; greeting for that person.
(defun greet [name]
  (println (strcat "Hello, " name)))

;; Calling this function will first concatenate "Hello, " to the value we give as argument,
;; and then prints the resulting string.
(ex/test-expr defun-defines-functions
              (greet "Muon")
              ()
              (t/sequential
               (strcat "Hello, " "Muon") "Hello, Muon"
               (println "Hello, Muon") ()))

;; #### Bindging Arguments to Parameters

;; Internally, the `bind-args` predicate creates a bindings vector out of an arguments vector and a
;; list of parameter expressions.
(t/test-value bind-args-returns-empty-bindings-for-no-params
              (ex/bind-args [] () :result)
              :result [])
(t/test-value bind-args-returns-bindings-for-params-with-matching-args
              (ex/bind-args [param1 param2 param3] (arg1 arg2 arg3) :result)
              :result [param1 arg1
                       param2 arg2
                       param3 arg3])

;; ## Conditionals

;; Similar to Clojure and many other functional programming languages, an `if` expression takes three expressions:
;; _condition_, _then_ and _else_. It begins by evaluating the condition. If it evaluates to `true`, the _then_ part
;; is being evaluated.
(ex/test-expr if-with-true-condition
               (if (>> some-condition-action)
                 (>> some-then-action)
                 (>> some-else-action))
               then-result
               (t/sequential
                (some-condition-action) true
                (some-then-action) then-result))

;; And if it evaluates to `false`, the _else_ part is being evaluated.
(ex/test-expr if-with-false-condition
              (if (>> some-condition-action)
                (>> some-then-action)
                (>> some-else-action))
              else-result
              (t/sequential
               (some-condition-action) false
               (some-else-action) else-result))

;; ## Functional Programming

;; To support functional programming we need to allow functions to be first-class values.
;; We already use pattern matching on the function name to make function calls,
;; so passing a function name to a function can allow that function to call it
;; by placing the name as a first element in a list.
;; However, for this to be convenient, function names should be self-evaluating.
;; For example, given the above definition of `greet`, the symbol `greet` evaluates to itself.
(t/test-model* defun-makes-function-name-self-evaluate
               greet
               greet
               t/pure)

;; Now we can define a function that takes a function name as parameter and calls it with some
;; arguments.
(defun with-muon [:f]
  (:f "Muon"))

(t/test-model* call-with-function-name
               (with-muon greet)
               ()
               (t/sequential
                (strcat "Hello, " "Muon") "Hello, Muon"
                (println "Hello, Muon") ()))

;; Note that for this to work we needed to make `((quote foo) args ...)` be accepted as `(foo args ...)`.
(t/test-model* quoted-function
               ((quote greet) "Muon")
               ()
               (t/sequential
                (strcat "Hello, " "Muon") "Hello, Muon"
                (println "Hello, Muon") ()))

;; ### Closures

;; A closure is a combination of a function to be called with _some_ of its arguments.
;; The `partial` function takes a function name and zero or more arguments for it
;; and returns a closure term, containing the function name and the argument values.

;; In the following example we call `partial` with some function name and two calls
;; to the fictional `input-line` action.
;; The actions are performed before returning the closure.
(t/test-model* partial-returns-closure
               (partial myfunc (>> input-line) (>> input-line))
               (ex/closure myfunc (quote "foo") (quote "bar"))
               (t/sequential
                (input-line) "foo"
                (input-line) "bar"))

;; A closure can be used in place of a function name as the first element of a list expression.
;; In such a case, the function named by the closure will be evaluated, with a concatenation of
;; the colsure arguments with the arguments given as the rest of the list as arguments to the function.
(t/test-model* closure-call
               ((ex/closure println (quote "foo") (quote "bar")) "baz")
               ()
               (t/sequential
                (println "foo") ()
                (println "bar") ()
                (println "baz") ()))

;; Combining the two elements, we can have higher-order functions, ones that receive and return functions.

;; In the following example we will use both to eventually print "Hello, Muon".
;; First, the `add-prefix` function takes a string and returns a function that takes another string and
;; concatenates the two.
(defun add-prefix [:prefix]
  (partial strcat :prefix))

;; Now we can use the previously-defined `with-muon` to do what we want:
(t/test-model* partial-used-to-greet
               (println (with-muon (add-prefix "Hello, ")))
               ()
               (t/sequential
                (strcat "Hello, " "Muon") "Hello, Muon"
                (println "Hello, Muon") ()))

;; ### A Note About Lamdas

;; A reader may wonder, at this point, why we haven't introduced lambdas. After all, they are considered the
;;  hallmark of functional programming languages.
;; While there are a few different ways to implement lambdas in Muon, none of them is as simple as the
;; features we have described so far.

;; To understand why this is, we need to understand how Muon, as a logic-programming language, treats variables.
;; Logic variables (e.g., `:var`) represent _unknowns_. This means that each variable actually holds one value,
;; we just don't know what it is.

;; Every time a computation considers a statement (e.g., a `defun` or `defexpr`), it takes its variables to be
;; _fresh_, meaning that the values they can take are independent of any past values other invocations of the
;; same statement were given.

;; However, a lambda is different. A lambda is a _term_, not a statement. Once created, we want to use it and often,
;; reuse it with different values. Unfortunately, once we "uncover" the value of an "unknown", it cannot be uncovered.
;; In other words, the concept of an unknown, which works well for definitions, doesn't work well for lambdas.

;; To demonstrate this we will define our own concept of a lambda, the way it should intuitively be defined.
;; First we will make it self-evaluate, so it can be used as an expression.
(defexpr (lambda :params :body ...)
  (quote (lambda :params :body ...)))

;; Next, we will define an invocation of this lambda by converting the invocation to a `let` expression.
(<- (defexpr ((lambda :params :body ...) :args ...)
      (let :bindings :body ...))
    (ex/bind-args :params :args :bindings))

;; Now we can use lambdas... but only once per lambda.
(t/test-model* lambda-use-once
               (with-muon (lambda [:who] (println (strcat "Hello, " :who))))
               ()
               (t/by-def (2)))

(t/defaction (strcat "Hello, " "Muon") "Hello, Muon")
(t/defaction (println :_s) ())
;; But the same lambda cannot be used more than once (with different arguments):
(t/test-failure lambda-use-twice
                (t/qepl-sim
                 (let [:greeter (lambda [:who] (println (strcat "Hello, " :who)))]
                   (:greeter "World")
                   (:greeter "Muon"))
                 ()
                 ()
                 (t/by-def (4))))

(t/defaction (strcat "Hello, " "World") "Hello, World")

;; ## Under the Hood

;; ### Bindings

;; A binding consists of an expression and an associated vector of _variable bindings_.
;; These variable bingins consist of a symbol representing the variable (not to be confused with a `:logic-variable`),
;; and a value associated with this variable.

;; Variables evaluate to their bound value within a binding.
(t/test-model bind-evaluates-first-var-to-value
              (ex/bind x [x 42
                          y 74])
              42
              t/pure)
(t/test-model bind-evaluates-other-var-to-value
              (ex/bind x [y 74
                          x 42])
              42
              t/pure)

;; Expressions do not stand on their own, but rather require binding to be evaluated.
;; To ease testing of expressions (i.e., make it so that we do not have to provide the binding every time),
;; we introduce the `test-expr` test definition. For example:
(ex/test-expr int-evaluates-to-itself
              42 42 t/pure)

;; This definition defines a corresponding `t/test-model`:
(t/test-value test-expr-defines-test-model
              (t/test-model int-evaluates-to-itself :args ...)
              :args
              ((ex/bind 42 []) 42 t/pure))
the-end