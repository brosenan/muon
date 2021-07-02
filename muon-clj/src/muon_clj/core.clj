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
    (-> ast first (= :var)) (let [var (second ast)
                                  var (if (int? var) (str "#" var) var)]
                              (keyword var))
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

(defn alloc-vars
  ([ast alloc]
   (-> (alloc-vars ast alloc {}) first))
  ([ast alloc varmap]
   (cond
     (-> ast first (= :var)) (let [var-str (second ast)
                                   var-int (varmap var-str)]
                               (if (nil? var-int)
                                 (let [var-int (swap! alloc inc)]
                                   [[:var var-int] (assoc varmap var-str var-int)])
                                 [[:var var-int] varmap]))
     (-> ast first (= :pair)) (let [[a b] (rest ast)
                                    [a varmap] (alloc-vars a alloc varmap)
                                    [b varmap] (alloc-vars b alloc varmap)]
                                [[:pair a b] varmap])
     :else [ast varmap])))