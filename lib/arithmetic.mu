(ns arithmetic
  (require native n)
  (require proc p [defun defproc >> ']))

(defun + []
  (' 0))

(defun + [:x]
  (' :x))

(defun + [:a :b]
  (>> n/+ :a :b))

(defproc (+ :a-expr :b-expr :c-expr :exprs ...)
  (+ (+ :a-expr :b-expr) :c-expr :exprs ...))

(defun - [:x]
  (' :x))

(defun - [:a :b]
  (>> n/- :a :b))

(defproc (- :a-expr :b-expr :c-expr :exprs ...)
  (- (- :a-expr :b-expr) :c-expr :exprs ...))