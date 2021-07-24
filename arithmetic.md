  * [Arithmetic Operators](#arithmetic-operators)
```clojure
(ns arithmetic-test
  (require arithmetic ar [+ - * /])
  (require testing t)
  (require proc p ['])
  (require native n))

```
The `arithmetic` module defines arithmetic operators (functions) that encapsulate arithmetic NExprs.

## Arithmetic Operators
The `+` operator adds two expressions.
```clojure
(t/test-model +-adds-numbers
              (+ (' 1) (' 2))
              3
              (t/sequential
               (n/+ 1 2) 3))

```
`+` is variadic. For zero arguments it returns 0.
```clojure
(t/test-model +-returns-0-for-0-arguments
              (+)
              0
              (t/sequential))

```
With one argument it returns the argument.
```clojure
(t/test-model +-returns-its-single-argument
              (+ (' some-single-arg))
              some-single-arg
              (t/sequential))

```
With three arguments and more it sums all the arguments in order.
```clojure
(t/test-model +-sums-its-arguments
              (+ (' 1) (' 2) (' 3) (' 4) (' 5))
              15
              (t/sequential
               (n/+ 1 2) 3
               (n/+ 3 3) 6
               (n/+ 6 4) 10
               (n/+ 10 5) 15))

```
The `-` operator takes at least one argument.
```clojure
(t/test-model --returns-single-arg
              (- (' 3))
              3
              (t/sequential))

```
For two arguments it applies the native - operator.
```clojure
(t/test-model --returns-single-arg
              (- (' 3) (' 2))
              1
              (t/sequential
               (n/- 3 2) 1))

```
For more than two arguments, the second is subtracted from the first
and then the rest are subtracted from the result.
```clojure
(t/test-model --returns-single-arg
              (- (' 15) (' 5) (' 4) (' 3) (' 2))
              1
              (t/sequential
               (n/- 15 5) 10
               (n/- 10 4) 6
               (n/- 6 3) 3
               (n/- 3 2) 1))

```
'*' returns 1 when called with no arguments
```clojure
(t/test-model *-with-no-args-returns-1
              (*)
              1
              (t/sequential))

```
With one argument it just returns it.
```clojure
(t/test-model *-with-one-arg-returns-it
              (* (' something...))
              something...
              (t/sequential))

```
With two arguments it calls the native * operator.
```clojure
(t/test-model *-with-two-args-multiplies-them
              (* (' 2) (' 3))
              6
              (t/sequential
               (n/* 2 3) 6))

```
With more than two arguments, the arguments are multiplied in order.
```clojure
(t/test-model *-with-multiple-args-multiplies-them-in-order
              (* (' 1) (' 2) (' 3) (' 4) (' 5))
              120
              (t/sequential
               (n/* 1 2) 2
               (n/* 2 3) 6
               (n/* 6 4) 24
               (n/* 24 5) 120))

```
The `/` operator takes at least one argument. With one argument, it returns the argument itself.
```clojure
(t/test-model div-with-single-arg-returns-arg
              (/ (' this-is-something-good))
              this-is-something-good
              (t/sequential))

```
With two arguments, it calls the native `/` operator.
```clojure
(t/test-model div-with-single-arg-returns-arg
              (/ (' 6) (' 2))
              3
              (t/sequential
               (n// 6 2) 3))

```
With more than two arguments, it first divides the first by the second and then divides
the result by each of the other arguments in order.
```clojure
(t/test-model div-with-single-arg-returns-arg
              (/ (' 120) (' 5) (' 4) (' 3) (' 2))
              1
              (t/sequential
               (n// 120 5) 24
               (n// 24 4) 6
               (n// 6 3) 2
               (n// 2 2) 1))
```

