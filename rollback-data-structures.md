# Rollback Data Structures

To support non-determinism / backtracking, μVM requires the ability to move back in time and restore past states of the computational data structures. To this end, a few additional data structures are defined.

Driving the rollback process are **choice points**, objects that represent the state of the VM at a certain point in time using O(1) values. Other data structures are used in conjunction with choice points to restore the VM state to the point described by the choice point.

## Trail

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

## Stack Restoration Stack (SRS)

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

## The Choice Point Stack

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


### CPS Structure

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

### CPS Operations

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

