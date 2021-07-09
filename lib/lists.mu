(ns lists)

(concat () :b :b)
(<- (concat (:x :a ...) :b (:x :ab ...))
    (concat :a :b :ab))

(reversed () ())
(<- (reversed (:x :a ...) :arx)
    (reversed :a :ar)
    (concat :ar (:x) :arx))
