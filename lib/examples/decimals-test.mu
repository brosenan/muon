(ns examples.decimal-test
  (require examples.decimals dec))

;; ## Addition
;; ### Digit Addition
(test dig-rev-add-1+2=3
      (dec/dig-rev-add 1 2 (3))
      1)
(test dig-rev-add-1+2-not-eq-4
      (dec/dig-rev-add 1 2 (4))
      0)

;; ### Long Addition
;; Long addition is best done from the units upward.
;; Therefore, we first define the `rev-add` predicate, which works on reversed decimals,
;; i.e., decimals for which the first (left-most) digit is the units.
(test rev-add-0+12=12
      (dec/rev-add () (2 1) (2 1))
      1)
(test rev-add-0+12!=13
      (dec/rev-add () (2 1) (3 1))
      0)
(test rev-add-12+0=12
      (dec/rev-add (2 1) () (2 1))
      1)
(test rev-add-12+0!=13
      (dec/rev-add (2 1) () (3 1))
      0)
(test rev-add-12+1=13
      (dec/rev-add (2 1) (1) (3 1))
      1)
(test rev-add-12+1!=14
      (dec/rev-add (2 1) (1) (4 1))
      0)
(test rev-add-12+8=20
      (dec/rev-add (2 1) (8) (0 2))
      1)
(test rev-add-12+8!=21
      (dec/rev-add (2 1) (8) (1 2))
      0)
(test rev-add-12+18=30
      (dec/rev-add (2 1) (8 1) (0 3))
      1)
(test rev-add-12+18!=31
      (dec/rev-add (2 1) (8 1) (1 3))
      0)

;; Now we can define `add`, which does the same for left-to-right decimals:
(test add-123+2345=2468
      (dec/add (1 2 3) (2 3 4 5) (2 4 6 8))
      1)
(test add-123+2345=2469
      (dec/add (1 2 3) (2 3 4 5) (2 4 6 9))
      0)
