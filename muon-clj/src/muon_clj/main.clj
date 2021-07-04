(ns muon-clj.main
  (:require [clojure.tools.cli :refer [parse-opts]]
            [clojure.edn :as edn]
            [clojure.string :as str]
            [muon-clj.core :as core]
            [muon-clj.modules :as modules]))

(def cli-options
 [["-p" "--muon-path PATH" "Muon Path"
   :default []
   :multi true
   :update-fn conj]
  ["-g" "--goal GOAL" "Goal to evaluate"
   :parse-fn edn/read-string]
  ["-d" "--dump-statements" "Prints the loaded statements to the console"]
  ["-D" "--dump-database" "Prints the database"]
  ["-t" "--trace" "Prints the intermediate goals being evaluated"
   :default 0
   :update-fn inc]
  ["-h" "--help" "Show help"]])

(defn- results-string [results]
  (if (empty? results)
    "No results."
    (->> (for [bindings results]
           (str/join "\n" (for [[var value] bindings
                                :when (string? var)]
                            (str var ": " (-> value
                                              (core/subs-vars bindings)
                                              core/format-muon)))))
         (str/join "\n----\n"))))

(defn -main [& args]
  (let [{options :options
         arguments :arguments
         summary :summary} (parse-opts args cli-options)]
    (when (:help options)
      (println summary)
      (System/exit 0))
    (let [muon-path (concat ["."] (:muon-path options))
          main-module (if (= (count arguments) 1)
                        (first arguments)
                        (throw (Exception. (str "Exactly one positional argument is required (the main module name). "
                                                (count (:arguments options)) " are given."))))
          statements (modules/load-with-dependencies main-module muon-path)
          db (core/load-program statements)]
      (when (:dump-statements options)
        (->> statements (str/join "\n") println))
      (when (:dump-database options)
        (prn db))
      (when (-> options :trace (>= 1))
        (->> (core/eval-states [[[(-> options :goal core/parse)] {}]] db (atom 0))
             (map (fn [[goals bindings]]
                    (if (empty? goals)
                      "****"
                      (str (->> (for [_goal goals] " ") str/join)
                           "> "
                           (if (-> options :trace (>= 2))
                             (prn-str [(first goals) bindings])
                             (-> goals
                                 first
                                 (core/subs-vars bindings)
                                 core/format-muon))))))
             (str/join "\n")
             println))
      (-> [(-> options :goal core/parse)]
          (core/eval-goals db (atom 0))
          results-string
          println))))
