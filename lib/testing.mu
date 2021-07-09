(ns testing
  (require proc p)
  (require logic l [case & =]))

(<- (test :name :goal 1)
    (test-value :name :goal :expected :expected))
(<- (test :name :goal 0)
    (test-value :name :goal not-a-value :expected))
(<- (test :name :goal 1)
    (test-success :name :goal))
(<- (test :name :goal 0)
    (test-failure :name :goal))

(<- (qepl-sim :state :input :model)
    (p/step :state :input :next)
    (case :next
      (continue :expr :next-state) (& (handle-expr :model :expr :result :next-model)
                                      (qepl-sim :next-state :result :next-model))
      (done) (final? :model)))

(handle-expr (sequential :expr :result :others ...) :expr :result (sequential :others ...))
(final? (sequential))
