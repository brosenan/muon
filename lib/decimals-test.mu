(ns decimals-test
  (require testing t)
  (require decimals d))

;; # Decimals

;; This module defines arithmetic operations for decimals, using pure logic.

;; It represents numbers using lists of digits, read from left to right. For example, `(4 2)` represents the number 42.

;; ## Increment and Decrement

;; `d/inc` takes a decimal and increments it.
(t/test-value inc-increments-23999
              (d/inc (2 3 9 9 9) :x)
              :x
              (2 4 0 0 0))

;; `d/dec` decrements a decimal.
(t/test-value dec-decrements-24000
              (d/dec (2 4 0 0 0) :x)
              :x
              (2 3 9 9 9))

;; ### Implementation Details

;; `d/digits` provides a list of the decimal digits.
(t/test-value digits
              (d/digits :digits)
              :digits
              (0 1 2 3 4 5 6 7 8 9))

;; `d/inc-digit` provides, for a digit in the range [0, 8], the next one, with carry `false`.
(t/test-value inc-digit-returns-8-for-7
              (d/inc-digit 7 :next :_carry)
              :next
              8)
(t/test-value inc-digit-returns-carry-false-for-7
              (d/inc-digit 7 :_next :carry)
              :carry
              false)

;; For 9 it provides 0 with carry `true`.
(t/test-value inc-digit-returns-0-for-9
              (d/inc-digit 9 :next :_carry)
              :next
              0)
(t/test-value inc-digit-returns-carry-true-for-9
              (d/inc-digit 9 :_next :carry)
              :carry
              true)

;; `d/dec-digit` provides, for a digit in the range [1. 9], the previous digit and carry `false`.
(t/test-value dec-digit-returns-6-for-7
              (d/dec-digit 7 :prev :_carry)
              :prev
              6)
(t/test-value dec-digit-returns-carry-false-for-7
              (d/dec-digit 7 :_prev :carry)
              :carry
              false)

;; For 0, it returns 9 and carry `true`.
(t/test-value dec-digit-returns-9-for-0
              (d/dec-digit 0 :prev :_carry)
              :prev
              9)
(t/test-value dec-digit-returns-carry-true-for-0
              (d/dec-digit 0 :_prev :carry)
              :carry
              true)

;; `d/inc-rev` increments a reversed (least digit first) decimal.
(t/test-value inc-rev-increments-0
              (d/inc-rev () :result)
              :result
              (1))
(t/test-value inc-rev-increments-7
               (d/inc-rev (7) :result)
               :result
               (8))
(t/test-value inc-rev-increments-9
              (d/inc-rev (9) :result)
              :result
              (0 1))
(t/test-value inc-rev-increments-2999
              (d/inc-rev (9 9 9 2) :result)
              :result
              (0 0 0 3))

;; `d/dec-rev` decrements a reversed (least digit first) decimal.
(t/test-value dec-rev-decrements-7-to-6
              (d/dec-rev (7) :result)
              :result
              (6))
(t/test-value dec-rev-decrements-10-to-9
              (d/dec-rev (0 1) :result)
              :result
              (9 0)) ;; Leading zeros are allowed in the result.
(t/test-value dec-rev-decrements-3000-to-2999
              (d/dec-rev (0 0 0 3) :result)
              :result
              (9 9 9 2))

;; ## Comparison

;; `d/is-zero` returns whether a given number represents zero.
(t/test-value is-zero-returns-true-for-zero
              (d/is-zero (0 0 0 0 0) :zero?)
              :zero?
              true)
(t/test-value is-zero-returns-false-for-non-zero
              (d/is-zero (0 0 0 2 0) :zero?)
              :zero?
              false)