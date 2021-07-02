(ns muon-clj.core-test
  (:require [midje.sweet :refer :all]
            [muon-clj.core :refer :all]))

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
