  * [Value Testing](#value-testing)
  * [Success and Failure Testing](#success-and-failure-testing)
  * [QEPL Simulation](#qepl-simulation)
    * [Models](#models)
      * [Sequential Model](#sequential-model)
```clojure
(ns testing-test
  (require testing t)
  (require proc p))

```
The `test` predicate is the main way of defining tests in Muon.
It is covered int [the Clojure implementation documentation](muon-clj/testing.md).
This documentation covers utility predicates intended to make tests simpler to work with.
```clojure
(foo "bar")

```
## Value Testing
A common use-case for testing is when we wish to compare a value provided by some goal
against an expected value.
Normally, this would be done by evaluating the value and then comparing it against the expected value.
However, in pure logic programming, the goal can succeed trivially, by providing a free variable rather than a concrete value.
To address this, the `test-value` predicate allows its users to define tests in which we make sure that the goal matches the expected value,
but not trivially.
We do this by translating every `test-value` result into two `test` results, one expecting one success with the concrete value,
and one expecting failure with a different value.
```clojure
(t/test-value foo-returns-bar
              (foo :x) :x "bar")
(test test-value-creates-two-tests
      (test foo-returns-bar :test :count)
      2)
(test test-value-creates-test-for-value
      (test foo-returns-bar (foo "bar") 1)
      1)
(test test-value-creates-anti-test-for-arbitrary-value
      (test foo-returns-bar (foo t/not-a-value) 0)
      1)

```
## Success and Failure Testing
`t/test-success` tests that the goal succeeds exactly once.
It does that by contributing a `muon/test` with 1 as the expected number of results.
```clojure
(t/test-success foo-bar-succeeds
                (foo "bar"))
(t/test-value test-success-creates-a-test
              (test foo-bar-succeeds :goal :num-results)
              [:goal :num-results]
              [(foo "bar") 1])

```
Similarly, `t/test-failure` tests that the goal fails.
```clojure
(t/test-failure foo-baz-fails
                (foo "baz"))
(t/test-value test-failure-creates-a-test
              (test foo-baz-fails :goal :num-results)
              [:goal :num-results]
              [(foo "baz") 0])

```
## QEPL Simulation
While the QEPL runs outside the Muon program, we allow for simulating it for testing.
### Models
The simulation of the QEPL is based on the notion of a _model_, an object that represents the simulated state of the world
and determines how expressions are to be evaluated, while simulating side-effects by mutating its own state.
A model needs to provide solutions for the `t/handle-expr` and `t/final?` predicates.
`(t/handle-expr :model :expr :result :next-model)` succeeds if `:model` accepts expression `:expr`,
providing `:result` as the value it evaluates to and `:next-model` as the next state to replace `:model`.
`(t/final? :model)` succeeds if `:model` represents a final state, i.e., allows for `p/step` to return `muon/done`.
To demonstrate some of the following model types we will consider the following program,
which asks a user for their name and then greets them.
```clojure
(p/step (some-state 1) :input (continue (print "What is your name?") (some-state 2)))
(p/step (some-state 2) :input (continue (input-line) (some-state 3)))
(p/step (some-state 3) :input (continue (strcat "Hello, " :input) (some-state 4)))
(p/step (some-state 4) :input (continue (print :input) (some-state 5)))
(p/step (some-state 5) :input (return 0))

```
#### Sequential Model
`t/sequential` is arguably the simplest possible model.
It takes an even number of arguments consisting of (expr, result) pairs
and expects that the expressions be evaluated in order.
```clojure
(t/test-value sequential-model
              (t/qepl-sim (some-state 1) () :output
                          (t/sequential
                           (print "What is your name?") ()
                           (input-line) "Muon"
                           (strcat "Hello, " "Muon") "Hello, Muon"
                           (print "Hello, Muon") ())) :output 0)

```
The only accepting state of the model is the one where all its expressions have been evaluated.
```clojure
(t/test-failure sequential-model-fails-on-extra-expressions
                (t/qepl-sim (some-state 1) () :output
                            (t/sequential
                             (print "What is your name?") ()
                             (input-line) "Muon"
                             (strcat "Hello, " "Muon") "Hello, Muon"
                             (print "Hello, Muon") ()
                             (print "Something else...") ())))
```
