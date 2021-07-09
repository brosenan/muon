  * [Addition](#addition)
```clojure
(ns examples.decimal-test
  (require examples.decimals dec))

```
## Addition
Long addition is best done from the units upward.
Therefore, we first define the `rev-add` predicate, which works on reversed decimals,
i.e., decimals for which the first (left-most) digit is the units.
```clojure
(test rev-add-0+0+0=0
      (dec/rev-add () () 0 ())
      1)
(test rev-add-0+0+0!=1
      (dec/rev-add () () 0 (1))
      0)
(test rev-add-0+0+1=1
      (dec/rev-add () () 1 (1))
      1)
(test rev-add-0+0+1!=0
      (dec/rev-add () () 1 ())
      0)
(test rev-add-0+12+0=12
      (dec/rev-add () (2 1) 0 (2 1))
      1)
(test rev-add-0+12+0!=13
      (dec/rev-add () (2 1) 0 (3 1))
      0)
(test rev-add-0+12+1=13
      (dec/rev-add () (2 1) 1 (3 1))
      1)
(test rev-add-0+12+1!=12
      (dec/rev-add () (2 1) 1 (2 1))
      0)
(test rev-add-12+0+1=13
      (dec/rev-add (2 1) () 1 (3 1))
      1)
(test rev-add-12+0+1!=12
      (dec/rev-add (2 1) () 1 (2 1))
      0)
(test rev-add-12+1+0=13
      (dec/rev-add (2 1) (1) 0 (3 1))
      1)
(test rev-add-12+1+0!=14
      (dec/rev-add (2 1) (1) 0 (4 1))
      0)
(test rev-add-12+8+1=21
      (dec/rev-add (2 1) (8) 1 (1 2))
      1)
(test rev-add-12+8+1!=20
      (dec/rev-add (2 1) (8) 1  (0 2))
      0)
(test rev-add-12+18+1=31
      (dec/rev-add (2 1) (8 1) 1 (1 3))
      1)
(test rev-add-12+18+1!=30
      (dec/rev-add (2 1) (8 1) 1 (0 3))
      0)

```
Now we can define `add`, which does the same for left-to-right decimals:
```clojure
(test add-123+2345=2468
      (dec/add (1 2 3) (2 3 4 5) (2 4 6 8))
      1)
(test add-123+2345=2469
      (dec/add (1 2 3) (2 3 4 5) (2 4 6 9))
      0)

```

