(ns muon-clj.modules-test
  (:require [midje.sweet :refer :all]
            [muon-clj.modules :refer :all]
            [clojure.java.io :as io]))

;; ## Namespace Conversions

;; Namespace conversion is the process of converting the symbols used in a Muon module from their
;; _local_ form, i.e., relative to the definitions of the module, to their _global_ form,
;; i.e., using absolute namespace names.
;;
;; The function `convert-ns` takes an s-expression and two maps.
;; It [walks](https://clojuredocs.org/clojure.walk) through the expression, converting symbols based on them.
;;
;; The first map is the `ns-map`, converting local namespaces into global ones.
;; A `nil` key represents the default namespace.
(fact
 (convert-ns 3 {nil "bar.baz"} {}) => 3
 (convert-ns 'foo {nil "bar.baz"} {}) => 'bar.baz/foo
 (convert-ns '(foo x/quux 3) {nil "bar.baz"
                              "x" "xeon"} {}) => '(bar.baz/foo xeon/quux 3))

;; The second map is the `refer-map`, similar to the `:refer` operator in Clojure `:require` expressions.
;; It maps the names of namspace-less symbols into namespaces they are provided with, as override over
;; the `ns-map`.
(fact
 (convert-ns 'foo {nil "bar.baz"} {"foo" "quux"}) => 'quux/foo
 (convert-ns '(foo bar) {nil "default"} {"foo" "quux"}) => '(quux/foo default/bar))

;; ## Module Names and Paths

;; Similar to Python, Java and Clojure, Muon modules are given names that correspond to their paths in the file system,
;; to allow the module system to find them within the file-system.
;; Like Python and Java, Muon has a `MUON_PATH`, an ordered set of path prefixes in which the module system should look
;; for modules.
;;
;; `module-paths` takes a dot-separated module name and a sequence of base paths (the `MUON_PATH`) and returns a sequence
;; of `java.io.File` objects representing the different candidate paths for this module.
(fact
 (module-paths "foo.bar.baz" ["/one/path" "/two/path"]) => [(io/file "/one/path" "foo" "bar" "baz.mu") 
                                                            (io/file "/two/path" "foo" "bar" "baz.mu")])

;; The function `read-module` (not shown here) uses `module-paths` to determine the path candidates for the module,
;; and reads (as string) the first one that exists.

