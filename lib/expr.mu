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

;; with
(<- (step (bind (with [] :expr) :bindings) :input :outcome)
    (step (bind :expr :bindings) :input :outcome))
(<- (step (bind (with [(let :var :let-expr) :clauses ...] :expr) :bindings) :input :outcome)
    (step (bind :let-expr :bindings) :input :expr-outcome)
    (case :expr-outcome
      (return :var) (step (bind (with :clauses :expr) :bindings) () :outcome)
      (continue :action :next) (= :outcome (continue :action
                                                     (bind
                                                      (with [(let :var (do* :next)) :clauses ...]
                                                            :expr)
                                                      :bindings)))))
(<- (step (bind (with [(where :goal) :clauses ...] :expr) :bindings) :input :outcome)
    :goal
    (step (bind (with :clauses :expr) :bindings) :input :outcome))

;; defexpr
(<- (step (bind :expr :bindings) :input :outcome)
    (defexpr :expr :body)
    (step (bind :body :bindings) :input :outcome))

;; list
(defexpr (list)
  (quote ()))
(defexpr (list :arg :args ...)
  (with [(let :head :arg)
         (let :tail (list :args ...))]
        (quote (:head :tail ...))))

;; bind-args
(<- (bind-args :params :args :bindings)
    (bind-args :params :args [] :bindings))

(bind-args [] () :end :end)
(<- (bind-args [:param :params ...] (:arg :args ...) :end [:param :arg :bindings ...])
    (bind-args :params :args :end :bindings))

;; defun
(<- (defexpr :f
      (lambda :params (do :exprs ...)))
    (defun :f :params :exprs ...))

;; if
(defexpr (if :cond :then :else)
  (with [(let :bool :cond)]
        (select :bool :then :else)))

(defexpr (select true :then :_else)
  :then)
(defexpr (select false :_then :else)
  :else)

;; lambda
(step (bind (lambda :params :expr) :bindings) :_input
      (return (closure :params :expr :bindings)))

(<- (step (bind (:f :args ...) :call-bindings) :input :outcome)
    (step (bind :f :call-bindings) :input (return (closure :params :expr :closure-bindings)))
    (step (bind
           (with [(let :arg-vals (list :args ...))
                  (where (bind-args :params :arg-vals :closure-bindings :func-bindings))]
                 (do* (bind :expr :func-bindings))) :call-bindings) :_input :outcome))
