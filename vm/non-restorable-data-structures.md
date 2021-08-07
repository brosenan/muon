# Non-Resrorable Data Structures

The following data structures are short-lived and are not tracked by the rollback data structures.

## Queue

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

## Locals

Locals are a set of variables allocated on the heap, representing the variables in a single Horn clause. A single index, `locals_base` points to the region on the heap where they are allocated.

The following C++ code example shows how locals can be allocated and referenced.

```c++
int locals_base;

// Allocates n locals.
void allocate_locals(int n) {
    locals_base = term_heap.size();
    for (int i = 0; i < n; i++) {
        allocate_term(0);
    }
}

// Returns the address of local number n.
int get_local(int n) {
    return locals_base + n;
}
```
