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

(defproc (let [] :pexprs ...) (do :pexprs ...))
(<- (step (let [:var :pexpr :bindings ...] :pexprs ...) :input :outcome)
    (step :pexpr :input :suboutcome)
    (case :suboutcome
      (return :var) (step (let :bindings :pexprs ...) :input :outcome)
      (continue :nexpr :subnext) (= :outcome (continue :nexpr (let [:var :subnext :bindings ...] :pexprs ...)))))

(<- (step :proc :input :outcome)
    (defproc :proc :body ...)
    (case :body
      () (step input :input :outcome)
      (:pexpr) (step :pexpr :input :outcome)
      (:pexpr :pexprs ...) (step (do :pexpr :pexprs ...) :input :outcome)))
