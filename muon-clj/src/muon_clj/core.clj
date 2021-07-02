(ns muon-clj.core
  (:gen-class))

(defn parse [expr]
  (cond
    (int? expr) [:int expr]
    (float? expr) [:float expr]
    (string? expr) [:string expr]
    (symbol? expr) [:symbol (str expr)]
    (keyword? expr) [:var (-> expr str (subs 1))]
    (vector? expr) (cond
                     (and (= (count expr) 3)
                          (= (nth expr 2) '...)) [:pair (-> expr first parse) (-> expr second parse)]
                     (empty? expr) [:empty-vec]
                     :else [:pair (-> expr first parse) (-> expr rest vec parse)])
    (list? expr) (cond
                   (and (= (count expr) 3)
                        (= (nth expr 2) '...)) [:pair (-> expr first parse) (-> expr second parse)]
                   (empty? expr) [:empty-list]
                   :else [:pair (-> expr first parse) (-> expr rest parse)])
    :else (throw (Exception. (str "Invalid Muon expression " expr)))))

(defn format-muon [ast]
  (cond
    (-> ast first (= :symbol)) (symbol (second ast))
    (-> ast first (= :var)) (keyword (second ast))
    (-> ast first (= :empty-list)) '()
    (-> ast first (= :empty-vec)) []
    (-> ast first (= :pair)) (let [[a b] (rest ast)
                                   head (format-muon a)
                                   tail (format-muon b)]
                               (cond
                                 (vector? tail) (vec (concat [head] tail))
                                 (list? tail) (conj tail head)
                                 :else (list head tail '...)))
    :else (second ast)))