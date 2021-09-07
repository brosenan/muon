(ns expr.io
  (require expr e [defun defexpr >> do let with quote])
  (require native.io nio))

(defun println [str]
  (with [(let :str str)]
        (>> nio/println :str)))