* [Input and Output](#input-and-output)
  * [Console Input and Output](#console-input-and-output)
```clojure
(ns expr.io-test
  (require testing t)
  (require expr.io io)
  (use native.io nio))

```
# Input and Output

This module provides functions for performing input and output operations.

## Console Input and Output

`println` takes zero or more strings, concatenates them and prints them.
```clojure
(t/test-model println-with-one-arg
              (io/println "hello, world")
              ()
              (t/sequential
               (nio/println "hello, world") ()))
```

