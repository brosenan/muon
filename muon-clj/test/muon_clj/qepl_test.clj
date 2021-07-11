(ns muon-clj.qepl-test
  (:require [midje.sweet :refer :all]
            [muon-clj.qepl :refer :all]
            [muon-clj.core :as core]))

;; Muon is a purely declarative logic programming language.
;; Being pure gives it some advantages over non-pure logic programming languages such as Prolog
;; because it makes the logic more predictable (side effects do not interfere with the logic).
;; But as a down-side, with term manipulation alone you cannot interact with users,
;; write to disk or to databases or communicate across networks.
;;
;; To allow Muon programmers to do all these things, we introduce the _QEPL_.
;;
;; Borrowing from [REPL](https://en.wikipedia.org/wiki/Read%E2%80%93eval%E2%80%93print_loop), QEPL stands for __Query-Eval-Parse Loop__.
;; This is a loop that runs outside the Muon program and starts with the Query step, which
;; queries the Muon program for the next `muon/clj-step`, given a certain initial state.
;; The response could be either `muon/return`, which ends the loop, or `muon/continue`, which also provides two arguments:
;; * A Clojure expression to be evaluated, and
;; * The next state.
;;
;; The Eval step takes the given Clojure expression and [eval](https://clojuredocs.org/clojure.core/eval)s it.
;; The result is the [parsed](core.md#term-handling) (the Parse step) to a Muon AST and then used,
;; along with the next state received from the query, in the next Query step.
;;
;; ## Successful QEPL Scenario
;; In the following example, we define a small Muon program that asks the user for their name and then greets them.
(defn my-println [arg]
  (println arg))

(fact
 (let [db (core/load-program '[(muon/clj-step 1 :input (muon/continue (muon-clj.qepl-test/my-println "What is your name?") 2))
                               (muon/clj-step 2 :input (muon/continue (clojure.core/read-line) 3))
                               (muon/clj-step 3 :input (muon/continue (clojure.core/str "Hello, " :input) 4))
                               (muon/clj-step 4 :input (muon/continue (muon-clj.qepl-test/my-println :input) 5))
                               (muon/clj-step 5 :input (muon/return 42))])]
   (qepl db [:int 1]) => 42
   (provided
    (my-println "What is your name?") => nil
    (read-line) => "Muon"
    (my-println "Hello, Muon") => nil)))

;; Given a state and an input, `clj-step` needs to succeed deterministically.
;; If the number of results is different than one, an exception is raized.
(fact
 (let [db (core/load-program '[(muon/clj-step 1 :input (muon/continue (muon-clj.qepl-test/my-println "What is your name?") 2))
                               (muon/clj-step 1 :input (muon/continue (muon-clj.qepl-test/my-println "Was heißt du?") 2))
                               (muon/clj-step 2 :input (muon/return 43))])]
   (qepl db [:int 1]) => (throws "Ambiguous progression for state: 1\n")
   (qepl db [:int 3]) => (throws "No progression for state: 3\n")))

;; State can be made of compound terms.
;; In the following example, the state consists of a list of strings to be printed.
(fact
 (let [db (core/load-program '[(muon/clj-step (:x :xs muon/...) :input (muon/continue (muon-clj.qepl-test/my-println :x) :xs))
                               (muon/clj-step () :input (muon/return 5))])]
   (qepl db (core/parse '("one" "two" "three"))) => 5
   (provided
    (my-println "one") => nil
    (my-println "two") => nil
    (my-println "three") => nil)))
