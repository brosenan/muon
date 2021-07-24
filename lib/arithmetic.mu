(ns arithmetic
  (require native n)
  (require proc p [defun defproc >> ']))

;; An associative operator will return its argument if given only one.
(<- (defun :op [:x]
      (' :x))
    (associative :op))

;; An associative operator will apply the binary operator in order if given three or more arguments.
(<- (defproc (:op :a-expr :b-expr :c-expr :exprs ...)
      (:op (:op :a-expr :b-expr) :c-expr :exprs ...))
    (associative :op))

(defun + []
  (' 0))
(defun + [:a :b]
  (>> n/+ :a :b))
(associative +)

(defun - [:a :b]
  (>> n/- :a :b))
(associative -)

(defun * []
  (' 1))
(defun * [:a :b]
  (>> n/* :a :b))
(associative *)

(defun / [:a :b]
  (>> n// :a :b))
(associative /)