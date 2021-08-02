(ns expr-test
  (require testing t)
  (require expr ex [quote >> do let defexpr defun])
  (use proc p [step]))

;; # expr: A Lisp-like Language

;; This module defines a Lisp-like expression language, facilitating impure functional programming.
;; Evaluation of such expressions is done through the [QEPL](muon-clj/qepl.md).
;; It works by defining solutions to the `step` predicate, which is queried by the QEPL.
;; Every expression should have a solution to the `step` predicate, either returning a value or
;; providing a continuation that consists of an _action_, which is an expression in the implementation
;; language (e.g., Clojure) and a next expression to evaluate, given the result of that action.
;;
;; In this doc we use [QEMU simulation](testing.md#qepl-simulation) to demonstrate the evaluation
;; of expressions.

;; ## Quotation and Self Evaluation

;; As in most Lisps, the `quote` expression evaluates to its (one and only) argument.
(t/test-model quote-evaluates-to-argument
              (quote (foo bar)) ;; This expression
              (foo bar)         ;; evaluates to this value
              (t/sequential))   ;; by computing these steps (none).

;; Literal types do not need to be quoted. They evaluate to themselves.
(t/test-model int-evaluates-to-itself
              42 42 (t/sequential))
(t/test-model float-evaluates-to-itself
              3.14 3.14 (t/sequential))
(t/test-model string-evaluates-to-itself
              "foo" "foo" (t/sequential))
(t/test-model bool-evaluates-to-itself
              true true (t/sequential))

;; ## Actions
;; Actions are lists containing an _action name_ as a first element and zero or more arguments following it.
;; The action names are host-language-agnostic, with a translation layer translating them to function names
;; in the host language.
;; The arguments should be _values_, not _expressions_.
;; This means that each action corresponds to _exactly one_ operation to be performed
;; by the host language.
;; Complex expressions are broken down into a sequence of actions by this expression language.
;;
;; To call an action from an expression, use the `>>` operator.
;; An expression that uses the `>>` operator evaluates to the value returned by the action.
;;
;; **Note**: In the examples provided in this doc we use made-up actions, as the language is agnostic to which
;; actions are actually used. Documentation on which actions are actually available is TBD.
(t/test-value >>-calls-an-action
              (step (>> some-action 1 2 3) () (continue :action :_next))
              :action
              (some-action 1 2 3))

(t/test-model >>-returns-action-result
              (>> the-big-question-of "life" "universe" "everything")
              42
              (t/sequential
               (the-big-question-of "life" "universe" "everything") 42))
