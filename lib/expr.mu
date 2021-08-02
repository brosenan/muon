(ns expr
  (use proc p [step])
  (require types ty)
  (require logic l [case =]))

;; quote
(step (quote :x) :_input (return :x))

;; Literal self-evaluation
(<- (step :n :_input (return :n))
    (ty/int? :n))
(<- (step :f :_input (return :f))
    (ty/float? :f))
(<- (step :s :_input (return :s))
    (ty/string? :s))
(<- (step :b :_input (return :b))
    (ty/bool? :b))

;; >>
(step (>> :action ...) :_input (continue :action input))
(step input :input (return :input))

;; do
(step (do) :input (return :input))
(<- (step (do :first :rest ...) :input :outcome)
    (step :first :input :first-outcome)
    (case :first-outcome
      (continue :first-action :first-next) (= :outcome 
                                              (continue :first-action (do :first-next :rest ...)))
      (return :retval) (step (do :rest ...) :retval :outcome)))

;; let
(<- (step (let [] :exprs ...) :input :outcome)
    (step (do :exprs ...) :input :outcome))
(<- (step (let [(quote :value) :expr :bindings ...] :body ...) :input :outcome)
    (step :expr :input :expr-outcome)
    (case :expr-outcome
      (return :value) (step (let :bindings :body ...) () :outcome)
      (continue :action :next) (= :outcome (continue :action (let [(quote :value) :next :bindings ...] :body ...)))))