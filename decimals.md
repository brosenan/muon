  * [Addition](#addition)
```clojure
(ns examples.decimal-test
  (require examples.decimals dec)
  (require testing t))

```
## Addition
Long addition is best done from the units upward.
Therefore, we first define the `rev-add` predicate, which works on reversed decimals,
i.e., decimals for which the first (left-most) digit is the units.
```clojure
(t/test-value rev-add-0+0+0=0
      (dec/rev-add () () 0 :x) :x ())
(t/test-value rev-add-0+0+1=1
      (dec/rev-add () () 1 :x) :x (1))

(t/test-value rev-add-0+12+0=12
      (dec/rev-add () (2 1) 0 :x) :x (2 1))
(t/test-value rev-add-0+12+1=13
      (dec/rev-add () (2 1) 1 :x) :x (3 1))
(t/test-value rev-add-0+19+1=20
      (dec/rev-add () (9 1) 1 :x) :x (0 2))
(t/test-value rev-add-12+0+1=13
      (dec/rev-add (2 1) () 1 :x) :x (3 1))
(t/test-value rev-add-19+0+1=20
      (dec/rev-add (9 1) () 1 :x) :x (0 2))
(t/test-value rev-add-12+1+0=13
      (dec/rev-add (2 1) (1) 0 :x) :x (3 1))
(t/test-value rev-add-12+8+1=21
      (dec/rev-add (2 1) (8) 1 :x) :x (1 2))
(t/test-value rev-add-12+18+1=31
      (dec/rev-add (2 1) (8 1) 1 :x) :x (1 3))

```
Now we can define `add`, which does the same for left-to-right decimals:
```clojure
(t/test-value add-123+2345=2468
      (dec/add (1 2 3) (2 3 4 5) :x) :x (2 4 6 8))
(t/test-value add-99999+1=100000
      (dec/add (9 9 9 9 9) (1) :x) :x (1 0 0 0 0 0))
```

