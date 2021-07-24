(ns proc
  (require logic l [= & case])
  (require lists ls [concat]))

(step (' :value) :_input (return :value))
(step input :input (return :input))
(step (>> :nexpr ...) :_input (continue :nexpr input))

(step (do) :input (return :input))
(<- (step (do :first :rest ...) :input :outcome)
    (step :first :input :first-outcome)
    (case :first-outcome
      (return :retval) (step (do :rest ...) :retval :outcome)
      (continue :expr :next-first) (= :outcome (continue :expr (do :next-first :rest ...)))))

(defproc (list :pexprs ...)
  (list-cat :pexprs ()))

(step (list-cat () :vals) :_input (return :vals))
(<- (step (list-cat (:pexpr :pexprs ...) :vals) :input :outcome)
    (step :pexpr :input :suboutcome)
    (case :suboutcome
      (return :val) (& (concat :vals (:val) :new-vals)
                       (step (list-cat :pexprs :new-vals) :input :outcome))
      (continue :nexpr :next) (= :outcome (continue :nexpr (list-cat (:next :pexprs ...) :vals)))))

(comment  )

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
      (:pexpr1 :pexpr2 :pexprs ...) (step (do :pexpr1 :pexpr2 :pexprs ...) :input :outcome)))

(bind-args [] () [])
(<- (bind-args [:param :params ...] (:arg :args ...) [:param :arg :bindings ...])
    (bind-args :params :args :bindings))
(bind-args (var [] :others) :args [:others (' :args)])
(<- (bind-args (var [:param :params ...] :others) (:arg :args ...) [:param :arg :bindings ...])
    (bind-args (var :params :others) :args :bindings))

(<- (defproc (:name :args ...) (let :bindings :body ...))
    (defun :name :params :body ...)
    (bind-args :params :args :bindings))