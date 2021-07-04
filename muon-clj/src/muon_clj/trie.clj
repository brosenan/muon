(ns muon-clj.trie
  (:require [clojure.set :as set]))

(declare trie-update)

(defn- trie-update* [[values next] key value]
  (if (empty? key)
    [(conj values value) next]
    [values (update next (first key) #(trie-update % (rest key) value))]))

(def trie-update (fnil trie-update* [#{} {}]))

(defn all-values [trie]
  (if (nil? trie)
    #{}
    (let [[values next] trie]
      (set/union values (->> next
                             (map second)
                             (map all-values)
                             (reduce set/union))))))

(defn trie-get [trie key]
  (if (nil? trie)
    #{}
    (if (empty? key)
      (all-values trie)
      (let [[values next] trie]
        (-> (first key)
            next
            (trie-get (rest key))
            (set/union values))))))