(ns testing
  (require proc p)
  (require logic l [case & =])
  (require decimals d))

(<- (test :name :goal 1)
    (test-value :name :goal :expected :expected))
(<- (test :name :goal 0)
    (test-value :name :goal not-a-value :expected))
(<- (test :name :goal 1)
    (test-value :name :goal :_expected :expected))

(<- (test :name :goal 0)
    (test-value? :name :goal :_expected :expected))

(<- (test :name :goal 1)
    (test-success :name :goal))
(<- (test :name :goal 0)
    (test-failure :name :goal))

(<- (qepl-sim :state :input :output :model)
    (qepl-trace :state :model :input (return :output)))

(<- (qepl-trace :state :model :input :outcome)
    (p/step :state :input :next)
    (is-final :model :final?)
    (case :final?
      true (= :outcome :next)
      false (case :next
              (continue :action :next-state) (& (act :model :action :result :next-model)
                                                (qepl-trace :next-state :next-model :result :outcome))
              (return :output) (= :outcome (unhandled-action :action)))))


(act (sequential :expr :result :others ...) :expr :result (sequential :others ...))
(is-final (sequential) true)
(is-final (sequential :action :result :others ...) false)

(<- (test-value :name (qepl-sim :pexpr () :output :model) :output :expected)
    (test-model :name :pexpr :expected :model))

(<- (test :name (qepl-trace :state :model () :_outcome) 0)
    (test-model? :name :state :expected :model))

(is-final pure true)

(<- (act (by-def :n) :action :result (by-def :n-1))
    (defaction :action :result)
    (d/dec :n :n-1))
(<- (is-final (by-def :n) :final?)
    (d/is-zero :n :final?))

(<- (act (| :model :models ...) :action :result (| :sub-next :models ...))
    (act :model :action :result :sub-next))
(<- (act (| :model :models ...) :action :result (| :model :sub-next ...))
    (act (| :models ...) :action :result (| :sub-next ...)))
(<- (is-final (| :model :models ...) :final?)
    (is-final :model :subfinal?)
    (case :subfinal?
      true (is-final (| :models ...) :final?)
      false (= :final? false)))
(is-final (|) true)