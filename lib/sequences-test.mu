(ns sequences-test
  (require testing t)
  (require sequences s [empty? first rest])
  (require proc p [']))

;; Sequences are an abstraction that supports three functions:
;; * `(empty? :seq)` returns `true` if a sequence has no elements.
;; * `(first :seq)` returns the first element of a non-empty sequences, and
;; * `(rest :seq)` returns a sequence containing all but the first element of a non-empty sequence.
;;
;; To define a sequence one needs to define these three functions for the relevant object.

;; ## Lists and Vectors as Sequences.
;; Lists and vectors are sequences.
;; `empty?` is defined on them, requiring no external computation.
(t/test-model empty?-for-empty-list
              (empty? ('()))
              true
              (t/sequential))
(t/test-model empty?-for-non-empty-list
              (empty? ('(1 2 3)))
              false
              (t/sequential))

(t/test-model empty?-for-empty-vec
              (empty? ('[]))
              true
              (t/sequential))
(t/test-model empty?-for-non-empty-vec
              (empty? ('[1 2 3]))
              false
              (t/sequential))

;; `first` returns the first element of a non-empty list or vector.
(t/test-model first-for-non-empty-list
              (first ('(1 2 3)))
              1
              (t/sequential))
(t/test-model first-for-non-empty-vec
              (first ('[1 2 3]))
              1
              (t/sequential))

;; `rest` returns a list containing all but the first element of a non-empty list or vector.
(t/test-model rest-for-non-empty-list
              (rest ('(1 2 3)))
              (2 3)
              (t/sequential))
(t/test-model rest-for-non-empty-vec
              (rest ('[1 2 3]))
              [2 3]
              (t/sequential))

