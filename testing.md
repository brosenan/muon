  * [Value Testing](#value-testing)
    * [Value Debugging](#value-debugging)
  * [Success and Failure Testing](#success-and-failure-testing)
  * [QEPL Simulation](#qepl-simulation)
    * [Model Testing](#model-testing)
    * [Model Debugging](#model-debugging)
    * [Models](#models)
      * [Pure Model](#pure-model)
      * [Sequential Model](#sequential-model)
      * [Definition-Based-Model](#definition-based-model)
      * [Model Composition](#model-composition)
```clojure
(ns testing-test
  (require testing t)
  (require proc p [>>]))

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
We do this by translating every `test-value` result into three `test` results, one expecting one success with the concrete value,
one expecting failure with a different value and a third that expects exactly one success while providing a free variable as the result.
```clojure
(t/test-value foo-returns-bar
              (foo :x) :x "bar")
(test test-value-creates-three-tests
      (test foo-returns-bar :test :count)
      3)
(test test-value-creates-test-for-value
      (test foo-returns-bar (foo "bar") 1)
      1)
(test test-value-creates-anti-test-for-arbitrary-value
      (test foo-returns-bar (foo t/not-a-value) 0)
      1)
(test test-value-creates-test-for-single-result
      (test foo-returns-bar (foo some-value-to-match-a-free-var) 1)
      1)

```
### Value Debugging

One thing that `test-value` does not do is, in case the goal succeeds but produces an unexpected value, provide this value.
`test-value?` is intended to address this need. It has the same syntax as `test-value` with the only difference being
the added `?`.
```clojure
(t/test-value? bar-returns-foo
               (bar :x) :x "foo")

```
But it behaves differently. It matches the result to a free variable and expects 0 results (i.e., expects failure).
```clojure
(test test-value?-creates-test-for-zero-results
      (test bar-returns-foo (bar some-value-to-match-a-free-var) 0)
      1)

```
As a result, the test will fail, but the actual return value will be logged in the failure message.

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

While the QEPL runs outside the Muon program, Muon does allow for simulating it for testing.

The simulation of the QEPL is based on the notion of a _model_, an object that represents the simulated state of the world
and determines how expressions are to be evaluated, while simulating side-effects by mutating its own state.

### Model Testing

`t/test-model` defines tests that test for an expected output given an initial state and a model.
Any such test definition is converted into a corresponding `t/test-value` result.
For example, given the following definition (see [below](#sequential-model) for details about the model in use here):
```clojure
(t/test-model my-model-test
              (>> input-line)
              "foo"
              (t/sequential
               (input-line) "foo"))
```
The following `t/test-value` is defined:
```clojure
(t/test-value my-model-test-defines-a-test-value
              (t/test-value my-model-test :args ...)
              :args
              ((t/qepl-sim (>> input-line) () x (t/sequential
                                                 (input-line) "foo"))
               x
               "foo"))

```
### Model Debugging

The `t/test-model?` predicate has syntax similar to `t/test-model` (with the only difference being the `?`),
but instead of defining a test that succeeds on a successful execution, the test it creates expects failure,
and in case of success it prints the result, which in this case includes the outcome of tracing through the
model.

For example, the following definition:
```clojure
(t/test-model? my-model-test-debugging
               some-state
               some-result
               some-model)

```
will emit the following test:
```clojure
(t/test-value my-model-test-debugging-defines-a-test
              (test my-model-test-debugging :others ...)
              :others
              ((t/qepl-trace some-state some-model () placeholder-for-the-outcome) 0))

```
### Models

A model needs to provide solutions for the `t/act` and `t/is-final` predicates.
`(t/act :model :action :result :next-model)` succeeds if `:model` accepts action `:action`,
providing `:result` as the value it evaluates to and `:next-model` as the evolution of `:model` as a result of the action.
`(t/is-final :model :final?)` succeeds for any model, binding `:final?` to `true` if `:model` represents a final state,
i.e., allows for `p/step` to return `muon/done`. Otherwise, `:final?` is bound to `false` (`t/is-final` always succeeds for
any valid model).

To demonstrate some of the following model types we will consider the following program,
which asks a user for their name and then greets them.
```clojure
(p/step (some-state 1) :input (continue (print "What is your name?") (some-state 2)))
(p/step (some-state 2) :input (continue (input-line) (some-state 3)))
(p/step (some-state 3) :input (continue (strcat "Hello, " :input) (some-state 4)))
(p/step (some-state 4) :input (continue (print :input) (some-state 5)))
(p/step (some-state 5) :input (return 0))

```
#### Pure Model

`t/pure` is arguably the simplest possible model. It does not allow any actions to be performed, thus restricting the code
to being purely declarative.
```clojure
(t/test-failure pure-does-not-allow-actions
                (t/act t/pure :_action :_result :_next))

```
It is a final state.
```clojure
(t/test-value pure-is-final
              (t/is-final t/pure :final?)
              :final?
              true)

```
In the example above, only `(some-state 5)` is pure.
```clojure
(t/test-model some-state-5-is-pure
              (some-state 5)
              0
              t/pure)

```
#### Sequential Model

`t/sequential` takes an even number of arguments consisting of (expr, result) pairs
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
#### Definition-Based Model

`t/sequential` is very strict in the sense that we have to tell it exactly which actions will be requested and
in which order. Sometimes we wish to be more lenient and not have to explicitly specify the actions or their order.
We do, however, have to provide results for the actions since they have an effect on the execution.

To address this, `t/defaction` allows us to define a result for a given action. For example, here we define
the behavior of some of the actions used in the example program.
```clojure
(t/defaction (print :_s) ())  ;; print returns () regardless of input.
(t/defaction (strcat "Hello, " "Muon") "Hello, Muon")

```
The `t/by-def` model can perform the defined actions, returning the defined results.
```clojure
(t/test-value by-def-returns-action-result
              (t/act (t/by-def (1 2))
                     (strcat "Hello, " "Muon") :result :next)
              :result
              "Hello, Muon")

```
The argument it takes is a [decimal](decimals.md) that represents the action count (number of expected actions).
Every action decrements this number.
```clojure
(t/test-value by-def-transitions-to-itself
              (t/act (t/by-def (1 2)) (strcat "Hello, " "Muon") :result :next)
              :next
              (t/by-def (1 1)))

```
It is final if and only if the action count is zero.
```clojure
(t/test-value by-def-is-not-final-for-non-zero-action-count
              (t/is-final (t/by-def (0 0 1)) :final?)
              :final?
              false)
(t/test-value by-def-is-final-for-zero-action-count
              (t/is-final (t/by-def (0 0 0)) :final?)
              :final?
              true)

```
#### Model Composition

A model composition is any model that combines one or more models.

The `t/|` model is constructed with one or more models as arguments. If any of the underlying models can act on a given action,
the model can act on it, providing that result.
```clojure
(t/test-value |-acts-on-first-submodel
              (t/act (t/| (t/sequential (foo) 1)
                          (t/sequential (bar) 2))
                     (foo) :result :_next)
              :result
              1)
(t/test-value |-acts-on-second-submodel
              (t/act (t/| (t/sequential (foo) 1)
                          (t/sequential (bar) 2))
                     (bar) :result :_next)
              :result
              2)

```
When acting on any of its submodels, it evolves that model.
```clojure
(t/test-value |-evolves-first-submodel
              (t/act (t/| (t/sequential (foo) 1)
                          (t/sequential (bar) 2))
                     (foo) :_result :next)
              :next
              (t/| (t/sequential)
                   (t/sequential (bar) 2)))
(t/test-value |-evolves-second-submodel
              (t/act (t/| (t/sequential (foo) 1)
                          (t/sequential (bar) 2))
                     (bar) :_result :next)
              :next
              (t/| (t/sequential (foo) 1)
                   (t/sequential)))

```
`t/|` is accepting if and only if all of its submodels are accepting.
```clojure
(t/test-value |-is-accepting-if-all-submodels-are-accepting
              (t/is-final (t/| (t/sequential) (t/by-def ())) :final?)
              :final?
              true)
(t/test-value |-is-not-accepting-if-first-submodel-is-not-accepting
              (t/is-final (t/| (t/sequential (foo) 1) (t/by-def ())) :final?)
              :final?
              false)
(t/test-value |-is-not-accepting-if-second-submodel-is-not-accepting
              (t/is-final (t/| (t/by-def ()) (t/sequential (foo) 1)) :final?)
              :final?
              false)

```
Now we can combine (almost) all of our model types and simulate the example program.
```clojure
(t/test-model example-program-using-all-models
              (some-state 1)
              0
              (t/| (t/by-def (3))
                   (t/sequential
                    (input-line) "Muon")))
```

