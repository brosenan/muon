(ns expr.arith
  (require expr e [defun defexpr >> do let quote if])
  (require native n))

;; Arithmetic
(defun + []
  0)

(defun + [(quote :a) (quote :b)]
  (>> n/+ :a :b))

(defun - [(quote :a) (quote :b)]
  (>> n/- :a :b))

(defun * []
  1)

(defun * [(quote :a) (quote :b)]
  (>> n/* :a :b))

(defun / [(quote :a) (quote :b)]
  (>> n// :a :b))

(left-associative +)
(left-associative -)
(left-associative *)
(left-associative /)

;; Logic operators
(defun not [:b]
  (if :b false true))

;; Associativity
(<- (defun :f [:x]
      :x)
    (left-associative :f))
(<- (defexpr (:f :first :second :third :others ...)
      (:f (:f :first :second) :third :others ...))
    (left-associative :f))
