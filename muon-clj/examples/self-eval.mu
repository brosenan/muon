(ns examples.self-eval)

(<- (s :f) :f)
(<- (s :h)
    (<-- :h :b ...)
    (s (conj :b ...)))
(s (conj))
(<- (s (conj :a :b ...))
    (s (conj :b ...)))
