(ns examples.language-test
  (require testing t))

;; # Muon Language Overview

;; In this doc we describe Muon from the ground up. This description refers to the language itself
;; and not to any of its libraries, some of which implement language features such as functional
;; programming (see [expr](expr.md)).
;;
;; This `.md` file is derived from the Muon source file [examples/language-test.mu](examples/language-test.mu).
;; To execute the tests here, use:
;; ```
;; muon -Ta examples.language-test
;; ```
;; This will run the tests continuously, re-running them every time you modify the file. This will
;; allow you to play around with the tests, to get a feel for the language.

;; ## Muon's Syntax

;; Muon is a Lisp. It uses the [Extensible Data Notation (EDN)](https://github.com/edn-format/edn),
;; an s-expression format developed as part of the Clojure ecosystem, as its syntax.
;; In fact, Muon's syntax really _is_ EDN, and not a subset. With the exception of the `ns` statement
;; that must appear at the head of every module, any sequence of valid EDN expressions is a valid Muon
;; program. For example, the following is valid Muon:
42
forty-two
[1 2 3 4 5]
(this is surely wrong)
"foo"

;; ## But What does it Mean?

;; So any valid EDN s-expression is a valid _statement_ in Muon, and a program consists of statements.
;; But what does it all mean?
;;
;; The simplest thing we can do with these statements is to see if they are defined.
;; The following statement is a test that will succeed if and only if the statement `42` is defined.
(t/test-success fourty-two-is-defined
                42)

;; Similarly, the following test will succeed if `43` is not defined.
(t/test-failure fourty-three-not-defined
                43)

;; But obviously, this is not very helpful. To get something meaningful out of our statements,
;; they need to have some structure which we can leverage to make meaningful queries.
;;
;; For example, we can pattern-match against statements.
(t/test-value pattern-match-statement
              (this is :adverb wrong) ;; A pattern to be matched.
              :adverb                 ;; The placeholder (variable) used in the pattern.
              surely)                 ;; Expected value for the variable to match.

;; Here we used the _logic variable_ `:adverb` to match a part of the statement.
;; Out of all the statements we stated in this program, the only one matching the pattern was:
;; ```clojure
;; (this is surely wrong)
;; ```
;; And the variable `:adverb` matched the symbol `surely`.
;;
;; Logic variables are simply placeholders, matching any part of a statement.
;; Once they are matched, we can use them to build other values (terms), like in the following example:
(t/test-value match-and-reconstruct-statement
              (this :verb :adverb :adjective)              ;; Pattern to match
              (there :adverb :verb no :adjective answer)   ;; Pattern to construct based no the same variables
              (there surely is no wrong answer))           ;; The result

;; In the examples above we used variables to match single elements of a list. However, a variable can
;; also match an entire list or the _tail_ of a list. This is done using the `...` symbol, as follows:
(t/test-value pattern-match-vector-tail
              [1 2 :others ...]
              :others
              [3 4 5])

;; In the above example we provided the beginning of a vector (`[]`) and asked to match the rest (`:others`).
;; By placing `...` after `:others`, as the last element of the vector, we told Muon to match `:others` against
;; the rest of the vector rather than the third element.
;;
;; The same can be done with a list:
(t/test-value pattern-match-list-tail
              (this :the-rest ...)
              :the-rest
              (is surely wrong))

;; Note that when we matched the tail of a vector we got a vector and when we matched the tail of a list we got
;; a list. The pattern itself, however, is agnostic of being a vector or a list. For example, the previous
;; test can be written with a list and still pass.
(t/test-value pattern-match-vector-tail-with-a-list
              (1 2 :others ...)
              :others
              [3 4 5])

;; ## Facts

;; The statements we have encountered so far are all considered to be _facts_.
;; You can think of the statement `42` as stating the fact `42`. OK, not a very useful example.
;; This is why numbers do not make useful statements.
;; But with a bit of structure, we can state meaningful facts. For example, the following statements express facts
;; about a famous fictional family:
(mother "Shmi" "Anakin")
(mother "Padme" "Luke")
(mother "Padme" "Lea")
(father "Anakin" "Luke")
(father "Anakin" "Lea")
(mother "Lea" "Ben")
(father "Han" "Ben")

;; By convention, we use a list (`()`) for each fact, with a symbol (`mother`/`father`) as its first element.
;; This is _by convention_. We could have just as well used a more English-like format, such as:
("Shmi" is the mother of "Anakin")

;; The latter is valid, and we can even query it:
(t/test-value who-is-anakin's-mother?
              (:who is the mother of "Anakin")
              :who
              "Shmi")

;; But for several reasons, performance being one of them, we recommend following this convention.
;;
;; Under this convention, the symbol at the beginning of the list is called a _predicate_.
;; This use of the term is derived from [mathematical logic](https://en.wikipedia.org/wiki/Predicate_(mathematical_logic))
;; and is similar to its use in [Prolog](https://en.wikipedia.org/wiki/Prolog), but unlike Prolog, where predicates are
;; fundamental, here they are merely a convention.
;;
;; So now that we have a standard way to define relationships in the royal family of SciFi, we can use it to ask questions,
;; such as who is Luke's father?
(t/test-value who-is-luke's-father?
              (father :who "Luke")
              :who
              "Anakin")

;; Or who is Lea's child?
(t/test-value who-is-lea's-child?
              (mother "Lea" :who)
              :who
              "Ben")

;; Note that these questions _happen to_ have exactly one answer. There are questions, such as who is Anakin's father,
;; that do not have an answer (under the statements in our program).
(t/test-failure who-is-anakin's-father?
                (father :who "Anakin"))

;; We usually refer to such cases as _failures_. But this notion of failure is very different from its meaning in other
;; languages. This is not similar to an exception being thrown or a singnal being raised. Nothing crashed. Everything is
;; behaving as it should. We simply did not find a solution to the question we asked. Or, in other words,
;; the question we asked happened to have zero answers, as we demonstrate in the following test, which is totally equivalent:
(test anakin-has-zero-fathers
      (father :who "Anakin")  ;; Pattern
      0)                      ;; Expected number of matches

;; While Anakin has no fathers our program knows of, he does have two children.
(test anakin-has-two-children
      (father "Anakin" :child)
      2)

;; **Note**: If you are reading this from the source file while running the command written at the top of this doc, you can
;; try to change the number in the test above and see how the test fails. It will list the actual results.

;; Having more than one match for a pattern, just like having zero matches, is too, totally normal.

;; ## Rules

;; The ability to query facts using pattern matching is powerful for some applications, but this is not yet a programming language.
;; To allow full-blown programming capabilities, we need to add reasoning, that is, the ability to draw conclusions from facts.
;;
;; _Rules_ are the way we do this in Muon. A rule is a statement that is a list containing the symbol `<-` followed by one _head_ term
;; and zero or more _body_ terms. The arrow symbol shows the direction of entailment: from the body to the head.
;;
;; For example, the following two rules state that `:parent` is the parent of `:child` if they are either their father or mother.
(<- (parent :parent :child)
    (mother :parent :child))
(<- (parent :parent :child)
    (father :parent :child))

;; These rules define a set of implicit facts of the form `(parent :parent :child)` that are true for whenever `(mother :parent :child)`
;; or `(father :parent :child)`, for some `:parent` and some `:child`.
;;
;; With these rules in place, we can query these new facts as if they were written explicitly.

(test luke-has-two-parents
      (parent :parent "Luke")
      2)
(test anakin-has-just-one-parents
      (parent :parent "Anakin")
      1)
(test padme-has-two-children
      (parent "Padme" :child)
      2)

;; The body of rules can use patterns that were created by other rules. For example, a grandparent is a parent of a parent.
(<- (grandparent :grandparent :grandchild)
    (parent :grandparent :parent)
    (parent :parent :grandchild))

(t/test-value anakin-is-ben's-grandparent
              (grandparent "Anakin" :who)
              :who
              "Ben")

;; ### Recursion

;; Rules can be recursive, that is, their bodies can use patterns that they define.
;; For example, the ancestor of person `:x` is either `:x` him or herself, or any ancestor of any parent of `:x`.
(ancestor :x :x)
(<- (ancestor :x :z)
    (parent :x :y)
    (ancestor :y :z))

;; Ben has himself, his parents, his grandparents on his mother's side and his great-grandmother as ancestors -- a total of six.
(test ben-has-six-ancestors
      (ancestor :x "Ben")
      6)

;; The same relation can allow us to find descendants too.
(test padme-has-four-descendants
      (ancestor "Padme" :x)
      4)

;; ### To Inifinity and Beyond!

;; One of the advantages of recursive rules is the fact that they can describe infinite sets and relations.
;; For example, the [Peano numbers](https://en.wikipedia.org/wiki/Peano_axioms) are a representation of the natural numbers that
;; is defined recursively as follows:
;; * 0 is natural.
;; * For every natural number `:n`, `(s :n)` is a natural number.
(nat 0)
(<- (nat (s :n))
    (nat :n))

;; This defines an infinity of natural numbers. For example:
(t/test-success five-is-natural
                (nat (s (s (s (s (s 0)))))))

;; We can now define [arithmetic](https://en.wikipedia.org/wiki/Peano_axioms#Arithmetic) based on Peano's axioms:
;; * 0 + `:n` = `:n`
;; * (`s` `:n`) + `:m` = (`s` (`:n` + `:m`))
(+ 0 :n :n)
(<- (+ (s :n) :m (s :n+m))
    (+ :n :m :n+m))

;; Note that `+` is not a predefined operator. It is a legal symbol in EDN, and we have just defined its meaning.
;; Now we can have some fun adding natural numbers.
(t/test-value calculate-2+3
              (+ (s (s 0)) (s (s (s 0))) :x)
              :x
              (s (s (s (s (s 0))))))

;; And subtracting...
(t/test-value calculate-4-3
              (+ (s (s (s 0))) :x (s (s (s (s 0)))))
              :x
              (s 0))

(t/test-value calculate-4-1
              (+ :x (s 0) (s (s (s (s 0)))))
              :x
              (s (s (s 0))))

;; What makes it possible for us to do this is the fact that `+`, as we defined it, is a _relation_ rather than a function.
;; One way to look at this is that by defining the rules above we actually defined an infinite number of facts of the form
;; `(+ :x :y :x+y)` where `:x` and `:y` are Peano numbers and `:x+y` is a Peano number representing their sum.
;; However, this view is not always helpful. Sometimes, due to the evaluation order, querying a relation from different directions
;; leads to significantly different performance, up to the point that one direction may never terminate.
;; It takes some experience to know when this is going to be the case. So we suggest that you play around with these toy examples
;; and start building your own so that you get some working experience with Muon.

;; ## Modules

;; Muon has a simple module system that:
;; * Allows for source files to be loaded and
;; * Manages the lexical scope of symbols.
;;
;; **Note**: The information below is not authoritative and may be outdated or incomplete.
;; For authoritative information see the [module system implementation documentation](muon-clj/modules.md).

;; Every Muon file must begin with a `ns` declaration, such as the following:
(ns my.module
  (require some.module m1 [some exported symbols])
  (use some.other.module m2 [exports from this one])
  (require some.third.module m3))

;; It begins with the name of the current module (`my.module` in this case). This has to correspond to the file path with respect to one of the
;; roots provided to the interpreter. For example, `my.module` should reside in the file `my/module.mu`.
;;
;; The module name is followed by zero or more clauses that reference other modules.
;; Both the `request` and `use` clauses have the same structure. They begin with a module name (`some.module`, `some.other.module`
;; and 'some.third.module` respectively), followed by an alias (`m1`, `m2` and `m3` respectively), followed by an optional vector containing symbols.
;;
;; A `require` clause will do all of the following:
;; * Load the file whose path corresponds to the module name.
;; * Make symbols that use the alias as their namespace (e.g., `m1/some-symbol`) in the current module refer to the corresponding symbol in the imported module.
;; * If provided, make all the symbols in the vector refer to the imported module if written without a namespace in the current module.
;;
;; For example, the first `require` clause will load the file `some/module.mu`, make sure that every symbol with the `m1/` prefix in `my.module`
;; will reference the corresponding symbol in `some.module` and make sure that the symbols `some`, `exported` and `symbols` used in `my.module`
;; module without a prefix will reference the corresponding symbols in `some.module`.
;;
;; A `use` does the same except it does _not_ load a module file.
the-end
