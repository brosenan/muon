(ns expr
  (use proc p [step])
  (require types ty))

(step (quote :x) :_input (return :x))
(<- (step :n :_input (return :n))
    (ty/int? :n))
(<- (step :f :_input (return :f))
    (ty/float? :f))
(<- (step :s :_input (return :s))
    (ty/string? :s))
(<- (step :b :_input (return :b))
    (ty/bool? :b))

(step (>> :action ...) :_input (continue :action input))
(step input :input (return :input))