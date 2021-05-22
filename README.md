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

size_t allocate_int64(int64_t value) {
  int64_heap.push_back(value);
  if (int64_heap.size() > 0x10000000) {
    // Report error: maximum number of int64 values exceeded.
  }
  return int64_heap.size() - 1;
}
```

#### Term Heap

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

##### Variables

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

##### Symbols

Symbols have the following structure:
```
   +---------------------------------------+
MSB|ssss ssss ssss ssss ssss ssss ssss 0001|LSB
   +---------------------------------------+
```
The `s`s are 28 bits specific to a symbol. For example, symbol `foo` will be represented by one string of 28 bits while symbol `bar` will be represented by another. There is no relation between the textual representation (`foo` and `bar`) and the bits representing them. However, within the scope of a single program, one (textual) symbol will always be represented by the same bit-string.

##### Constants

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

##### Pairs

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

##### Hooks

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

#### Stack

The stack is represented by a variable-size _signed_ `int32` array. Pushing to the stack involves adding an element at the end of the array, while popping the stack involves removing the last element.

Non-negative values represent indexes on the heap. Negative values are treated as special values, according to the following table:
| Numeric value | Meaning        |
|---------------|----------------|
| -1            | `nil`          |

#### Queue

The queue is a data structure intended to support dynamic scheduling. It is represented as a variable-size array of `int32` each representing an address of a `hook` chain in the heap.

Unlike the stack and the heap, which grow and shrink throughout the lifespan of a Muon computation, the queue is extremely short-lived. Its contents is reset after the completion of every unification operation, where its contents is flushed into the stack.

The `queue_flush` operation walks through every hook chain rooted in the queue and flushes all the goals listed there to the stack. Once this is complete, the queue is reset.

The following C++ code example shows how the `queue_flush` operation may be implemented.

```c++
std::vector<int> queue;

// Pushes a single hook-chain to the stack.
void push_hook_chain(int chain) {
  while (chain != -1) {
    switch (term_heap[chain] & 0x3) {
      case 0x3:  // a hook
        // Push the goal to the stack.
        stack.push(car(chain));
        chain = cdr(chain);
        break;
      case 0x2:  // a pair
        // Continue with the left chain. Push the right chain to the end of the queue.
        queue.push_back(cdr(chain));
        chain = car(chain);
        break;
      default:
        // Report error: a hook chain can only contain hooks and pairs.
    }
  }
}

void queue_flush() {
  for (int i = 0; i < queue.size(); i++) {  // Note that queue may grow during this process.
    push_hook_chain(queue[i]);
  }
  queue.resize(0);
}
```

### Rollback Data Structures

To support non-determinism / backtracking, μVM requires the ability to move back in time and restore past states of the computational data structures. To this end, a few additional data structures are defined.

Driving the rollback process are **choice points**, objects that represent the state of the VM at a certain point in time using O(1) values. Other data structures are used in conjunction with choice points to restore the VM state to the point described by the choice point.

#### Trail

The trail is responsible for restoring the term heap. It is variable-size array of pairs of `int32`, representing an address in the heap and its previous value. It can be thought of as an undo-stack for the heap.

At a first approximation, every change made to the heap requires adding a pair consisting of the index of the cell being updated and the value of that cell _before_ the update to the trail. This way, by playing the trail in reverse order we can undo all these changes until we reach the state described by the choice point.

However, this can be optimized by storing the size of the heap in the choice point, and only storing updates to cells below that index in the trail. The rationale is that reverting to the choice point will include shrinking of the heap to its size at the choice point, thus all cells beyond that point would be discarded anyways.

The following C++ code example depicts a function for updating the heap while updating the trail if needed, and then for restoring the heap to a given choice point.

```c++
std::vector<std::pair<int, int32_t>> trail;

void update_term_heap(int index, int32_t value, const ChoicePoint& cp) {
  if (index < cp.term_heap_size) {
    trail.push_back(std::make_pair(index, term_heap[index]));
  }
  term_heap[index] = value;
}

void restore_heap(const ChoicePoint& cp) {
  term_heap.resize(cp.term_heap_size);
  while (trail.size() > cp.trail_size) {
    auto [index, value] = trail.back();
    term_heap[index] = value;
    trail.pop_back();
  }
}
```

#### Stack Restoration Stack (SRS)

The SRS is a stack intended to restore elements that have been popped from the stack after the choice point and need to be pushed back to it, to restore its state. It is represented as a variable-size array of `int32` (`srs`) and an `int32` value, indicating its lowest size the stack has reached since the last choice point (`srs_index`).

When a choice point is set, the `srs_index` is set to the stack size at that point, and the previous `srs_index` value is stored in the choice point data structure.

When popping a value from the stack, if the size of the stack equals `srs_index`, the value at the top of the stack (the one returned by the pop operation) is pushed to the `srs` and `srs_index` is decremented.

To restore the stack, the stack is first trimmed to `srs_index`. Then values are popped from the `srs` until the stack reaches its original size at the choice point.

The following C++ code example demonstrates the lifecycle of the SRS:

```c++
std::vector<int32_t> stack;
std::vector<int32_t> srs;
int32_t srs_index;

void set_choice_point() {
  ChoicePoint new_cp;
  // ...
  new_cp.last_srs_index = srs_index;
  new_cp.stack_size = stack.size();
  srs_index = stack.size();
  // ...
}

int32_t stack_pop() {
  if (stack.size() == srs_index) {
    srs_index--;
    srs.push_back(stack.back());
  }
  int32_t value = stack.back();
  stack.pop_back();
  return value;
}

void restore_stack(const ChoicePoint& cp) {
  stack.resize(srs_index);
  while (stack.size() < cp.stack_size) {
    stack.push_back(srs.back());
    srs.pop_back();
  }
  srs_index = cp.srs_index;
}
```

#### The Choice Point Stack

The choice point stack (CPS) represents the collection of choices made through the computation process and still have viable alternatives to explore. For example, consider the following decision tree relating to a meal choice:

```
            meal
             |
       +--------------+
     regular       vegetarian
       |
  +---------+
beef      chicken
````

When a person is considering which meal to take they first have a choice between `regular` and `vegetarian`. Then, if they have chosen `regular`, they have a choice between `beef` and `chicken`. Given that a person considers the meals in this diagram from left to right, at the point when they are considering `beef` they have to remember that they still have more options on that level (i.e., `chicken`), and also that they still have alternatives on the previous level (i.e., `vegetarian`). However, when they move to consider `chicken` the no longer have a pending alternative on that level, so that they can _commit_ to `chicken` in the sense that if `chicken` doesn't work for them, they have to abandon `regular` all together, and move directly to `vegetarian`.


##### CPS Structure

The CPS consists of a variable-size array of `ChoicePoint` records, each containing the following fields:
| Name                | Type    | Description                                                          |
|---------------------|---------|----------------------------------------------------------------------|
| `term_heap_size`    | `int32` | The heap size at the time of the choice point.                       |
| `int64_heap_size`   | `int32` | The `int64` heap size at the time of the choice point.               |
| `float64_heap_size` | `int32` | The `float64` heap size at the time of the choice point.             |
| `string_heap_size`  | `int32` | The string heap size at the time of the choice point.                |
| `trail_size`        | `int32` | The size of the trail at the time of the choice point.               |
| `stack_size`        | `int32` | The size of the stack at the time of the choice point.               |
| `srs_index`         | `int32` | The `srs_index` value at the time of the choice point.               |
| `next_option`       | `int32` | The index of the next μCode instruction to be executed upon failure. |

The following C++ code example shows a possible definition of the CPS:

```c++
struct ChoicePoint {
  int32_t term_heap_size;
  int32_t int64_heap_size;
  int32_t float64_heap_size;
  int32_t string_heap_size;
  int32_t trail_size;
  int32_t stack_size;
  int32_t srs_index;
  int32_t next_option;
};

std::vector<ChoicePoint> cp_stack;
```

##### CPS Operations

The CPS supports two basic operations: `cp_set` and `cp_restore`.

`cp_set` pushes a new choice point to the CPS, based on the current state of the VM. The following C++ code example shows how this can be done:

```c++
void cp_set(int32 next_option) {
  if (queue.size() > 0) {
    // Report error: the queue size must be zero when arriving at a choice point.
  }

  cp_stack.emplace_back();  // This adds a new record at the top of the stack without initializing it.

  cp_stack.back().term_heap_size = term_heap.size();
  cp_stack.back().int64_heap_size = int64_heap.size();
  cp_stack.back().float64_heap_size = float64_heap.size();
  cp_stack.back().string_heap_size = string_heap.size();
  cp_stack.back().trail_size = trail.size();
  cp_stack.back().stack_size = stack.size();
  cp_stack.back().srs_index = srs_index;
  cp_stack.back().next_option = next_option;
}
```

`cp_restore` restores the VM state into its state at the choice point (i.e., when `cp_set` was performed). It does not pop the current choice point from the CPS as we may still have options to explore under this choice point.

The following C++ code example shows a possible implementation of `cp_restore`, based on restoration functions defined in previous examples:
```c++
void cp_restore() {
  if (cp_stack.empty()) {
    // Report error: attempting to restore to an non-existing choice point.
  }
  restore_heap(cp_stack.back());
  restore_stack(cp_stack.back());

  int64_heap.resize(cp_stack.back().int64_heap_size);
  float64_heap.resize(cp_stack.back().float64_heap_size);
  string_heap.resize(cp_stack.back().string_heap_size);
  
  queue.resize(0);
}
```

## Variable Operations

As in many logic programming languages, logic variables in Muon form a [union-find data structure](https://en.wikipedia.org/wiki/Disjoint-set_data_structure) where each variable starts as a set which can then be unified with other sets (variables), with a _find_ operation that returns a consistent root for each merged set. The root can either be _unbound_ (i.e., point to itself or a hook-chain) or be _bound_ (i.e., point to a concrete value).

### Find

The `find` operation takes an address of an object on the heap. If it is a bound varaible, the address of the object it is bound to is returned. If it is unbound, a consistent root is returned.

The following C++ code example shows how the `find` operation can be implemented:

```c++
int find(int addr) {
  if (!is_variable(addr)) {
    return addr;
  }
  
  int var = addr;  // addr is the address of a variable...
  int next = variable_deref(var);  // ...which points to next.
  if (next == var) {
    // var is a self-referencing variable, which is the root.
    return var;
  } else if (is_hook(next)) {  // next & 0x3 == 0x3
    // var points to a hook, making it a root.
    return var;
  } else if (!is_variable(parent)) {
    // var points to a value (symbol, constant or pair). We return the value.
    return next;
  } else {
    // next is a variable that is different from var.
    // We will call find() recursively on it and update var to point to the root we find.
    int root = find(next);
    int new_value = (root - var) << 2;
    update_term_heap(var, new_value, cp_stack.back());
    return root;
  }
}
```

As can be seen in the example above, the path to the root variable can (and should) be collapsed by updating every variable in the path to point to the root directly. This optimization is at the core of the efficiency of the union-find data structure.

### Binding and Hooks

Binding is a directional operation which binds one variable to a value, which may or may not be an unbound variable. The `bind` operation is defined on a pair of addresses, `var` and `value`, which are both expected to be results of calls to `find` (i.e., roots). `var` is further required to be a variable (which is required to be unbound because of the requirement that it is a root).

After the `bind` operation, `var` is bound to `value`. If `value` is a value (symbol, constant or pair) then `var` will be bound to that value. If `value` is an unbound variable, `var` will be bound to it such that `find(var) == value`.

What makes binding a bit more challenging is the need to handle hooks correctly. Hooks are the μVM's way of delaying the evaluation of a logic goal until a certain variable is bound. Therefore, it is the responsibility of the `bind` operation to apply said hooks when binding a variable that contains hooks to a value. This is done by adding the hook-chain to the queue.

Similarly, when binding a variable that contains hook to another unbound variable with hooks, their hook chains need to be merged. This is done by creating a pair containing both chains.

The following C++ code example demonstrates how `bind` can be implemented.

```c++
void bind(int var, int value) {
  if (var == value) {
    // var and value are already bound. We're done.
    return;
  }
  if (term_heap[var] != 0) {
    // var has a hook-chain.
    int hook_chain = variable_deref(var);
  
    if (is_variable(value)) {
      // value is also an unbound variable.
      if (term_heap[value] != 0) {
        // value does have a hook-chain of its own. We need to merge the two.
        int value_hook_chain = variable_deref(value);
        hook_chain = cons(value_hook_chain, hook_chain);
      }
      // We can now update value to hold the hook-chain
      update_term_heap(value, (hook_chain - value) << 2, cp_stack.back());
    } else {
      value is, well, a value. We need to schedule var's hook-chain.
      queue.push_back(hook_chain);
    }
  }
  // Finally, with the hook-chain taken care of, we can update var to point to value.
  update_term_heap(var, (value - var) << 2, cp_stack.back());
}
```
