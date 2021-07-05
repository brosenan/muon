(ns examples.self-eval-concat
  (require examples.self-eval se [<--]))

;; This is an implementation of concat that uses the Muon self-interpreter.
(concat () :b :b)
(<-- (concat (:x :a ...) :b (:x :ab ...))
     (concat :a :b :ab))
