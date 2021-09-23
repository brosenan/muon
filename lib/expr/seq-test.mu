(ns expr.seq-test
  (require testing t)
  (require expr.seq s [empty? first rest to-list to-vec defseq seq])
  (require expr.arith ar [+])
  (require expr ex [defun lambda do let quote >>])
  (require native n))

;; # Sequences

;; A sequence is an object that can either be empty or not, and if it is not, it can provide
;; its first element and a sequence consisting of the rest of its elements.

;; ## Sequence Definitions

;; `defseq` defines a sequence. It takes a name, a parameter list and exactly three expressions:

;; 1. Is the sequence empty?
;; 2. (assuming not empty) what is the first element?
;; 3. (assuming not empty) a sequence of all other elements.

;; In the following example we define the `count-from` sequence, which takes a number (ingeter) as parameter
;; and represents all integers starting at that number onwards. If is defined as follows:
(defseq count-from [n]
  false                  ;; The sequence is never empty.
  n                      ;; n is the first element.
  (count-from (+ n 1)))  ;; Count from the next element to get the rest of the elements.

;; Given such a definition, `count-from` becomes a _contstructor_. This means that it can be used
;; as an expression, where its argument is being evaluated.
(ex/test-expr defseq-defines-constructor
              (count-from (+ 2 4))
              (count-from 6)
              (t/by-def (1)))

(t/defaction (n/+ 2 4) 6)

;; Three functions are defined on each sequence, using the respective expressions:
;; `empty?` returns whether or not the sequence is empty.
(ex/test-expr defseq-defines-empty
              (empty? (count-from 7))
              false
              t/pure)

;; `first` returns the first element.
(ex/test-expr defseq-defines-first
              (first (count-from 7))
              7
              t/pure)

;; `rest` returns the rest of the sequence.
(ex/test-expr defseq-defines-rest
              (rest (count-from 7))
              (count-from 8)
              (t/by-def (1)))

(t/defaction (n/+ 7 1) 8)

;; ## Lists and Vectors

;; Lists and vectors are _not_ sequences by themselves. This is because defining them as such
;; would conflict with sequences defined using `defseq` (e.g., `count-from`) which already take the
;; form of a list.

;; To overcome this, we define the sequence `seq` which takes a list or a vector and defines the three
;; operations based on them.
(ex/test-expr seq-defines-empty-for-empty-list
              (empty? (seq (quote ())))
              true
              t/pure)
(ex/test-expr seq-defines-empty-for-nonempty-list
              (empty? (seq (quote (1 2 3))))
              false
              t/pure)
(ex/test-expr seq-defines-empty-for-empty-vec
              (empty? (seq (quote [])))
              true
              t/pure)
(ex/test-expr seq-defines-empty-for-nonempty-vec
              (empty? (seq (quote [1 2 3])))
              false
              t/pure)

(ex/test-expr seq-defines-first
              (first (seq (quote (1 2 3))))
              1
              t/pure)
(ex/test-expr seq-defines-rest
              (rest (seq (quote (1 2 3))))
              (seq (2 3))
              t/pure)

;; ### Constructing Lists and Vectors

;; Finite sequences can be materialized as lists or vectors.

;; The function `to-list` materializes a sequence into a list.
(defseq myseq []
  (>> is-it-empty?)
  (>> give-me-first)
  (>> give-me-rest))

(ex/test-expr to-list-creates-list
              (to-list (myseq))
              (1 2 3)
              (t/sequential
               (is-it-empty?) false
               (give-me-first) 1
               (give-me-rest) (myseq)
               (is-it-empty?) false
               (give-me-first) 2
               (give-me-rest) (myseq)
               (is-it-empty?) false
               (give-me-first) 3
               (give-me-rest) (myseq)
               (is-it-empty?) true))

