(ns examples.concat)

(concat () :b :b)
(<- (concat (:x :a ...) :b (:x :ab ...))
    (concat :a :b :ab))

(test concatenating-two-lists
      (concat (1 2) (3 4) :x)
      1)

(test finding-all-partitions
      (concat :x :y (1 2 3 4))
      5)
