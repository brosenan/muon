(ns testing)

(<- (test :name :goal 1)
    (test-value :name :goal :expected :expected))
(<- (test :name :goal 0)
    (test-value :name :goal not-a-value :expected))
