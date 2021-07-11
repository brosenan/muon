(ns muon-clj.qepl
  (:require [muon-clj.core :as core]))

(defn qepl [db state]
  (let [allocator (atom 0)]
    (loop [state state
           input [:empty-list]]
      (let [query [:pair [:symbol "muon/clj-step"]
                   [:pair state
                    [:pair input
                     [:pair [:var "next"]
                      [:empty-list]]]]]
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
          (if-let [result (core/unify [:var "next"]
                                      [:pair [:symbol "muon/return"] [:pair [:var "retval"] [:empty-list]]]
                                      result)]
            (-> [:var "retval"] (core/subs-vars result) core/format-muon)
            (if-let [result (core/unify [:var "next"]
                                        [:pair [:symbol "muon/continue"]
                                         [:pair [:var "expr"]
                                          [:pair [:var "state"] [:empty-list]]]]
                                        result)]
              (let [expr (-> [:var "expr"] (core/subs-vars result) core/format-muon)
                    value (eval expr)
                    parsed-value (core/parse value)
                    next-state (core/subs-vars [:var "state"] result)]
                (recur next-state parsed-value))
              (throw (Exception. (str "Invalid result from muon/clj-step: "
                                      (-> [:var "next"]
                                          (core/subs-vars (if (nil? result)
                                                            {}
                                                            result))
                                          core/format-muon prn-str)))))))))))
