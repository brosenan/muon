(ns expr
  (use proc p [step])
  (require types ty)
  (require logic l [case =])
  (require lists li [concat])
  (require testing t))

;; bind
(<- (step (bind :var :bindings) :_input (return :value))
    (binding-lookup :bindings :var :value))

(binding-lookup [:var :value :_bindings ...] :var :value)
(<- (binding-lookup [:_var1 :_value1 :_bindings ...] :var :value)
    (binding-lookup :_bindings :var :value))

;; test-expr
(<- (t/test-model :name (bind :expr []) :value :model)
    (test-expr :name :expr :value :model))
(<- (t/test-model? :name (bind :expr []) :value :model)
    (test-expr? :name :expr :value :model))

;; quote
(step (bind (quote :x) :_bindings) :_input (return :x))

;; Literal self-evaluation
(<- (step (bind :x :_bindings) :_input (return :x))
    (value? :x))

(<- (value? :n)
    (ty/int? :n))
(<- (value? :f)
    (ty/float? :f))
(<- (value? :s)
    (ty/string? :s))
(<- (value? :b)
    (ty/bool? :b))

;; >>
(step (bind (>> :action ...) :bindings) :_input (continue :action (bind input :bindings)))
(step (bind input :_bindings) :input (return :input))

;; do
(step (bind (do) :_bindings) :input (return :input))
(<- (step (bind (do :first :rest ...) :bindings) :input :outcome)
    (step (bind :first :bindings) :input :first-outcome)
    (evolve-do :first-outcome :rest :bindings :outcome))
(<- (step (bind (do* :first :rest ...) :bindings) :input :outcome)
    (step :first :input :first-outcome)
    (evolve-do :first-outcome :rest :bindings :outcome))

(<- (evolve-do :first-outcome :rest :bindings :outcome)
 (case :first-outcome
   (continue :first-action :first-next) (= :outcome
                                           (continue :first-action (bind (do* :first-next :rest ...) :bindings)))
   (return :retval) (step (bind (do :rest ...) :bindings) :retval :outcome)))

;; let
(<- (step (bind (let [] :exprs ...) :bindings) :input :outcome)
    (step (bind (do :exprs ...) :bindings) :input :outcome))
(<- (step (bind (let [:var :expr :let-bindings ...] :body ...) :bindngs) :input :outcome)
    (step (bind :expr :bindngs) :input :expr-outcome)
    (evolve-let :expr-outcome :var :let-bindings :body :bindngs :outcome))
(<- (step (bind (let* [:var :expr :let-bindings ...] :body ...) :bindngs) :input :outcome)
    (step :expr :input :expr-outcome)
    (evolve-let :expr-outcome :var :let-bindings :body :bindngs :outcome))

(<- (evolve-let :expr-outcome :var :let-bindings :body :bindngs :outcome)
    (case :expr-outcome
      (return :value) (step (bind (let :let-bindings :body ...) [:var :value :bindngs ...]) () :outcome)
      (continue :action :next) (= :outcome (continue :action (bind (let* [:var :next :let-bindings ...] :body ...) :bindngs)))))

;; let-value
(<- (step (bind (let-value [] :exprs ...) :bindings) :input :outcome)
    (step (bind (do :exprs ...) :bindings) :input :outcome))
(<- (step (bind (let-value [:var :expr :let-bindings ...] :body ...) :bindngs) :input :outcome)
    (step (bind :expr :bindngs) :input :expr-outcome)
    (evolve-let-value :expr-outcome :var :let-bindings :body :bindngs :outcome))
(<- (step (bind (let-value* [:var :expr :let-bindings ...] :body ...) :bindngs) :input :outcome)
    (step :expr :input :expr-outcome)
    (evolve-let-value :expr-outcome :var :let-bindings :body :bindngs :outcome))

(<- (evolve-let-value :expr-outcome :var :let-bindings :body :bindngs :outcome)
    (case :expr-outcome
      (return :var) (step (bind (let-value :let-bindings :body ...) :bindngs) () :outcome)
      (continue :action :next) (= :outcome (continue :action (bind (let-value* [:var :next :let-bindings ...] :body ...) :bindngs)))))

;; defexpr
(<- (step (bind :expr :bindings) :input :outcome)
    (defexpr :expr :body)
    (step (bind :body :bindings) :input :outcome))

;; list
(defexpr (list)
  (quote ()))
(defexpr (list :arg :args ...)
  (let-value [:head :arg
              :tail (list :args ...)]
             (quote (:head :tail ...))))

;; bind-args
(bind-args [] () [])
(<- (bind-args [:param :params ...] (:arg :args ...) [:param :arg :bindings ...])
    (bind-args :params :args :bindings))

;; defun
(<- (defexpr (:f :args ...)
      (let :bindings :exprs ...))
    (defun :f :params :exprs ...)
    (bind-args :params :args :bindings))
(<- (step :f :_input (return :f))
    (defun :f :_params :_exprs ...))

;; if
(defexpr (if :cond :then :else)
  (let-value [:bool :cond]
    (select :bool :then :else)))

(defexpr (select true :then :_else)
  :then)
(defexpr (select false :_then :else)
  :else)

;; Calling quoted function names
(defexpr ((quote :f) :args ...)
  (:f :args ...))

;; partial and closure
(defexpr (partial :func :arg :args ...)
  (let [:arg-val :arg
        (quote (closure :_func1 :arg-vals ...)) (partial :func :args ...)]
    (quote (closure :func :arg-val :arg-vals ...))))
(defexpr (partial :func)
  (quote (closure :func)))
(<- (defexpr ((closure :f :closure-args ...) :args ...)
      (:f :all-args ...))
    (concat :closure-args :args :all-args))
