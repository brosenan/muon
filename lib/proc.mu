(ns proc
  (require logic l [= & case]))

(step (const :value) :_input (return :value))
(step input :input (return :input))
(step :nexpr :_input (continue :nexpr input))

(step (do) :input (return :input))
(<- (step (do :first :rest ...) :input :outcome)
    (step :first :input :first-outcome)
    (case :first-outcome
      (return :retval) (step (do :rest ...) :retval :outcome)
      (continue :expr :next-first) (= :outcome (continue :expr (do :next-first :rest ...)))))

(<- (step (let [] :pexprs ...) :input :outcome)
    (step (do :pexprs ...) :input :outcome))
(<- (step (let [:var :pexpr :bindings ...] :pexprs ...) :_input1 :outcome)
    (step :pexpr :_input2 :suboutcome)
    (case :suboutcome
      (return :var) (step (let :bindings :pexprs ...) :_input3 :outcome)
      (continue :nexpr :subnext) (= :outcome (continue :nexpr (let [:var :subnext :bindings ...] :pexprs ...)))))
(<- (step :proc :input :outcome)
    (defproc :proc :commands ...)
    (step (do :commands ...) :input :outcome))