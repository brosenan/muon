(ns muon-clj.core
  (:gen-class)
  (:require [muon-clj.trie :as trie]))

(defn parse [expr]
  (cond
    (nil? expr) ()
    (int? expr) ['muon/int expr]
    (float? expr) ['muon/float expr]
    (string? expr) ['muon/string expr]
    (keyword? expr) [(name expr)]
    (and (sequential? expr)
         (seq expr)) (if (and (= (count expr) 3)
                              (= (nth expr 2) 'muon/...))
                       [(parse (first expr)) (parse (second expr))]
                       [(parse (first expr)) (parse (rest expr))])
    :else expr))

(defn format-muon [ast]
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
                            :else (let [head (format-muon (first ast))
                                        tail (format-muon (second ast))]
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

(defn alloc-vars
  ([ast alloc]
   (-> (alloc-vars ast alloc {}) first))
  ([ast alloc varmap]
   (if (vector? ast)
     (cond
       (= (count ast) 2) (let [[head varmap] (alloc-vars (first ast) alloc varmap)
                               [tail varmap] (alloc-vars (second ast) alloc varmap)]
                           [[head tail] varmap])
       (= (count ast) 1) (if (varmap (first ast))
                           [[(varmap (first ast))] varmap]
                           (let [new-var (swap! alloc inc)]
                             [[new-var] (assoc varmap (first ast) new-var)]))
       :else [ast varmap])
     [ast varmap])))

(defn- variable? [ast]
  (and (vector? ast)
       (= (count ast) 1)))

(defn- pair? [ast]
  (and (vector? ast)
       (= (count ast) 2)))

(defn unify [a b bindings]
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
                       (unify a-head b-head)
                       (unify a-tail b-tail)))
                nil)
    (= a b) bindings))

(defn subs-vars [term bindings]
  (cond
    (variable? term) (if-let [val (bindings (first term))]
                       (recur val bindings)
                       term)
    (pair? term) (let [[a b] term]
                   [(subs-vars a bindings) (subs-vars b bindings)])
    :else term))

(defn normalize-statement [statement]
  (if-let [bindings (unify statement ['muon/<- [["head"] ["body"]]] {})]
    [(bindings "head") (bindings "body")]
    [statement ()]))

(defn- term-key-with-stop [term]
  (cond
    (variable? term) [:stop]
    (pair? term) (let [[a b] term
                       prefix (term-key-with-stop a)]
                   (if (= (last prefix) :stop)
                     prefix
                     (concat prefix (term-key-with-stop b))))
    :else [term]))

(defn term-key [term]
  (let [key (term-key-with-stop term)]
    (if (= (last key) :stop)
      (take (dec (count key)) key)
      key)))

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
    (empty? ast-list) []
    (pair? ast-list) (let [[a b] ast-list]
                       (concat [a] (ast-list-to-seq b)))) )

(defn match-rules [goal bindings db alloc]
  (->> (subs-vars goal bindings)
       term-key
       (trie/trie-get db)
       (map (fn [[head body]] (alloc-vars [head body] alloc)))
       (map (fn [[head body]] [body (unify head goal bindings)]))
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
