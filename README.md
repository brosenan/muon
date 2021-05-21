# μVM Specifications

The μVM is a virtual machine for evaluating the pure-logic programming language **Muon**. It is inspired by the Warren Abstract Machine (WAM), with the following differences:



1. The underlying term structure is based on s-expressions rather than on functions (compound terms).
2. It supports dynamic scheduling, allowing the evaluation of built-in predicates and predicates with a large number of clauses to be delayed until their arguments are sufficiently instantiated.


## μVM Overview

The μVM is a **virtual machine** based on the notion of a **stack machine** featuring a **time machine**.

A μVM program consists of a sequence of **μCode instructions** which affect a **stack**. The stack is made of indexes pointing to objects in the **heap**.

To support non-determinism and backtracking, the state of the μVM can be rolled-back to a previous state known as a **choice-point**. Many of the data structures used by μVM are used to implement these rollbacks.


## μVM Data Structures

In this section we specify the data structures used by μVM to store its state. To simplify the discussion, we divide it into two parts: **computational data structures**, used for performing computation and **rollback data structures** used for rollbacks.


### Computational Data Structures

These include the **term heap**, used for storing logic terms, **value heaps**, used for storing `int64`, `float64` and UTF-8 string values and the **stack**, which holds, at any given point in time, the goals that need to be satisfied.


#### Value Heaps

There are three value heaps:
1. The `int64` heap
2. the `float64` heap and
3. the string heap.

Each heap is represented as a variable-size array of the corresponding type.

Each value heap has a 28-bit address space and therefore the number of constants in each such heap should not exceed `2^28`.

Allocation of a new value on one of these heaps is done by appending an element to the end of the heap and returning its index. For example, the following C++ function performs allocation on the `int64` heap represented as `std::vector<int64_t>`:

```c++
std::vector<int64_t> int64_heap;

size_t allocate_term(int64_t value) {
  int64_heap.push_back(value);
  if (int64_heap.size() > 0x0FFFFFFF) {
    // Report error: maximum number of int64 values exceeded.
  }
  return int64_heap.size() - 1;
}
```

#### Term Heap

The **term heap** (or just “heap” for short) consists of a variable-size array of (signed) `int32` values.

Allocation of new values on the heap is done by adding a value to top of the array and returning its address. For example, the folling C++ code allocates a new value in a heap represented as `std::vector<int32_t>`:

```c++
std::vector<int32_t> term_heap;

size_t allocate_term(int32_t value) {
  term_heap.push_back(value);
  return term_heap.size() - 1;
}
```

Each `int32` value in the term heap represents one of the following:
1. A **constants** value (represented as a reference to one of the value heaps).
2. A **symbol**, represented as a unique number (i.e., the textual representation of the symbol is not present in the representation, but rather only its identity).
3. A **pair**, pointing to two other cells in the heap.
4. A **hook**, used for dynamic scheduling.
5. A **variable**, a pointer to either itself or another object on the heap.

The distinction between the different object types that can be represented by a cell in the heap is made through its least-significant two or four bits. The least significant two bits provide the main division:
| 2LSB | Type(s)            |
|------|--------------------|
| 00   | Variable           |
| 01   | Constant or symbol |
| 10   | Pair               |
| 11   | Hook               |

For `2LSB=01`, the following two bits indicate whether this is a symbol or a literal, and if a literal, of which type:
| 4LSB | Type               |
|------|--------------------|
| 0001 | Symbol             |
| 0101 | `int64` constant   |
| 1001 | `float64` constant |
| 1101 | string constant    |

##### Variables

Variables have the following representation:
```
    --------------------------------
MSB|vvvvvvvvvvvvvvvvvvvvvvvvvvvvvv00|LSB
    --------------------------------
```
The `v`s represent a 30-bit **signed offset**. Please note that the value 0 represents a variable with offset 0, that is a variable that points to itself. This is called an *unbound* variable.

The following C++ code example shows how the index a variable at address `i` on the heap can be extracted:
```c++
int offset = term_heap[i] >> 2; // assuming arithmetic shift
int index = i + offset;
```

##### Symbols

Symbols have the following structure:
```
    --------------------------------
MSB|ssssssssssssssssssssssssssss0001|LSB
    --------------------------------
```
The `s`s are 28 bits specific to a symbol. For example, symbol `foo` will be represented by one string of 28 bits while symbol `bar` will be represented by another. There is no relation between the textual representation (`foo` and `bar`) and the bits representing them. However, within the scope of a single program, one (textual) symbol will always be represented by the same bit-string.

##### Constants

Constants can come in three different types: `int64`, `float64` and strings. Their representation is as follows:

```
    --------------------------------
MSB|iiiiiiiiiiiiiiiiiiiiiiiiiiiiTT01|LSB
    --------------------------------
```

Here, `TT` determines the type of constant and the `i`s represent an _unsigned_ index in the corresponding value heap. The following C++ code example shows how the type and offset can be determined based on the value in `term_heap[i]`:

```c++
int type = (term_heap[i] >> 2) && 3;
int index = (term_heap[i] >> 4) & 0x0FFFFFFF;
```

##### Pairs

A pair represents an ordered pair of objects in the heap. Its representation is as follows:
```
    --------------------------------
MSB|lllllllllllllllrrrrrrrrrrrrrrr10|LSB
    --------------------------------
```
Here, the `l`s and the `r`s represent _unsigned_ offsets to the left and right element of the pair, respectively. The offset is unsigned because the pair element is always expected to be with a higher index relative to its components. A value of 0 for either the `l` or the `r` bit-string represents the special value `nil`.

The following C++ code example shows how the left and right indexes are calculated for a pair at index `i`, and how we determine whether either is `nil`:

```c++
int left_offset = (term_heap[i] >> 17) & 0x7FFF;
int left_index = i - left_offset;
bool is_left_nil = (left_index == i);

int right_offset = (term_heap[i] >> 2) & 0x7FFF;
int right_index = i - right_offset;
bool is_right_nil = (right_index == i);
```
