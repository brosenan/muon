(:- (fib N F) (fib2 N 1 F))

(fib2 1 F F)
(:- (fib2 N F F2)
    (int-gt N 1 true)
    (int-mult F N F1)
    (int-plus N1 1 N)
    (fib2 N1 F1 F2))

;;;;

(:- (s F) F)
(s (/\ ))
(:- (s (/\ A B ...))
    (s A)
    (s (/\ B ...)))
(:- (s H)
    (:-- H B ...)
    (s (/\ B ...)))
