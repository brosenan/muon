(ns base
  (use clojure.core clj)
  (use Integer int)
  (use Double dbl)
  (require clj-expr expr [clj-expr-name0
                          clj-expr-name1
                          clj-expr-name2
                          clj-expr-name3
                          clj-expr]))

;; Arithmetic operations
(clj-expr-name2 + clj/+)
(clj-expr-name2 - clj/-)
(clj-expr-name2 * clj/*)
(clj-expr-name2 / clj//)
(clj-expr-name2 mod clj/mod)
(clj-expr-name2 div clj/quot)

;; Comparison
(clj-expr-name2 == clj/=)
(clj-expr-name2 > clj/>)
(clj-expr-name2 < clj/<)
(clj-expr-name2 >= clj/>=)
(clj-expr-name2 <= clj/<=)
(clj-expr-name2 != clj/not=)

;; String operations
(clj-expr-name1 strcat clj/str)
(clj-expr-name1 strlen clj/count)
(clj-expr-name3 substr clj/subs)

;; Conversion functions
(clj-expr-name1 string-to-int int/parseInt)
(clj-expr-name1 string-to-float dlb/parseDouble)
(clj-expr-name1 int-to-float clj/float)
(clj-expr-name1 int-to-string clj/str)
(clj-expr-name1 float-to-int clj/int)
(clj-expr-name1 float-to-string clj/str)
