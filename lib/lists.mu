(ns lists)

(concat () :b :b)
(<- (concat (:x :a ...) :b (:x :ab ...))
    (concat :a :b :ab))

(reversed () ())
(<- (reversed (:x :a ...) :arx)
    (reversed :a :ar)
    (concat :ar (:x) :arx))

(vector? [])
(<- (vector? [:_x :xs ...])
    (vector? :xs))

(list? ())
(<- (list? (:_x :xs ...))
    (list? :xs))