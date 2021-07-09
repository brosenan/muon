  * [Concatenation](#concatenation)
  * [Reverting a List](#reverting-a-list)
```clojure
(ns lists-test
  (require lists l))

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

