* [expr: A Lisp-like-Language](#expr:-a-lisp-like-language)
  * [Quotation and Self Evaluation](#quotation-and-self-evaluation)
  * [Actions](#actions)
  * [Control Flow](#control-flow)
  * [Definitions](#definitions)
    * [Expression Definitions](#expression-definitions)
```clojure
(ns expr-test
  (require testing t)
  (require expr ex [quote >> do let defexpr defun])
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
(t/test-model quote-evaluates-to-argument
              (quote (foo bar)) ;; This expression
              (foo bar)         ;; evaluates to this value
              (t/sequential))   ;; by computing these steps (none).

```
Literal types do not need to be quoted. They evaluate to themselves.
```clojure
(t/test-model int-evaluates-to-itself
              42 42 (t/sequential))
(t/test-model float-evaluates-to-itself
              3.14 3.14 (t/sequential))
(t/test-model string-evaluates-to-itself
              "foo" "foo" (t/sequential))
(t/test-model bool-evaluates-to-itself
              true true (t/sequential))

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
              (step (>> some-action 1 2 3) () (continue :action :_next))
              :action
              (some-action 1 2 3))

(t/test-model >>-returns-action-result
              (>> the-big-question-of "life" "universe" "everything")
              42
              (t/sequential
               (the-big-question-of "life" "universe" "everything") 42))

```
## Control Flow

The `do` expression takes zero or more sub-expressions and evaluates them in-order.
It returns the value of the last expression.
```clojure
(t/test-model do-with-no-subexprs
              (do)
              ()
              (t/sequential))
(t/test-model do-with-subexprs
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
(t/test-model let-without-bindings
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
(t/test-model let-evaluates-bindings-in-order
              (let [:foo (>> get-foo)
                    :bar (>> get-bar)]
                (>> do-something))
              2
              (t/sequential
               (get-foo) "foo"
               (get-bar) "bar"
               (do-something) 2))

```
The variable in each pair is bound to the result of evaluating the expression.
```clojure
(t/test-model let-binds-vars-to-expr-results
              (let [:foo (>> get-foo)]
                :foo)
              "foo"
              (t/sequential
               (get-foo) "foo"))

```
The values bound are quoted, so that they can be used as expressions even if the value returned 
by the expression is not self-evaluating.
```clojure
(t/test-model let-binds-vars-to-quoted-value
              (let [:list (>> get-some-list)]
                :list)
              (1 2 3)
              (t/sequential
               (get-some-list) (1 2 3)))

```
## Definitions

In this section we describe the ways in which new expression types can be introduced.
Definitions are done through predicates that are being consulted during the evaluation
process of expressions. By defining new solutions for said predicates we can introduce
new types of expressions.

### Expression Definitions

`defepxr` allows us to define one (new) expression in terms of another.
It takes a pattern of the expression to be defined and a pattern of the pattern
it would be defined as.
In the following example we define the `println` expression, which takes one
expression as argument, evaluates it (using a `let` expression) and invokes
the imaginary `println` action with the result as parameter.
```clojure
(defexpr (println :str)
  (let [(quote :str-val) :str]
    (>> println :str-val)))

```
One thing to note here is the fact that we _unquote_ `:str-val`. This is because
we need it as a value rather than an expression (recall that actions
require values as parameters).
Now we can call the new `println` expression.
```clojure
(t/test-model defexpr-defines-expr
              (println "foo")
              ()
              (t/sequential
               (println "foo") ()))

```
Since `defexpr` takes a pattern of the actual expression it defines,
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
(t/test-model defexpr-defines-variadic-expr
              (println "one" "two" "three")
              ()
              (t/sequential
               (println "one") ()
               (println "two") ()
               (println "three") ()))
```

