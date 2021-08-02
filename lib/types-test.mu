(ns types-test
  (require testing t)
  (require types ty))

;; # Types
;; This module defines predicates to determine the type of a given term.

;; ## Literals
;; `int?` succeeds for int literals and fails for all other terms.
(t/test-success int?-succeeds-for-ints
                (ty/int? 42))
(t/test-failure int?-fails-for-non-ints
                (ty/int? 42.0))

;; `float?` succeeds for float literals and fails for all other terms.
(t/test-success float?-succeeds-for-floats
                (ty/float? 3.14))
(t/test-failure float?-fails-for-non-floats
                (ty/float? 314))

;; `string?` succeeds for string literals and fails for all other terms.
(t/test-success string?-succeeds-for-strings
                (ty/string? "this is a string"))
(t/test-failure string?-fails-for-non
                (ty/string? this-is-not-a-string))

;; `bool?` succeeds for `true` and `false` but not for anything else.
(t/test-success bool?-succeeds-for-true
                (ty/bool? true))
(t/test-success bool?-succeeds-for-false
                (ty/bool? false))
(t/test-failure bool?-fails-for-non-bool
                (ty/bool? 42))

;; ## Lists and Vectors
;; `list?` succeeds for any list (empty or not).
(t/test-success list?-succeeds-for-empty-list
                (ty/list? ()))
(t/test-success list?-succeeds-for-non-empty-list
                (ty/list? (1 2 3)))
(t/test-failure list?-fails-for-vectors
                (ty/list? [1 2 3]))

;; `vector?` succeeds for any vector (empty or not).
(t/test-success vector?-succeeds-for-empty-vector
                (ty/vector? []))
(t/test-success vector?-succeeds-for-non-empty-vector
                (ty/vector? [1 2 3]))
(t/test-failure vector?-fails-for-lists
                (ty/vector? (1 2 3)))