(ns muon-clj.main
  (:gen-class)
  (:require [clojure.tools.cli :refer [parse-opts]]
            [clojure.edn :as edn]
            [clojure.string :as str]
            [muon-clj.core :as core]
            [muon-clj.modules :as modules]
            [muon-clj.testing :as testing]
            [clojure.core.async :as async]
            [hawk.core :as hawk]))

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
  ["-T" "--test" "Runs unit tests defined in the selected module and all its dependencies"]
  ["-a" "--autotest" "Execute iteratively every time one of the dependent modules change"]
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

(defn- trace [options db]
  (->> (core/eval-states [[[(-> options :goal core/parse)] {}]] db (atom 0))
       (map (fn [[goals bindings]]
              (str (if (empty? goals)
                     "****"
                     (if (-> options :trace (>= 3))
                       (str "\n > "
                            (->> goals
                                 (map #(core/subs-vars % bindings))
                                 (map core/format-muon)
                                 (str/join "\n > ")))
                       (str (->> (for [_goal goals] " ") str/join)
                            "> "
                            (-> goals
                                first
                                (core/subs-vars bindings)
                                core/format-muon))))
                   (if (-> options :trace (>= 2))
                     (str "\n"
                          (->> (for [[var val] bindings]
                                 (str var " = " (-> val
                                                    (core/subs-vars bindings)
                                                    core/format-muon)))
                               (str/join "\n")))
                     ""))))
       (str/join "\n")
       println))

(defn- wait-for-change [modules muon-path]
  (let [files-to-watch (for [module modules
                             file (modules/module-paths module muon-path)]
                         (.toString file))
        chan (async/chan)]
    (hawk/watch! [{:paths files-to-watch
                   :handler (fn [_ e] (async/>!! chan e))}])
    (async/<!! chan)))

(defn -main [& args]
  (let [status (atom 0)
        {options :options
         arguments :arguments
         summary :summary} (parse-opts args cli-options)]
    (when (:help options)
      (println summary)
      (System/exit 0))
    (loop []
      (let [muon-path (concat ["."] (:muon-path options))
            main-module (if (= (count arguments) 1)
                          (first arguments)
                          (throw (Exception. (str "Exactly one positional argument is required (the main module name). "
                                                  (count (:arguments options)) " are given."))))
            [statements modules] (modules/load-with-dependencies main-module muon-path)
            db (core/load-program statements)]
        (when (:dump-statements options)
          (->> statements (str/join "\n") println))
        (when (:dump-database options)
          (prn db))
        (when (:test options)
          (let [[success output] (testing/run-tests db)]
            (println output)
            (when (not success)
              (reset! status 1))))
        (when (:goal options)
          (when (-> options :trace (>= 1))
            (trace options db))
          (-> [(-> options :goal core/parse)]
              (core/eval-goals db (atom 0))
              results-string
              println))
        (when (:autotest options)
          (wait-for-change modules (:muon-path options))
          (recur))))
          (System/exit @status)))

