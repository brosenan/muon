(ns examples.concat)

(concat () :b :b)
(<- (concat (:x :a ...) :b (:x :ab ...))
    (concat :a :b :ab))
