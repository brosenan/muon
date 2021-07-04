```clojure
(ns muon-clj.trie-test
  (:require [midje.sweet :refer :all]
            [muon-clj.trie :refer :all]))

```
[Tries](https://en.wikipedia.org/wiki/Trie) are data structures that store payloads keyed by prefixes.
The Muon interpreter uses a trie to store its program database.
The reason is that the problem of efficiently searching for matching terms can be reduced to the problem
of efficiently finding lists with shared prefixes.
Consider the following problem. We have a large set of short sequences.
Given a new sequence, we would like to find all sequences in the set that either:
* Are a prefix of our sequences, or
* Our sequence is a prefix of.
This problem maps into logic terms. Every logic term can be "flattened" into a sequence of tokens.
For example, the term `(foo (bar 2) 3)` can be flattened into the sequence:
`[:pair "foo" :pair :pair "bar" :pair 2 :empty-list :pair 3 :empty-list]`.
Terms that contain variables are trimmed before the first variable.
For example, the term `(foo (bar :x) 3)` is flattened into:
`[:pair "foo" :pair :pair "bar"]`. This is because a variable can match anything, thus from that point
onward a matching term (sequence) can have any shape.
Therefore, by looking for prefixes of a sequence we are actually looking for terms that may have a common structure
up to a point, and have a variable in a place that can match other parts of our term, and vice versa.
Each node in the trie holds a pair consisting of:
* `values` - a set of values for which the key is the sequence up until that point, and
* `next` - a map from tokens (sequence elements) to nodes for longer sequences.
`nil` represents an empty trie.
`trie-update` takes a trie, a key (sequence) and a value and returns a trie containing that new value.
```clojure
(fact
 (trie-update nil [] "root") => [#{"root"} {}]
 (trie-update nil [1 2] "onetwo") => [#{} {1 [#{} {2 [#{"onetwo"} {}]}]}]
 (-> nil
     (trie-update ["foo" "bar"] "foobar")
     (trie-update ["bar"] "bar")
     (trie-update ["bar" "foo"] "barfoo")
     (trie-update ["bar" "bar"] "barbar")
     (trie-update ["foo" "foo"] "foofoo")
     (trie-update ["foo"] "foo")
     (trie-update ["bar" "foo"] "barfoo2")) =>
 [#{} {"foo" [#{"foo"} {"foo" [#{"foofoo"} {}]
                        "bar" [#{"foobar"} {}]}]
       "bar" [#{"bar"} {"foo" [#{"barfoo" "barfoo2"} {}]
                        "bar" [#{"barbar"} {}]}]}])

```
`all-values` traverses a given trie and returns all its underlying `values` in a single set.
```clojure
(fact
 (all-values nil) => #{}
 (let [trie (-> nil
                (trie-update [1 2] "onetwo")
                (trie-update [2 1] "twoone")
                (trie-update [2] "two")
                (trie-update [2 3] "twothree")
                (trie-update [] "root"))]
   (all-values trie) => #{"onetwo" "twoone" "two" "twothree" "root"}))

```
Given a trie and a key (sequence), `trie-get` returns a set of all values corresponding to keys that are either prefixes of the key,
or ones that the key is a prefix of them.
This is done by doing both:
* Returning all values stored in `values` sets encountered along the path, and
* Returning all the values in the sub-trie rooted at the end of the path.
```clojure
(fact
 (trie-get nil [1]) => #{}
 (let [trie (-> nil
                (trie-update [1 2] "onetwo")
                (trie-update [1] "one")
                (trie-update [2 1] "twoone")
                (trie-update [2] "two")
                (trie-update [1 3] "onethree")
                (trie-update [] "root"))]
   (trie-get trie [1 2]) => #{"root" "one" "onetwo"}
   (trie-get trie [1]) => #{"root" "one" "onetwo" "onethree"}
   (trie-get trie [1 2 4]) => #{"root" "one" "onetwo"}))
```

