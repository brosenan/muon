# Restorable Data Structures

These include the **term heap**, used for storing logic terms, **value heaps**, used for storing `int64`, `float64` and UTF-8 string values and the **stack**, which holds, at any given point in time, the goals that need to be satisfied.


## Value Heaps

There are three value heaps:
1. The `int64` heap
2. the `float64` heap and
3. the string heap.

Each heap is represented as a variable-size array of the corresponding type.

Each value heap has a 28-bit address space and therefore the number of constants in each such heap should not exceed `2^28`.

Allocation of a new value on one of these heaps is done by appending an element to the end of the heap and returning its index. For example, the following C++ function performs allocation on the `int64` heap represented as `std::vector<int64_t>`:

```c++
std::vector<int64_t> int64_heap;

size_t allocate_int64(int64_t value) {
  int64_heap.push_back(value);
  if (int64_heap.size() > 0x10000000) {
    // Report error: maximum number of int64 values exceeded.
  }
  return int64_heap.size() - 1;
}
```

## Term Heap

The **term heap** (or just “heap”) consists of a variable-size array of (signed) `int32` values.

The size of the term heap is limited to `2^29` elements to allow variables, using 30-bit signed offsets to address any object in the heap.

Allocation of new values on the heap is done by adding a value to top of the array and returning its address. For example, the folling C++ code allocates a new value in a heap represented as `std::vector<int32_t>`:

```c++
std::vector<int32_t> term_heap;

size_t allocate_term(int32_t value) {
  term_heap.push_back(value);
  if (term_heap.size() > 0x40000000) {
    // Report error: heap size exceeded.
  }
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

### Variables

Variables have the following representation:
```
   +---------------------------------------+
MSB|vvvv vvvv vvvv vvvv vvvv vvvv vvvv vv00|LSB
   +---------------------------------------+
```
The `v`s represent a 30-bit **signed offset**. Please note that the value 0 represents a variable with offset 0, that is a variable that points to itself. This is called an *unbound* variable.

The following C++ code example provides functions that determine whether a heap cell contains a variable and that calculates the index a variable references:
```c++
bool is_variable(int addr) {
  return term_heap[addr] & 0x3 == 0;
}

int variable_deref(int var_addr) {
  int offset = term_heap[var_addr] >> 2; // assuming arithmetic shift
  return var_addr + offset;
}
```

### Symbols

Symbols have the following structure:
```
   +---------------------------------------+
MSB|ssss ssss ssss ssss ssss ssss ssss 0001|LSB
   +---------------------------------------+
```
The `s`s are 28 bits specific to a symbol. For example, symbol `foo` will be represented by one string of 28 bits while symbol `bar` will be represented by another. There is no relation between the textual representation (`foo` and `bar`) and the bits representing them. However, within the scope of a single program, one (textual) symbol will always be represented by the same bit-string.

### Constants

Constants can come in three different types: `int64`, `float64` and strings. Their representation is as follows:

```
   +---------------------------------------+
MSB|iiii iiii iiii iiii iiii iiii iiii TT01|LSB
   +---------------------------------------+
```

Here, `TT` determines the type of constant and the `i`s represent an _unsigned_ index in the corresponding value heap. The following C++ code example shows how the type and offset can be determined based on the value in `term_heap[i]`:

```c++
int type = (term_heap[i] >> 2) && 3;
int index = (term_heap[i] >> 4) & 0x0FFFFFFF;
```

### Pairs

A pair represents an ordered pair of objects in the heap. Its representation is as follows:
```
   +---------------------------------------+
MSB|llll llll llll lllr rrrr rrrr rrrr rr10|LSB
   +---------------------------------------+
```
Here, the `l`s and the `r`s represent _unsigned_ offsets to the left and right element of the pair, respectively. The offset is unsigned because the pair element is always expected to be with a higher index relative to its components. A value of 0 for either the `l` or the `r` bit-string represents the special value `nil`.

A pair is constructed by calculating the distances to the left and right targets from the top of the heap. If this distance exceeds the addressable range for either the left or right element, a variable is added with the complete offset to the target and the offset from the pair is addressed to that variable.

The following C++ code example defines the `cons` function, which constructs a pair given `left` and `right` addresses on the heap.

```c++
int new_variable_to(int target) {
  int offset = target - term_heap.size();
  int value = target << 2;  // Adds 00 at the end.
  return allocate_term(value);
}

int const(int left, int right, int32_t suffix = 0x2) {
  if (term_heap.size() - left > 0x7FFE) {
    left = new_variable_to(left);
  }
  if (term_heap.size() - right > 0x7FFF) {
    right = new_variable_to(right);
  }
  int32_t value = (term_heap.size() - left) & 0x7FFF;
  value = (value << 15) | ((term_heap.size() - right) & 0x7FFF);
  value = (value << 15) | suffix;
  return allocate_term(value);
}
```

The following C++ code example shows how a pair is interpreted by implementing `car` and `cdr` to extract the left and right indexes, respectively. Both functions return -1 to indicate `nil`.

```c++
// Returns the left component.
int car(int pair) {
  int offset = (term_heap[pair] >> 17) & 0x7FFF;
  return offset == 0 ? -1 : pair - offset;
}

// Returns the right component.
int cdr(int pair) {
  int offset = (term_heap[pair] >> 2) & 0x7FFF;
  return offset == 0 ? -1 : pair - offset;
}
```

### Hooks

Hooks associate (unbound) variable with goals that need to be satisfied once they are bound to values. Hooks are represented as follows:
```
   +---------------------------------------+
MSB|gggg gggg gggg gggn nnnn nnnn nnnn nn11|LSB
   +---------------------------------------+
```

Here, the `g`s represent an unsigned offset to the goal that needs to be satisfied and the `n`s represent an unsigned offset to the next hook in the chain, or 0 to indicate that this is the last one. Like pairs, these offsets are subtracted from the address of the hook.

If a hook needs to reference objects (either a goal or the next hook) that are too far away to be represented with 15 bits, the offset may point to a variable which in turn will point to the desired goal/hook.

Since structurally, hooks are identical to pairs, they can use the same `cons`, `car` and `cdr` operations described above, with the only difference being the suffix provided to the `cons` function:

```c++
int cons_hook(int goal, int next) {
  return cons(goal, next, 0x3);
}

int hook_goal(int hook) {
  return car(hook);
}

int hook_next(int hook) {
  return cdr(hook);
}
```

## Stack

The stack is represented by a variable-size _signed_ `int32` array. Pushing to the stack involves adding an element at the end of the array, while popping the stack involves removing the last element.

Non-negative values represent indexes on the heap. Negative values are treated as special values, according to the following table:
| Numeric value | Meaning        |
|---------------|----------------|
| -1            | `nil`          |

