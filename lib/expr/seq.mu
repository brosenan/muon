(ns expr.seq
  (require expr ex [defexpr defun lambda do let with where if quote list]))

(<- (defexpr (:name :args ...)
      (with [(let :arg-vals (list :args ...))]
            (quote (:name :arg-vals ...))))
    (defseq :name :params
      :_empty
      :_first
      :_rest))

(defun empty? [seq]
  (with [(let (:name :args ...) seq)
         (where (defseq :name :params :empty :_first :_rest))
         (where (ex/bind-args :params :args :bindings))]
        (ex/do* (ex/bind :empty :bindings))))

(defun first [seq]
  (with [(let (:name :args ...) seq)
         (where (defseq :name :params :_empty :first :_rest))
         (where (ex/bind-args :params :args :bindings))]
        (ex/do* (ex/bind :first :bindings))))

(defun rest [seq]
  (with [(let (:name :args ...) seq)
         (where (defseq :name :params :_empty :_first :rest))
         (where (ex/bind-args :params :args :bindings))]
        (ex/do* (ex/bind :rest :bindings))))

;; seq
(defseq seq [l]
  (with [(let :l l)
         (where (is-empty? :l :is-empty))]
        :is-empty)
  (with [(let (:x :_xs ...) l)]
        (quote :x))
  (with [(let (:_x :xs ...) l)]
        (seq (quote :xs))))

(is-empty? () true)
(is-empty? [] true)
(is-empty? (:_x :_xs ...) false)

;; Materialization
(defun to-list [s]
  (if (empty? s)
    (quote ())
    (with [(let :x (first s))
           (let :xs (to-list (rest s)))]
          (quote (:x :xs ...)))))