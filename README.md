# μVM Specifications

The μVM is a virtual machine for evaluating the pure-logic programming language **Muon**. It is inspired by the Warren Abstract Machine (WAM), with the following differences:



1. The underlying term structure is based on s-expressions rather than on functions (compound terms).
2. It supports dynamic scheduling, allowing the evaluation of built-in predicates and predicates with a large number of clauses to be delayed until their arguments are sufficiently instantiated.


## μVM Overview

The μVM is a **virtual machine** based on the notion of a **stack machine** featuring a **time machine**.

A μVM program consists of a sequence of **μCode instructions** which affect a **stack**. The stack is made of indexes pointing to objects in the **heap**.

To support non-determinism and backtracking, the state of the μVM can be rolled-back to a previous state known as a **choice-point**. Many of the data structures used by μVM are used to implement these rollbacks.


## μVM Data Structures

In this section we specify the data structures used by μVM to store its state. To simplify the discussion, we divide it into three parts: [restorable data structures](restorable-data-structures.md), which are tracked by the [rollback data structures](rollback-data-structures.md) to allow rolling their state back, and [non-restorable data structures](non-restorable-data-structures.md), which are short-lived, volatile data structures.

## Functionality

The basic functionality of the μVM consists of [variable operations](varialbe-operations.md).

