(ns clj-expr
  (require proc p [step]))

(<- (clj-step :state :input (continue :clj-expr :next-state))
    (step :state :input (continue :expr :next-state))
    (clj-expr :expr :clj-expr))

(<- (clj-expr (:name) (:clj-name))
    (clj-expr-name0 :name :clj-name))
(<- (clj-expr (:name :arg1) (:clj-name :arg1))
    (clj-expr-name1 :name :clj-name))
(<- (clj-expr (:name :arg1 :arg2) (:clj-name :arg1 :arg2))
    (clj-expr-name2 :name :clj-name))
(<- (clj-expr (:name :arg1 :arg2 :arg3) (:clj-name :arg1 :arg2 :arg3))
    (clj-expr-name3 :name :clj-name))
(<- (clj-expr (:name :args ...) (:clj-name :args ...))
    (clj-expr-name :name :clj-name))