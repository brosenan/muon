(ns muon-clj.modules
  (:require [clojure.edn :as edn]
            [clojure.walk :as walk]
            [clojure.string :as str]
            [clojure.java.io :as io]))

(defn convert-ns [expr ns-map refer-map]
  (walk/postwalk (fn [expr] (if (symbol? expr)
                              (let [orig-ns (namespace expr)
                                    new-ns (if (and (empty? orig-ns)
                                                    (refer-map (name expr)))
                                             (refer-map (name expr))
                                             (ns-map orig-ns))]
                                (symbol new-ns (name expr)))
                              expr)) expr))


(defn module-paths [module-name muon-path]
  (let [rel-path (str/split module-name #"[.]")
        depth (-> rel-path count dec)
        rel-path (update rel-path depth #(str % ".mu"))]
    (for [path muon-path]
      (apply io/file path rel-path))))

;; Reads a module to a string.
(defn read-module [module-name muon-path]
  (let [paths (module-paths module-name muon-path)
        existing (->> paths .exists)]
    (if (empty? existing)
      (throw (Exception. (str "Cannot find module " module-name " in paths " muon-path)))
      (-> existing first slurp))))
