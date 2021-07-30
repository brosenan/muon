(ns muon-clj.testing-test
  (:require [midje.sweet :refer :all]
            [muon-clj.testing :refer :all]
            [muon-clj.core :as core]))

;; Testing is an important aspect of programming.
;; In Muon, testing is facilitated by the `test` predicate (implicitly, `muon/tets`).
;; Programs define tests by contributing results to the `test` predicate.
;; The runtime environment (defined here) calls this predicate to gather all tests that need to be executed,
;; Executes them and compares the result to the expectation.
;;
;; A test definition has the form: `(test :id :goal :num-results)`, where `:id` is a symbol identifying the test
;; (it will be displayed if the test fails), `:goal` is a logic goal to be executed and `:num-results` is the
;; expected number of results from the test. `1` indicates that the goal should succeed deterministically,
;; i.e., provide one set of bindings, `0` indicates that the goal is supposed to fail and any other number
;; indicates the number of expected bindings that should come out.
;;
;; `get-tests` takes a program database and returns a list of tests to be performed, each represented as a map of
;; the test's three arguments (parsed).
(fact
 (let [db (core/load-program
           '[(muon/test foo-should-fail (foo 1) 0)
             (muon/test bar-should-succeed-once (bar 2) 1)
             (muon/test foo-should-succeed-thrice (foo 3) 3)
             (foo 3)
             (bar 7)])]
   (set (get-tests db)) => #{{:id 'foo-should-fail
                              :goal ['foo [['muon/int 1] ()]]
                              :num-results 0}
                             {:id 'bar-should-succeed-once
                              :goal ['bar [['muon/int 2] ()]]
                              :num-results 1}
                             {:id 'foo-should-succeed-thrice
                              :goal ['foo [['muon/int 3] ()]]
                              :num-results 3}}))

;; `run-test` takes a database and a map describing a single test, executes the test and returns a map containing the following:
;; * `:id`: The test Id as in the input.
;; * `:success`: A Boolean indicating whether the test was successful.
;; * `:expected-num-results`: Contains the `:num-results` from the input.
;; * `:results`: A set of the result terms (the `:goal` from the input substituted with each result bindings), formatted as an s-expression.
(fact
 (let [db (core/load-program
           '[(foo 1)
             (foo 2)
             (foo 3)])]
   (run-test db {:id "foo-should-succeed-thrice"
                 :goal ['foo [[1] ()]]
                 :num-results 3}) => {:id "foo-should-succeed-thrice"
                                      :expected-num-results 3
                                      :results #{'(foo 1)
                                                 '(foo 2)
                                                 '(foo 3)}
                                      :success true}
   (run-test db {:id "foo-should-succeed-thrice"
                 :goal ['foo [['muon/int 1] ()]]
                 :num-results 3}) => {:id "foo-should-succeed-thrice"
                                      :expected-num-results 3
                                      :results #{'(foo 1)}
                                      :success false}))

;; `format-results` takes a collection of result maps such as the ones returned by `run-test`,
;; and returns a string summarizing it.
;;
;; If all tests are successful, the number of successful tests is returned with green caption.
(fact
 (format-results [{:id "foo" :success true}
                  {:id "bar" :success true}
                  {:id "baz" :success true}
                  {:id "quux" :success true}]) => "\u001b[32mSuccess:\u001b[0m 4 test(s) passed.")

;; Failing tests are printed in detail with the test ID appearing in red,
;; followed by the expected and actual number of results, followed by the actual results.
;; Finally a summary of the number of failures (and successes) is given with red caption.
(fact
 (format-results [{:id "foo" :success true}
                  {:id "bar" :success false
                   :expected-num-results 1
                   :results '[(bar 1) (bar 2)]}
                  {:id "baz" :success true}
                  {:id "quux" :success true}]) =>
 "\u001b[31mbar\u001b[0m: Expected 1 result(s), got 2:
* (bar 1)
* (bar 2)
\u001b[31mFailure:\u001b[0m 1 test(s) failed (3 passed).")

;; Finally, `run-tests` takes a database as input and returns a (`success`, `output`) pair,
;; where `success` is `true` if all tests have passed and `output` is the a string returned by `format-results`.
(fact
 (let [db (core/load-program
           '[(foo 1)
             (foo 2)
             (foo 3)
             (muon/test foo1 (foo :x) 3)
             (muon/test foo2 (foo 2) 1)])]
   (run-tests db) => [true "\u001b[32mSuccess:\u001b[0m 2 test(s) passed."]))
