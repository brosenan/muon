* [expr: A Lisp-like-Language](#expr:-a-lisp-like-language)
  * [Quotation and Self Evaluation](#quotation-and-self-evaluation)
  * [Actions](#actions)
  * [List Construction](#list-construction)
  * [Control Flow](#control-flow)
  * [Definitions](#definitions)
    * [Expression Definitions](#expression-definitions)
    * [Function Definitions](#function-definitions)
      * [Bindging Arguments to Parameters](#bindging-arguments-to-parameters)
  * [Conditionals](#conditionals)
  * [Lambdas](#lambdas)
  * [Under the Hood](#under-the-hood)
    * [Bindings](#bindings)
```clojure
(ns expr-test
  (require testing t)
  (require expr ex [quote >> list do let defexpr defun if lambda with where])
  (require logic l [=])
  (use proc p [step]))

```
# expr: A Lisp-like Language

This module defines a Lisp-like expression language, facilitating impure functional programming.
Evaluation of such expressions is done through the [QEPL](muon-clj/qepl.md).
It works by defining solutions to the `step` predicate, which is queried by the QEPL.
Every expression should have a solution to the `step` predicate, either returning a value or
providing a continuation that consists of an _action_, which is an expression in the implementation
language (e.g., Clojure) and a next expression to evaluate, given the result of that action.

In this doc we use [QEMU simulation](testing.md#qepl-simulation) to demonstrate the evaluation
of expressions.

## Quotation and Self Evaluation

As in most Lisps, the `quote` expression evaluates to its (one and only) argument.
```clojure
(ex/test-expr quote-evaluates-to-argument
              (quote (foo bar)) ;; This expression
              (foo bar)         ;; evaluates to this value
              t/pure)   ;; by computing these steps (none).

```
Literal types do not need to be quoted. They evaluate to themselves.
```clojure
(ex/test-expr int-evaluates-to-itself
              42 42 t/pure)
(ex/test-expr float-evaluates-to-itself
              3.14 3.14 t/pure)
(ex/test-expr string-evaluates-to-itself
              "foo" "foo" t/pure)
(ex/test-expr bool-evaluates-to-itself
              true true t/pure)

```
## Actions
Actions are lists containing an _action name_ as a first element and zero or more arguments following it.
The action names are host-language-agnostic, with a translation layer translating them to function names
in the host language.
The arguments should be _values_, not _expressions_.
This means that each action corresponds to _exactly one_ operation to be performed
by the host language.
Complex expressions are broken down into a sequence of actions by this expression language.

To call an action from an expression, use the `>>` operator.
An expression that uses the `>>` operator evaluates to the value returned by the action.

**Note**: In the examples provided in this doc we use made-up actions, as the language is agnostic to which
actions are actually used. Documentation on which actions are actually available is TBD.
```clojure
(t/test-value >>-calls-an-action
              (step (ex/bind (>> some-action 1 2 3) [some bindings]) () (continue :action :_next))
              :action
              (some-action 1 2 3))

(ex/test-expr >>-returns-action-result
              (>> the-big-question-of "life" "universe" "everything")
              42
              (t/sequential
               (the-big-question-of "life" "universe" "everything") 42))

```
## List Construction

A `list` expression takes zero or more expressions as arguments, evaluates them and returns a list of their respective values.
```clojure
(ex/test-expr list-creates-list
              (list (>> get-foo) (>> get-bar))
              ("foo" "bar")
              (t/by-def (2)))

(t/defaction (get-foo) "foo")
(t/defaction (get-bar) "bar")

```
## Control Flow

The `do` expression takes zero or more sub-expressions and evaluates them in-order.
It returns the value of the last expression.
```clojure
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

```
The `let` expression takes a vector of bindings (variable-expression pairs) and zero or more expressions.
With no bindings, it works exactly like a `do` expression.
```clojure
(ex/test-expr let-without-bindings
              (let []
                (>> do-something)
                (>> do-something-else))
              3
              (t/sequential
               (do-something) 2
               (do-something-else) 3))

```
Given bindings, the bound expressions are being evaluated in order before evaluating the body.
```clojure
(ex/test-expr let-evaluates-bindings-in-order
              (let [foo (>> get-foo)
                    bar (>> get-bar)]
                (>> do-something))
              2
              (t/sequential
               (get-foo) "foo"
               (get-bar) "bar"
               (do-something) 2))

```
The variable in each pair is bound to the result of evaluating the expression.
```clojure
(ex/test-expr let-binds-vars-to-expr-results
              (let [foo (>> get-foo)]
                foo)
              "foo"
              (t/by-def (1)))

```
A `with` expression allows for using logic within the evaluation of an expression.
It takes a vector of _clauses_, which may either be `let` or `where` clauses,
and a single expression which will be evaluated in the end.

Without clauses, the `with` expression evaluates to its underlying expression.
```clojure
(ex/test-expr with-without-clauses
              (let [x 42]
                (with [] x))
              42
              t/pure)

```
A `let` clause takes a _logic_ variable and an expression. It evaluates the expression
and binds the variable to the value.
```clojure
(ex/test-expr with-with-a-let-clause
              (with [(let :x (>> the-answer))] :x)
              42
              (t/sequential
               (the-answer) 42))

```
A `where` clause applies the underlying logic goal. It is assumed that this goal succeeds deterministically.
```clojure
(ex/test-expr with-with-a-where-clause
              (with [(let :x (>> the-answer))
                     (where (= :y :x))] :y)
              42
              (t/sequential
               (the-answer) 42))

```
## Definitions

In this section we describe the ways in which new expression types can be introduced.
Definitions are done through predicates that are being consulted during the evaluation
process of expressions. By defining new solutions for said predicates we can introduce
new types of expressions.

### Expression Definitions

`defepxr` allows us to define one (new) expression in terms of another.
It takes a pattern of the expression to be defined and a pattern of the pattern
it would be defined as. Both the defined expression and the expression used for defining
it share `:logic-variables` which are bound to sub-expressions.

In the following example we define the `println` expression, which takes one
expression as parameter, evaluates it (using a `let-value` expression) and invokes
the fictional `println` action with the result as parameter.
```clojure
(defexpr (println :str)
  (with [(let :str-val :str)]
             (>> println :str-val)))

```
Now we can call the new `println` expression.
```clojure
(ex/test-expr defexpr-defines-expr
              (println "foo")
              ()
              (t/sequential
               (println "foo") ()))

```
Since `defexpr` takes a pattern of the expression it defines,
it is very useful for defining variadic expressions.
The following example extends the previous definition of `println`, adding support for
two arguments and above.
```clojure
(defexpr (println :first :second :rest ...)
  (do
    (println :first)
    (println :second :rest ...)))

```
Now we can call `println` with any number of arguments.
```clojure
(ex/test-expr defexpr-defines-variadic-expr
              (println "one" "two" "three")
              ()
              (t/sequential
               (println "one") ()
               (println "two") ()
               (println "three") ()))

```
In comparison to other Lisps, `defexpr` is similar to a macro definition in that it operates at the
expression level. The expression being defined shares the call-site's lexical scope.
```clojure
(ex/test-expr defexpr-shares-lexical-scope
              (let [x "foo"]
                (println x))
              ()
              (t/sequential
               (println "foo") ()))

```
In the above example, the definition of `println` received the expression `x` as parameter.
Then, `x` was evaluated as part of the expression `println` translated into.

Obviosly, this behavior can also be abused, as in the following example.
```clojure
(defexpr do-something-surprising
  (println some-message))

```
In the above definition we defined the expression `do-something-surprising` as a printing of
`some-message`, a variable we did not define in this scope. Now, if we bind `some-message` to a string
`do-something-surprising` will print it.
```clojure
(ex/test-expr defexpr-lexical-scope2
              (let [some-message "don't do this!"]
                do-something-surprising)
              ()
              (t/sequential
               (println "don't do this!") ()))

```
### Function Definitions

In contrast to `defexpr`, which is comparable with a macro definition, `defun` is a function definition.
Simlalr to its counterpart in other Lisps, the syntax of `defun` consists of a function name,
a vector of parameters (symbols, not logic variables) and zero or more expressions acting as the body.
A call to a function defined using `defun` will always start by evaluating the arguments first,
and only then will the body be evaluated as well.

In the following example we define two functions. The first is `strcat` which wraps around
the (imaginary) `strcat` action. It unquotes the parameters to be able to use the plain strings
in an action.
```clojure
(defun strcat [s1 s2]
  (with [(let :s1 s1)
         (let :s2 s2)]
        (>> strcat :s1 :s2)))

```
Then we define the function `greet` which takes a name of a person as parameter and prints a
greeting for that person.
```clojure
(defun greet [name]
  (println (strcat "Hello, " name)))

```
Calling this function will first concatenate "Hello, " to the value we give as argument,
and then prints the resulting string.
```clojure
(ex/test-expr defun-defines-functions
              (greet "Muon")
              ()
              (t/sequential
               (strcat "Hello, " "Muon") "Hello, Muon"
               (println "Hello, Muon") ()))

```
#### Bindging Arguments to Parameters

Internally, the `bind-args` predicate creates a bindings vector out of an arguments vector and a
list of parameter expressions.
```clojure
(t/test-value bind-args-returns-empty-bindings-for-no-params
              (ex/bind-args [] () :result)
              :result [])
(t/test-value bind-args-returns-bindings-for-params-with-matching-args
              (ex/bind-args [param1 param2 param3] (arg1 arg2 arg3) :result)
              :result [param1 arg1
                       param2 arg2
                       param3 arg3])

```
## Conditionals

Similar to Clojure and many other functional programming languages, an `if` expression takes three expressions:
_condition_, _then_ and _else_. It begins by evaluating the condition. If it evaluates to `true`, the _then_ part
is being evaluated.
```clojure
(ex/test-expr if-with-true-condition
              (if (>> some-condition-action)
                (>> some-then-action)
                (>> some-else-action))
              then-result
              (t/sequential
               (some-condition-action) true
               (some-then-action) then-result))

```
And if it evaluates to `false`, the _else_ part is being evaluated.
```clojure
(ex/test-expr if-with-false-condition
              (if (>> some-condition-action)
                (>> some-then-action)
                (>> some-else-action))
              else-result
              (t/sequential
               (some-condition-action) false
               (some-else-action) else-result))

```
## Lambdas

A `labmda` expression takes a parameter list and an expression and creates a `closure` which stores the parameter list,
the expression and the local bindings as of the creation of the lambda.
```clojure
(ex/test-expr lambda-creates-closure
              (let [baz "baz"]
                (lambda [foo bar] (>> do-something foo bar baz)))
              (ex/closure [foo bar] (>> do-something foo bar baz) [baz "baz"])
              t/pure)

```
A lambda can be used in place of a function (a first element in a list expression).
```clojure
(ex/test-expr labmda-call
              (let [f (let [baz "baz"]
                        (lambda [foo bar]
                                (with [(let :foo foo)
                                       (let :bar bar)
                                       (let :baz baz)]
                                      (>> do-something :foo :bar :baz))))]
                (f "foo" "bar"))
              ()
              (t/sequential
               (do-something "foo" "bar" "baz") ()))

```
The arguments to a lambda are evaluated using the bindings at the call site.
```clojure
(ex/test-expr labmda-call-computes-args
              (let [f (let [baz "baz"]
                        (lambda [foo bar]
                                (with [(let :foo foo)
                                       (let :bar bar)
                                       (let :baz baz)]
                                      (>> do-something :foo :bar :baz))))
                    foo "FOO"
                    bar "BAR"]
                (f foo bar))
              ()
              (t/sequential
               (do-something "FOO" "BAR" "baz") ()))

```
`defun` itself is defined in terms of lambdas:
```clojure
(ex/test-expr defun-uses-lambda
              greet
              (ex/closure [name]
                          (do
                            (println (strcat "Hello, " name)))
                          [])
              t/pure)

```
## Under the Hood

### Bindings

A binding consists of an expression and an associated vector of _variable bindings_.
These variable bingins consist of a symbol representing the variable (not to be confused with a `:logic-variable`),
and a value associated with this variable.

Variables evaluate to their bound value within a binding.
```clojure
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

```
Expressions do not stand on their own, but rather require binding to be evaluated.
To ease testing of expressions (i.e., make it so that we do not have to provide the binding every time),
we introduce the `test-expr` test definition. For example:
```clojure
(ex/test-expr int-evaluates-to-itself
              42 42 t/pure)

```
This definition defines a corresponding `t/test-model`:
```clojure
(t/test-value test-expr-defines-test-model
              (t/test-model int-evaluates-to-itself :args ...)
              :args
              ((ex/bind 42 []) 42 t/pure))
the-end
```

