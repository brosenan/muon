(ns decimals
  (require logic l [case =])
  (require lists ls [reversed]))

(digits (0 1 2 3 4 5 6 7 8 9))

(<- (inc-digit :digit :next :carry)
    (digits :digits)
    (inc-digit :digit :digits :next :carry))
(inc-digit 9 0 true)

(inc-digit :digit (:digit :next :digits ...) :next false)
(<- (inc-digit :digit (:_digit :digits ...) :next :carry)
    (inc-digit :digit :digits :next :carry))

(<- (dec-digit :digit :prev :carry)
    (digits :digits)
    (dec-digit :digit :digits :prev :carry))
(dec-digit 0 9 true)

(dec-digit :digit (:prev :digit :_digits ...) :prev false)
(<- (dec-digit :digit (:_digit :digits ...) :prev :carry)
    (dec-digit :digit :digits :prev :carry))

(inc-rev () (1))
(<- (inc-rev (:digit :digits ...) (:next :more-digits ...))
    (inc-digit :digit :next :carry)
    (case :carry
      false (= :more-digits :digits)
      true (inc-rev :digits :more-digits)))

(<- (dec-rev (:digit :digits ...) (:prev :more-digits ...))
    (dec-digit :digit :prev :carry)
    (case :carry
      false (= :more-digits :digits)
      true (dec-rev :digits :more-digits)))

(<- (inc :n :n+1)
    (reversed :n :n-rev)
    (inc-rev :n-rev :n+1-rev)
    (reversed :n+1-rev :n+1))

(<- (dec :n :n-1)
    (reversed :n :n-rev)
    (dec-rev :n-rev :n-1-rev)
    (reversed :n-1-rev :n-1))

(is-zero () true)
(<- (is-zero (0 :digits ...) :zero?)
    (is-zero :digits :zero?))
(<- (is-zero (:digit :_digits ...) false)
    (digits (0 :other-digits ...))
    (member :digit :other-digits))

(member :x (:x :_ys ...))
(<- (member :x (:_y :ys ...))
    (member :x :ys))