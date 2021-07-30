(ns muon-clj.testing
  (:require [muon-clj.core :as core]
            [clojure.string :as str]))

(def allocator (atom 0))

(defn get-tests [db]
  (->> (core/eval-goals [['muon/test [["id"] [["goal"] [["num-results"] ()]]]]] db allocator)
       (map (fn [result] (->> ["id" "goal" "num-results"]
                              (map (fn [key] [(keyword key) (core/subs-vars [key] result)]))
                              (into {}))))
       (map #(update % :num-results second))))

(defn run-test [db test]
  (let [results (->> (core/eval-goals [(:goal test)] db allocator)
                     (map #(core/subs-vars (:goal test) %))
                     (map core/format-muon)
                     set)]
    {:id (:id test)
     :expected-num-results (:num-results test)
     :results results
     :success (= (count results) (:num-results test))}))

(defn- color [code]
  (str "\u001b[" code "m"))

(def GREEN 32)
(def RED 31)
(def RESET 0)

(defn format-results [results]
  (let [failures (->> results (filter #(not (:success %))))]
    (str (->> failures
              (map (fn [failure]
                     (str (color RED)
                          (:id failure)
                          (color RESET)
                          ": Expected " (:expected-num-results failure) " result(s), got "
                          (count (:results failure)) ":\n"
                          (->> (:results failure)
                               (map #(str "* " (prn-str %)))
                               str/join))))
              (str/join "\n"))
     (if (-> failures count (> 0))
       (str (color RED)
            "Failure:"
            (color RESET)
            " " (count failures) " test(s) failed (" (- (count results) (count failures))" passed).")
       (str (color GREEN)
         "Success:"
         (color RESET)
         " " (count results) " test(s) passed.")))))

(defn run-tests [db]
  (let [results (->> db
                     get-tests
                     (map #(run-test db %)))]
    [(every? :success results)
     (format-results results)]))