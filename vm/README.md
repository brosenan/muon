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

## Basic Operations

* [Variable operations](variable-operations.md).

## μCode

μCode (pronounced "mu-code", not "micro code") is the instruction-set used by μVM. It is a 32-bit fixed-length instruction set.

μCode instructions can be classified into two classes:

* **Class A instructions**, which contain a 24-bit operand (255 possible opcodes), and
* **class B instructions**, which do not take operands (2^24 possible opcodes).

Below is the general scheme of these classes, with `o`s representing the opcode bits and `x` representing operand bits.

```
Class A:
   +---------------------------------------+
MSB|xxxx xxxx xxxx xxxx xxxx xxxx oooo oooo|LSB
   +---------------------------------------+

Class A:
   +---------------------------------------+
MSB|oooo oooo oooo oooo oooo oooo 1111 1111|LSB
   +---------------------------------------+

```

Each μCode instruction can either succeed or fail. In the code examples we provide here we represent each instruction as a Boolean function.

μCode instructions can be classified into the following functional groups:

* [Construction instructions](mucode-construction.md)
* [Destruction instructions](mucode-destruction.md)
* [Choice point instructions](mucode-choicepoint.md)
* [Control instructions](mucode-control.md)

The following table lists all class A instructions and their opcodes.

| Instruction      | Opcode    |
|------------------|-----------|
| C_SYMBOL         | 0x01      |
| C_VAR            | 0x02      |
| C_INT64          | 0x05      |
| C_FLOAT64        | 0x09      |
| C_STRING         | 0x0d      |
| D_SYMBOL         | 0x11      |
| D_VAR            | 0x12      |
| D_INT64          | 0x15      |
| D_FLOAT64        | 0x19      |
| D_STRING         | 0x1d      |

The following table lists all class B instructions and their opcodes.
| Instruction      | Opcode    |
|------------------|-----------|
| C_NIL            | 0x000000  |
| C_PAIR           | 0x000001  |
| D_NIL            | 0x000002  |
| D_PAIR           | 0x000003  |
