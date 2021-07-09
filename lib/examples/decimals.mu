(ns examples.decimals
  (require lists l))

;; (for [a (range 10) b (range 10)] (let [c (quot (+ a b) 10) d (mod (+ a b) 10)] (list 'dig-rev-add a b (if (> c 0) (list d c) (list d)))))
(dig-rev-add 0 0 (0)) (dig-rev-add 0 1 (1)) (dig-rev-add 0 2 (2)) (dig-rev-add 0 3 (3)) (dig-rev-add 0 4 (4)) (dig-rev-add 0 5 (5)) (dig-rev-add 0 6 (6)) (dig-rev-add 0 7 (7)) (dig-rev-add 0 8 (8)) (dig-rev-add 0 9 (9)) (dig-rev-add 1 0 (1)) (dig-rev-add 1 1 (2)) (dig-rev-add 1 2 (3)) (dig-rev-add 1 3 (4)) (dig-rev-add 1 4 (5)) (dig-rev-add 1 5 (6)) (dig-rev-add 1 6 (7)) (dig-rev-add 1 7 (8)) (dig-rev-add 1 8 (9)) (dig-rev-add 1 9 (0 1)) (dig-rev-add 2 0 (2)) (dig-rev-add 2 1 (3)) (dig-rev-add 2 2 (4)) (dig-rev-add 2 3 (5)) (dig-rev-add 2 4 (6)) (dig-rev-add 2 5 (7)) (dig-rev-add 2 6 (8)) (dig-rev-add 2 7 (9)) (dig-rev-add 2 8 (0 1)) (dig-rev-add 2 9 (1 1)) (dig-rev-add 3 0 (3)) (dig-rev-add 3 1 (4)) (dig-rev-add 3 2 (5)) (dig-rev-add 3 3 (6)) (dig-rev-add 3 4 (7)) (dig-rev-add 3 5 (8)) (dig-rev-add 3 6 (9)) (dig-rev-add 3 7 (0 1)) (dig-rev-add 3 8 (1 1)) (dig-rev-add 3 9 (2 1)) (dig-rev-add 4 0 (4)) (dig-rev-add 4 1 (5)) (dig-rev-add 4 2 (6)) (dig-rev-add 4 3 (7)) (dig-rev-add 4 4 (8)) (dig-rev-add 4 5 (9)) (dig-rev-add 4 6 (0 1)) (dig-rev-add 4 7 (1 1)) (dig-rev-add 4 8 (2 1)) (dig-rev-add 4 9 (3 1)) (dig-rev-add 5 0 (5)) (dig-rev-add 5 1 (6)) (dig-rev-add 5 2 (7)) (dig-rev-add 5 3 (8)) (dig-rev-add 5 4 (9)) (dig-rev-add 5 5 (0 1)) (dig-rev-add 5 6 (1 1)) (dig-rev-add 5 7 (2 1)) (dig-rev-add 5 8 (3 1)) (dig-rev-add 5 9 (4 1)) (dig-rev-add 6 0 (6)) (dig-rev-add 6 1 (7)) (dig-rev-add 6 2 (8)) (dig-rev-add 6 3 (9)) (dig-rev-add 6 4 (0 1)) (dig-rev-add 6 5 (1 1)) (dig-rev-add 6 6 (2 1)) (dig-rev-add 6 7 (3 1)) (dig-rev-add 6 8 (4 1)) (dig-rev-add 6 9 (5 1)) (dig-rev-add 7 0 (7)) (dig-rev-add 7 1 (8)) (dig-rev-add 7 2 (9)) (dig-rev-add 7 3 (0 1)) (dig-rev-add 7 4 (1 1)) (dig-rev-add 7 5 (2 1)) (dig-rev-add 7 6 (3 1)) (dig-rev-add 7 7 (4 1)) (dig-rev-add 7 8 (5 1)) (dig-rev-add 7 9 (6 1)) (dig-rev-add 8 0 (8)) (dig-rev-add 8 1 (9)) (dig-rev-add 8 2 (0 1)) (dig-rev-add 8 3 (1 1)) (dig-rev-add 8 4 (2 1)) (dig-rev-add 8 5 (3 1)) (dig-rev-add 8 6 (4 1)) (dig-rev-add 8 7 (5 1)) (dig-rev-add 8 8 (6 1)) (dig-rev-add 8 9 (7 1)) (dig-rev-add 9 0 (9)) (dig-rev-add 9 1 (0 1)) (dig-rev-add 9 2 (1 1)) (dig-rev-add 9 3 (2 1)) (dig-rev-add 9 4 (3 1)) (dig-rev-add 9 5 (4 1)) (dig-rev-add 9 6 (5 1)) (dig-rev-add 9 7 (6 1)) (dig-rev-add 9 8 (7 1)) (dig-rev-add 9 9 (8 1))

(rev-add () :a :a)
(rev-add :a () :a)
(<- (rev-add (:a :as ...) (:b :bs ...) (:c :es ...))
    (dig-rev-add :a :b (:c :cs ...))
    (rev-add :as :bs :ds)
    (rev-add :ds :cs :es))

(<- (add :a :b :c)
    (l/reversed :a :ra)
    (l/reversed :b :rb)
    (rev-add :ra :rb :rc)
    (l/reversed :rc :c))
