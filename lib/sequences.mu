(ns sequences
  (require proc p [defun ']))

(defun empty? [()]
  (' true))
(defun empty? [[]]
  (' true))
(defun empty? [(:first :rest ...)]
  (' false))

(defun first [(:first :_rest ...)]
  (' :first))

(defun rest [(:_first :rest ...)]
  (' :rest))

