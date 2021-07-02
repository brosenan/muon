(ns muon-clj.core-test
  (:require [midje.sweet :refer :all]
            [muon-clj.core :refer :all]))

;; ## Term Handling

;; `parse` translates a Muon s-expression into an AST.
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

;; `format-muon` formats an AST into a Muon s-expression.
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

;; `alloc-vars` takes a Muon AST and an integer `atom`, and allocates integers in place of the string `:var` nodes.
;; It does so consistently, such that the same string will be mapped to the same number.
;; The returned AST has numeric `:vars` but is otherwise identical to the original AST.
(fact
 (alloc-vars [:empty-list] (atom 0)) => [:empty-list]
 (alloc-vars [:var "a"] (atom 0)) => [:var 1]
 (alloc-vars [:pair [:var "a"] [:var "b"]] (atom 0)) => [:pair [:var 1] [:var 2]]
 (alloc-vars [:pair [:var "a"] [:var "a"]] (atom 0)) => [:pair [:var 1] [:var 1]]
 (alloc-vars [:pair [:var "a"] [:pair [:int 42] [:pair [:var "a"] [:empty-list]]]] (atom 0)) =>
 [:pair [:var 1] [:pair [:int 42] [:pair [:var 1] [:empty-list]]]])

;; [Term unification](https://en.wikipedia.org/wiki/Unification_(computer_science)) is an operation that looks for a set of variable bindings that,
;; if assigned, make two logic terms that contain these variables identical.
;;
;; `unify` takes a pair of terms and a (possibly empty) map of variable bindings and returns either `nil`,
;; if the terms cannot be unified, or, if they can be unified, it returns the map of variable assignments that satisfies the unification.
(fact
 (unify [:int 1] [:int 2] {}) => nil
 (unify [:int 1] [:int 1] {"a" [:int 3]}) => {"a" [:int 3]}
 (unify [:var "foo"] [:int 1] {}) => {"foo" [:int 1]}
 (unify [:var "foo"] [:int 1] {"foo" [:int 2]}) => nil
 (unify [:var "foo"] [:int 1] {"foo" [:int 1]}) => {"foo" [:int 1]}
 (unify [:int 1] [:var "foo"] {}) => {"foo" [:int 1]}
 (unify [:int 1] [:var "foo"] {"foo" [:int 2]}) => nil
 (unify [:int 1] [:var "foo"] {"foo" [:int 1]}) => {"foo" [:int 1]}
 (unify [:pair [:var "x"] [:int 2]] [:pair [:int 1] [:var "y"]] {}) => {"x" [:int 1] "y" [:int 2]}
 (unify [:pair [:var "x"] [:int 2]] [:pair [:int 1] [:var "x"]] {}) => nil
 (unify [:pair [:int 2] [:int 3]] [:pair [:int 1] [:var "x"]] {}) => nil
 (unify [:pair [:var "x"] [:int 2]] [:not-a-pair [:int 1] [:var "y"]] {}) => nil)

;; ## Program Handling

;; A Muon program consists of _statements_, which are individual expressions. Each statement can either be a _fact_ or a _rule_.
;; A rule is a statement of the form `(<- :head :body ...)` where `:head` is a single term and `:body` is a list of zero or more terms.
;; A fact, in contrast is a single term.
;;
;; To simplify the handling of facts and rules, the `normalize-statement` function takes statements (facts or rules), and returns a pair
;; `[:head :body]` such that for a rule `(<- :head :body ...)` `:head` and `:body` are taken verbatim, and for a fact `:fact`, `:head`
;; is taken as `:fact` and `:body` is taken as `()`.
(fact
 (map format-muon
      (-> '(<- (foo :bar)
               (bar :foo)) parse normalize-statement)) => ['(foo :bar) ['(bar :foo)]]
 (map format-muon
      (-> '(foo :bar) parse normalize-statement)) => ['(foo :bar) []])

;; Normalized rules are stored in a database keyed by all their symbol prefixes.
(fact
 (-> 2 parse term-key) => []
 (-> 'foo parse term-key) => ["foo"]
 (-> '(foo) parse term-key) => ["foo"]
 (-> '(foo bar) parse term-key) => ["foo" "bar"]
 (-> '(foo (bar (baz))) parse term-key) => ["foo" "bar" "baz"]
 (-> '(foo (:bar (baz))) parse term-key) => ["foo"])

;; `load-program` takes a collection of Muon statements, parses them, normalizes them and builds a database: a map from keys to lists of normalized pairs.
(fact
 (let [program `[(nat z)
                 (<- (nat (s :n))
                     (nat :n))]
       db (load-program program)]
   (-> ["nat" "z"] db count) => 1
   (-> ["nat" "z"] db first (->> (map format-muon))) => '[(nat z) ()]
   (-> ["nat" "s"] db count) => 1
   (-> ["nat"] db count) => 2))

;; ## Evaluation

;; The state of the evaluation consists of a sequence of (`goal-list`, `bindings`) pairs,
;; where the `goal-list` consists of the logic goals to be satisfied and `bindings` is a map from variable names to their assigned values.
;; Each element in the sequence represents an alternative that needs to be explored.
;; An empty `goal-list` indicates a result, and an empty sequence indicates the end of the evaluation, with no more options to explore.
;;
;; The evaluation process is done in steps. In each step, the first (`goal-list`, `bindings`) pair is taken out of the sequence and
;; the first goal in the `goal-list` is matched against the database.
;; Every match results in an option to explore.
;; The body of each matching rule is prepended to the `goal-list` and the `bindings` are updated with the result of the unification of the head.
;;
;; We begin describing this process bottom-up.
;; As a first step, `match-rules` takes a goal (term AST), a bindings map, a database map and an integer `atom` for allocating fresh variables.
;; It returns a sequence (`goal-list`, `bindings`) pairs, one for each successful match.
(fact
 (let [db (load-program '[(foo 1)
                          (<- (foo :x)
                              (bar :x :y)
                              (foo :y))])]
   (match-rules (parse `(bar 1 2)) {}, db, (atom 0)) => []
   (match-rules (parse `(foo :x)) {}, db, (atom 0)) => [[[] {"x" [:int 1]}]
                                                        [[[:pair [:symbol "bar"] [:pair [:var 1] [:pair [:var 2] [:empty-list]]]]
                                                          [:pair [:symbol "foo"] [:pair [:var 2] [:empty-list]]]]
                                                         {1[:var "x"]}]]))

;; ## Implementation Details
(fact
 (all-prefixes [1 2 3 4]) => [[1] [1 2] [1 2 3] [1 2 3 4]]
 (ast-list-to-seq [:pair [:int 1] [:pair [:int 2] [:empty-list]]]) => [[:int 1] [:int 2]])