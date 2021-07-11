(ns proc
  (require logic l [= & case]))

(step (do) :input (return :input))
(step (do :c :cs ...) :_input (continue :c (do :cs ...)))
(<- (step (do :first :rest ...) :input :outcome)
    (step :first :input :first-outcome)
    (case :first-outcome
      (return :retval) (step (do :rest ...) :retval :outcome)
      (continue :expr :next-first) (= :outcome (continue :expr (do :next-first :rest ...)))))

(<- (step (let [] :exprs ...) :input :outcome)
    (step (do :exprs ...) :input :outcome))
(step (let [:var :expr :bindings ...] :exprs ...) :_input 
      (continue :expr (bind :var (let :bindings :exprs ...))))
(<- (step (bind :input :proc) :input :outcome)
    (step :proc :_input1 :outcome))
(<- (step :proc :_input :outcome)
    (defproc :proc :commands ...)
    (step (do :commands ...) :_input :outcome))