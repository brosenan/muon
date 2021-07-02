(ns muon-clj.core
  (:gen-class))

(defn parse [expr]
  (cond
    (int? expr) [:int expr]
    (float? expr) [:float expr]
    (string? expr) [:string expr]
    (symbol? expr) [:symbol (name expr)]
    (keyword? expr) [:var (-> expr str (subs 1))]
    (vector? expr) (cond
                     (and (= (count expr) 3)
                          (= (nth expr 2) '...)) [:pair (-> expr first parse) (-> expr second parse)]
                     (empty? expr) [:empty-vec]
                     :else [:pair (-> expr first parse) (-> expr rest vec parse)])
    (seq? expr) (cond
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

(defn unify [a b bindings]
  (cond
    (nil? bindings) nil
    (-> a first (= :var)) (if-let [a-val (bindings (second a))]
                            (recur a-val b bindings)
                            (assoc bindings (second a) b))
    (-> b first (= :var)) (if-let [b-val (bindings (second b))]
                            (recur a b-val bindings)
                            (assoc bindings (second b) a))
    (-> a first (= :pair)) (if (-> b first (= :pair))
                             (let [[a1 a2] (rest a)
                                   [b1 b2] (rest b)]
                               (->> bindings (unify a1 b1) (recur a2 b2)))
                             nil)
    (= a b) bindings))

(defn normalize-statement [statement]
  (if-let [bindings (unify statement [:pair [:symbol "<-"] [:pair [:var "head"] [:var "body"]]] {})]
    [(bindings "head") (bindings "body")]
    [statement [:empty-list]]))

(defn term-key [term]
  (cond
    (-> term first (= :symbol)) [(second term)]
    (-> term first (= :pair)) (let [key-pref (term-key (second term))]
                                (if (empty? key-pref)
                                  []
                                  (concat key-pref (-> term (nth 2) term-key))))
    :else []))

(defn all-prefixes [list]
  (if (empty? list)
    []
    (concat (-> list count dec (take list) all-prefixes) [list])))

(defn load-program [program]
  (->> program
       (map parse)
       (map normalize-statement)
       (map (fn [[head body]] [(term-key head) [head body]]))
       (mapcat (fn [[key statement]] (for [subkey (all-prefixes key)]
                                       [subkey statement])))
       (group-by first)
       (map (fn [[key value]] [key (->> value (map second))]))
       (into {})))
