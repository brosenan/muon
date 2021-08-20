(ns expr.io
  (require expr e [defun defexpr >> do let quote])
  (require native.io nio))

(defun println [(quote :str)]
  (>> nio/println :str))