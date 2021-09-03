(ns expr.io
  (require expr e [defun defexpr >> do let let-value quote])
  (require native.io nio))

(defun println [str]
  (let-value [:str str]
             (>> nio/println :str)))