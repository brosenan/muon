(ns proc-test
  (require proc p [defproc do let])
  (require testing t))

;; This module is responsible for defining procedural, or imperative constructs for Muon.
;; This is done in terms of the `p/step` predicate, which implements a state-machine using the [QEPL](muon-clj/qepl.md).

;; ## Doing Things in Sequence
;; The `do` construct contains instructions that are processed in sequence.
;; If an instruction is an expression to be evaluated by the QEPL (or its simulator),
;; the evaluation result is ignored.
(t/test-success do-empty-is-done
                (t/qepl-sim (do) ()
                            (t/sequential)))
(t/test-success do-executes-in-sequence
                (t/qepl-sim (do
                              (println "one")
                              (println "two")
                              (println "three")) ()
                            (t/sequential
                             (println "one") 1
                             (println "two") 2
                             (println "three") 3)))

;; `do`s can be nested.
(t/test-success do-nested
                (t/qepl-sim (do
                              (do (println "one")
                                  (do (println "two")))
                              (do (println "three"))) ()
                            (t/sequential
                             (println "one") 1
                             (println "two") 2
                             (println "three") 3)))

;; Letting Values be Captured
;; The `let` construct takes a vector of bindings ((variable, expression) pairs) and zero or more expressions.
;; It evaluates (through the QEPL) each expression in the bindings and binds the result to the associated variable.
;; Then it evaluates the expressions for their side effects, just like a `do`.
(t/test-success let-as-do
                (t/qepl-sim (let []
                              (println "one")
                              (println "two")
                              (println "three")) ()
                            (t/sequential
                             (println "one") 1
                             (println "two") 2
                             (println "three") 3)))

 (t/test-success let-binds-vars
                 (t/qepl-sim (let [:name (input-line)
                                   :greeting (strcat "Hello, " :name)]
                               (println :greeting)) ()
                             (t/sequential
                              (input-line) "Muon"
                              (strcat "Hello, " "Muon") "Hello, Muon"
                              (println "Hello, Muon") ())))

