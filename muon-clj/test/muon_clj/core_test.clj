(ns muon-clj.core-test
  (:require [midje.sweet :refer :all]
            [muon-clj.core :refer :all]))

;; parse translates a Muon s-expression into an AST.
(fact
 (parse 1) => [:int 1]
 (parse 3.14) => [:float 3.14]
 (parse "foo") => [:string "foo"]
 (parse 'bar) => [:symbol "bar"]
 (parse :baz) => [:var "baz"]
 (parse '()) => [:empty-list]
 (parse '(1 2)) => [:pair [:int 1] [:pair [:int 2] [:empty-list]]]
 (parse '(:x :xs ...)) => [:pair [:var "x"] [:var "xs"]]
 (parse []) => [:empty-vec]
 (parse ['a 'b]) => [:pair [:symbol "a"] [:pair [:symbol "b"] [:empty-vec]]]
 (parse '[:x :xs ...]) => [:pair [:var "x"] [:var "xs"]]
 (parse {}) => (throws Exception "Invalid Muon expression {}"))

;; format-muon formats an AST into a Muon s-expression.
(fact
 (format-muon [:int 1]) => 1
 (format-muon [:float 3.14]) => 3.14
 (format-muon [:string "foo"]) => "foo"
 (format-muon [:symbol "bar"]) => 'bar
 (format-muon [:var "baz"]) => :baz
 (format-muon [:var 42]) => :#42  ;; Numeric vars are prefixed with a #.
 (format-muon [:empty-list]) => '()
 (format-muon [:pair [:int 1] [:pair [:int 2] [:empty-list]]]) => '(1 2)
 (format-muon [:pair [:var "x"] [:var "xs"]]) => '(:x :xs ...)
 (format-muon [:empty-vec]) => []
 (format-muon [:pair [:symbol "a"] [:pair [:symbol "b"] [:empty-vec]]]) => ['a 'b])

;; alloc-vars takes a Muon AST and an integer atom, and allocates integers in place of the string :var nodes.
;; It does so consistently, such that the same string will be mapped to the same number.
;; The returned AST has numeric :vars but is otherwise identical to the original AST.
(fact
 (alloc-vars [:empty-list] (atom 0)) => [:empty-list]
 (alloc-vars [:var "a"] (atom 0)) => [:var 1]
 (alloc-vars [:pair [:var "a"] [:var "b"]] (atom 0)) => [:pair [:var 1] [:var 2]]
 (alloc-vars [:pair [:var "a"] [:var "a"]] (atom 0)) => [:pair [:var 1] [:var 1]]
 (alloc-vars [:pair [:var "a"] [:pair [:int 42] [:pair [:var "a"] [:empty-list]]]] (atom 0)) =>
 [:pair [:var 1] [:pair [:int 42] [:pair [:var 1] [:empty-list]]]])