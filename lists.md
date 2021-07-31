  * [Concatenation](#concatenation)
  * [Reverting a List](#reverting-a-list)
  * [Distinguishing between a Vector and a List](#distinguishing-between-a-vector-and a list)
```clojure
(ns lists-test
  (require lists l)
  (require testing t))

```
## Concatenation

`(concat :a :b :ab)` finds all ways in which `:ab` can be a concatenation of lists `:a` and `:b`:
```clojure
(test concatenating-two-lists
      (l/concat (1 2) (3 4) :x)
      1)

(test finding-all-partitions
      (l/concat :x :y (1 2 3 4))
      5)

```
## Reverting a List
`(reversed :ab :ba)` succeeds for every two lists `:ab` and `:ba` such that they have the same elements in reverse order.
```clojure
(test reversed-empty
      (l/reversed () ())
      1)
(test reversed-not-different
      (l/reversed () (1))
      0)

(test reversed-two-elements
      (l/reversed (1 2) (2 1))
      1)

```
## Distinguishing between a Vector and a List
`(vector? :vec)` succeeds for empty and non-empty vectors.
```clojure
(t/test-success vector?-succeeds-for-empty-vec
                (l/vector? []))
(t/test-failure vector?-fails-for-empty-list
                (l/vector? ()))
(t/test-success vector?-succeeds-for-nonempty-vec
                (l/vector? [1 2 3]))
(t/test-failure vector?-fails-for-nonempty-list
                (l/vector? (1 2 3)))

```
Similarly, `(list? :list)` succeeds for empty and non-empty lists.
```clojure
(t/test-success list?-succeeds-for-empty-list
                (l/list? ()))
(t/test-failure list?-fails-for-empty-vec
                (l/list? []))
(t/test-success list?-succeeds-for-nonempty-list
                (l/list? (1 2 3)))
(t/test-failure list?-fails-for-nonempty-vec
                (l/list? [1 2 3]))
```

