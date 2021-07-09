(ns logic-test
  (require logic logic [& = case]))

;; For the demonstrations in this module we will use the `foo` predicate, which succeeds for `1`, `2` and `3`:
(foo 1)
(foo 2)
(foo 3)

(test foo-has-three-values
      (foo :x)
      3)

;; ## Unification (`=`)
;; The `=` operator unifies its two operands, and succeeds if unification is successful.
(test =-successful-for-identical-values
      (= 1 1)
      1)
(test =-unsuccessful-for-different-values
      (= 1 2)
      0)

;; ## Conjunction (`&`)
;; The `&` operator performs conjunction of zero or more goals.
(test &-on-zero-goals
      (&)
      1)
(test &-on-one-goal
      (& (foo :x))
      3)
(test &-on-two-passing-goals
      (& (foo 1) (foo 2))
      1)
(test &-on-passing-and-failing-goals
      (& (foo 1) (foo 4))
      0)

;; ## Pattern Matching (`case`)
;; The `case` predicate, inspired by the `case` construct in functional programming languages such as [Haskell](https://www.haskell.org/tutorial/patterns.html),
;; allows for matching a pattern against different options.
;;
;; For example, consider a predicate that matches lists. It can match either an empty list `()` or a non-empty list `(:x :xs ...)`.
;; Typically, a predicate would have different clauses to handle the different cases, but sometimes we would like to
;; handle them from the same clause. This is where `case` comes in handy.
;;
;; Its first argument is a term, followed by a number of (pattern, goal) pairs.
;; The term is matched against each pattern and in case of a match, the goal is evaluated.
;;
;; The following example predicate matches a list with a term, indicating whether the list is empty or not, and if not, provides the first element.
(<- (list-status :list :status)
    (case :list
      () (= :status empty-list)
      (:x :xs ...) (= :status (non-empty-list :x))))
(test case-takes-first-case
      (list-status () empty-list)
      1)
(test case-takes-second-case
      (list-status (1 2) (non-empty-list 1))
      1)
(test case-fails-if-no-case-matches
      (list-status foo :x)
      0)

;; Unlike `case` constructs in functional languages, here the different cases are not mutually exclusive.
;; Evaluation does not stop once a match is found.
;; For example, in the following test the `case` goal has two different options for matching `1`,
;; and when given `1` as the term, both are taken.
(test case-matching-more-than-one-option
      (case 1
        1 (= :x 2)
        1 (= :x 3)
        2 (= :x 1))
      2)
