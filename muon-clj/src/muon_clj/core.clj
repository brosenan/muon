(ns muon-clj.core
  (:gen-class)
  (:require [muon-clj.trie :as trie]))

(defn parse2 [expr]
  (cond
    (nil? expr) ()
    (int? expr) ['muon/int expr]
    (float? expr) ['muon/float expr]
    (string? expr) ['muon/string expr]
    (keyword? expr) [(name expr)]
    (and (sequential? expr)
         (seq expr)) (if (and (= (count expr) 3)
                              (= (nth expr 2) 'muon/...))
                       [(parse2 (first expr)) (parse2 (second expr))]
                       [(parse2 (first expr)) (parse2 (rest expr))])
    :else expr))

(defn parse [expr]
  (cond
    (nil? expr) [:empty-list]
    (int? expr) [:int expr]
    (float? expr) [:float expr]
    (string? expr) [:string expr]
    (symbol? expr) [:symbol (str expr)]
    (keyword? expr) [:var (-> expr str (subs 1))]
    (boolean? expr) [:symbol (if expr "true" "false")]
    (vector? expr) (cond
                     (and (= (count expr) 3)
                          (= (nth expr 2) 'muon/...)) [:pair (-> expr first parse) (-> expr second parse)]
                     (empty? expr) [:empty-vec]
                     :else [:pair (-> expr first parse) (-> expr rest vec parse)])
    (seq? expr) (cond
                  (and (= (count expr) 3)
                       (= (nth expr 2) 'muon/...)) [:pair (-> expr first parse) (-> expr second parse)]
                  (empty? expr) [:empty-list]
                  :else [:pair (-> expr first parse) (-> expr rest parse)])
    :else (throw (Exception. (str "Invalid Muon expression " expr)))))

(defn format-muon2 [ast]
  (if (vector? ast)
    (cond
      (= (count ast) 2) (let [tag (first ast)]
                          (cond
                            (or
                             (and (= tag 'muon/int)
                                  (int? (second ast)))
                             (and (= tag 'muon/float)
                                  (float? (second ast)))
                             (and (= tag 'muon/string)
                                  (string? (second ast)))) (second ast)
                            :else (let [head (format-muon2 (first ast))
                                        tail (format-muon2 (second ast))]
                                    (cond
                                      (seq? tail) (conj tail head)
                                      (vector? tail) (vec (concat [head] tail))
                                      :else (list head tail 'muon/...)))))
      (= (count ast) 1) (let [var (first ast)
                              name (if (int? var)
                                     (str "#" var)
                                     var)]
                          (keyword name))
      :else ast)
    ast))

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
                                 :else (list head tail 'muon/...)))
    :else (second ast)))

(defn alloc-vars2
  ([ast alloc]
   (-> (alloc-vars2 ast alloc {}) first))
  ([ast alloc varmap]
   (if (vector? ast)
     (cond
       (= (count ast) 2) (let [[head varmap] (alloc-vars2 (first ast) alloc varmap)
                               [tail varmap] (alloc-vars2 (second ast) alloc varmap)]
                           [[head tail] varmap])
       (= (count ast) 1) (if (varmap (first ast))
                           [[(varmap (first ast))] varmap]
                           (let [new-var (swap! alloc inc)]
                             [[new-var] (assoc varmap (first ast) new-var)]))
       :else [ast varmap])
     [ast varmap])))

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

(defn- variable? [ast]
  (and (vector? ast)
       (= (count ast) 1)))

(defn- pair? [ast]
  (and (vector? ast)
       (= (count ast) 2)))

(defn unify2 [a b bindings]
  (cond
    (nil? bindings) nil
    (variable? a) (if-let [a-val (bindings (first a))]
                    (recur a-val b bindings)
                    (assoc bindings (first a) b))
    (variable? b) (if-let [b-val (bindings (first b))]
                    (recur a b-val bindings)
                    (assoc bindings (first b) a))
    (pair? a) (if (pair? b)
                (let [[a-head a-tail] a
                      [b-head b-tail] b]
                  (->> bindings
                       (unify2 a-head b-head)
                       (unify2 a-tail b-tail)))
                nil)
    (= a b) bindings))

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

(defn subs-vars2 [term bindings]
  (cond
    (variable? term) (if-let [val (bindings (first term))]
                       (recur val bindings)
                       term)
    (pair? term) (let [[a b] term]
                   [(subs-vars2 a bindings) (subs-vars2 b bindings)])
    :else term))

(defn subs-vars [term bindings]
  (cond
    (and (-> term first (= :var))
         (bindings (second term))) (subs-vars (bindings (second term)) bindings)
    (-> term first (= :pair)) (let [[a b] (rest term)]
                                [:pair (subs-vars a bindings) (subs-vars b bindings)])
    :else term))

(defn normalize-statement2 [statement]
  (if-let [bindings (unify2 statement ['muon/<- [["head"] ["body"]]] {})]
    [(bindings "head") (bindings "body")]
    [statement ()]))

(defn normalize-statement [statement]
  (if-let [bindings (unify statement [:pair [:symbol "muon/<-"] [:pair [:var "head"] [:var "body"]]] {})]
    [(bindings "head") (bindings "body")]
    [statement [:empty-list]]))

(defn- term-key-with-stop [term]
  (cond
    (pair? term) (let [[a b] term]
                   (if (variable? a)
                     [:stop]
                     (let [prefix (term-key-with-stop a)]
                       (if (= (last prefix) :stop)
                         prefix
                         (concat prefix (term-key-with-stop b))))))
    :else [term]))

(defn term-key2 [term]
  (let [key (term-key-with-stop term)]
    (if (= (last key) :stop)
      (take (dec (count key)) key)
      key)))

(defn term-key
  ([term]
   (let [result (term-key [] term)]
     (if (map? result)
       (:stop result)
       result)))
  ([prefix term]
   (cond
     (map? prefix) prefix
     (-> term first (= :pair)) (let [[a b] (rest term)]
                                 (-> prefix
                                     (conj :pair)
                                     (term-key a)
                                     (term-key b)))
     (-> term first (= :empty-list)) (-> prefix
                                         (conj :empty-list))
     (-> term first (= :var)) {:stop prefix}
     :else (conj prefix (second term)))))

(defn load-program2 [program]
  (loop [db nil
         program program]
    (if (empty? program)
      db
      (let [statement (first program)
            statement (parse2 statement)
            [head body] (normalize-statement2 statement)
            key (term-key2 head)]
        (recur (trie/trie-update db key [head body]) (rest program))))))

(defn load-program [program]
  (loop [db nil
         program program]
    (if (empty? program)
      db
      (let [statement (first program)
            statement (parse statement)
            [head body] (normalize-statement statement)
            key (term-key head)]
        (recur (trie/trie-update db key [head body]) (rest program))))))

(defn ast-list-to-seq [ast-list]
  (cond
    (-> ast-list first (= :empty-list)) []
    (-> ast-list first (= :pair)) (concat [(-> ast-list (nth 1))] (-> ast-list (nth 2) ast-list-to-seq))))

(defn match-rules [goal bindings db alloc]
  (->> (subs-vars goal bindings)
       term-key
       (trie/trie-get db)
       (map (fn [[head body]] (alloc-vars [:pair head body] alloc)))
       (map (fn [[_pair head body]] [body (unify head goal bindings)]))
       (filter (fn [[_body bindings]] (not (nil? bindings))))
       (map (fn [[goals bindings]] [(ast-list-to-seq goals) bindings]))))

(defn eval-step [options db alloc]
  (let [[goal-list bindings] (first options)
        goal (first goal-list)]
    (concat (->> (match-rules goal bindings db alloc)
                 (map (fn [[goal-list1 bindings]] [(concat goal-list1 (rest goal-list)) bindings])))
            (rest options))))

(defn eval-states [options db alloc]
  (if (empty? options) nil
      (lazy-seq (cons (first options)
                      (eval-states (eval-step options db alloc) db alloc)))))

(defn eval-goals [goals db alloc]
  (->> (eval-states [[goals {}]] db alloc)
       (filter (fn [[goals _bindings]] (empty? goals)))
       (map second)))