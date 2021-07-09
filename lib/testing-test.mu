(ns testing-test
  (require testing t))

;; The `test` predicate is the main way of defining tests in Muon.
;; It is covered int [the Clojure implementation documentation](muon-clj/testing.md).
;; This documentation covers utility predicates intended to make tests simpler to work with.

;; ## Value Testing
;; A common use-case for testing is when we wish to compare a value provided by some goal
;; against an expected value.
;; Normally, this would be done by evaluating the value and then comparing it against the expected value.
;; However, in pure logic programming, the goal can succeed trivially, by providing a free variable rather than a concrete value.
;;
;; To address this, the `test-value` predicate allows its users to define tests in which we make sure that the goal matches the expected value,
;; but not trivially.
;; We do this by translating every `test-value` result into two `test` results, one expecting one success with the concrete value,
;; and one expecting failure with a different value.
(foo "bar")
(t/test-value foo-returns-bar
              (foo :x) :x "bar")
(test test-value-creates-two-tests
      (test foo-returns-bar :test :count)
      2)
(test test-value-creates-test-for-value
      (test foo-returns-bar (foo "bar") 1)
      1)
(test test-value-creates-anti-test-for-arbitrary-value
      (test foo-returns-bar (foo t/not-a-value) 0)
      1)