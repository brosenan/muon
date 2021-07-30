(ns muon-clj.qepl
  (:require [muon-clj.core :as core]))

(defn qepl [db state]
  (let [allocator (atom 0)]
    (loop [state state
           input [:empty-list]]
      (let [query ['muon/clj-step [state [input [["next"] ()]]]]
            results (->> (core/eval-goals [query] db allocator)
                         (take 2)
                         vec)]
        (when (= (count results) 0)
          (throw (Exception. (str "No progression for state: "
                                  (-> state core/format-muon prn-str)))))
        (when (= (count results) 2)
          (throw (Exception. (str "Ambiguous progression for state: "
                                  (-> state core/format-muon prn-str)))))
        (let [result (first results)]
          (if-let [result (core/unify ["next"] ['muon/return [["retval"] ()]] result)]
            (-> ["retval"] (core/subs-vars result) core/format-muon)
            (if-let [result (core/unify ["next"] ['muon/continue [["expr"] [["state"] ()]]] result)]
              (let [expr (-> ["expr"] (core/subs-vars result) core/format-muon)
                    value (eval expr)
                    parsed-value (core/parse value)
                    next-state (core/subs-vars ["state"] result)]
                (recur next-state parsed-value))
              (throw (Exception. (str "Invalid result from muon/clj-step: "
                                      (-> ["next"]
                                          (core/subs-vars (if (nil? result)
                                                            {}
                                                            result))
                                          core/format-muon prn-str)))))))))))
