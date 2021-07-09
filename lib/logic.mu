(ns logic)

(= :a :a)

(&)
(<- (& :goal :goals ...)
    :goal
    (& :goals ...))

(<- (case :term
      :term :goal
      :others ...)
    :goal)
(<- (case :term
      :pattern :goal
      :others ...)
    (case :term
      :others ...))
