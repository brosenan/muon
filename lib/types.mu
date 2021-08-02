(ns types
  (use muon mu))

(int? (mu/int :_n ...))

(float? (mu/float :_f ...))

(string? (mu/string :_s ...))

(bool? true)
(bool? false)

(list? ())
(<- (list? (:_x :xs ...))
    (list? :xs))

(vector? [])
(<- (vector? (:_x :xs ...))
    (vector? :xs))