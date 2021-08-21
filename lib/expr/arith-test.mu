(ns expr.io-test
  (require testing t)
  (require expr.arith ar [+ - * /])
  (require expr e [defun >> quote])
  (use native n)
  (use proc p [step]))

;; # Arithmetic

;; This module defines arithmetic and comparison operators (functions).

;; ## Arithmetic Operators

;; `+` with zero arguments returns 0.
(t/test-model +-with-zero-args-returns-0
              (+)
              0
              t/pure)

;; `*` with no arguments returns 1.
(t/test-model *-with-zero-args-returns-1
              (*)
              1
              t/pure)

;; Given two arguments, each arithmetic operator applies its respective action.
(t/test-model +-with-two-args-calls-native-+
              (+ 1 2)
              3
              (t/sequential
               (n/+ 1 2) 3))
(t/test-model --with-two-args-calls-native--
              (- 3 1)
              2
              (t/sequential
               (n/- 3 1) 2))
(t/test-model *-with-two-args-calls-native-*
              (* 2 3)
              6
              (t/sequential
               (n/* 2 3) 6))
(t/test-model div-with-two-args-calls-native-div
              (/ 6 3)
              2
              (t/sequential
               (n// 6 3) 2))

;; The four arithmetic operators are left-associative. See [below](#associativity) for what this means.
(t/test-success +-is-left-associative
                (ar/left-associative +))
(t/test-success --is-left-associative
                (ar/left-associative -))
(t/test-success *-is-left-associative
                (ar/left-associative *))
(t/test-success div-is-left-associative
                (ar/left-associative /))

;; ## Associativity

;; Any binary operator can be made _associative_ by defining how its behavior when given a number of arguments that is
;; different than two.

;; For example, consider the binary operator `foo`, which is evaluated by a binary action of the same name.
(defun foo [(quote :a) (quote :b)]
  (>> foo :a :b))

(t/test-model left-associative-function-with-two-args-applies-it
              (foo 1 2)
              12
              (t/sequential
               (foo 1 2) 12))


;; Now let us define `foo` to be `left-associative`:
(ar/left-associative foo)

;; As a result, we get a definition of `foo` for a single argument defined as the identity function:
(t/test-model left-associative-function-with-one-arg-is-identity
              (foo 3)
              3
              t/pure)

;; With more than two arguments, it will apply the binary operator on the first two arguments, then apply the operator
;; on the result and the third operator, and so on.
(t/test-model left-associative-function-with-more-than-two-args-applies-it-in-order
              (foo 1 2 3 4)
              1234
              (t/sequential
               (foo 1 2) 12
               (foo 12 3) 123
               (foo 123 4) 1234))

