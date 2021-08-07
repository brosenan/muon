# Variable Operations

As in many logic programming languages, logic variables in Muon form a [union-find data structure](https://en.wikipedia.org/wiki/Disjoint-set_data_structure) where each variable starts as a set which can then be unified with other sets (variables), with a _find_ operation that returns a consistent root for each merged set. The root can either be _unbound_ (i.e., point to itself or a hook-chain) or be _bound_ (i.e., point to a concrete value).

## Find

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

## Binding and Hooks

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
      // value is, well, a value. We need to schedule var's hook-chain.
      queue.push_back(hook_chain);
    }
  }
  // Finally, with the hook-chain taken care of, we can update var to point to value.
  update_term_heap(var, (value - var) << 2, cp_stack.back());
}
```

## Unification

Term unification is at the heart of any logic programming language. It is a symmetric operation by which two terms are compared to one another, and if they are equal up to variable assignments, the variable assignment that satisfies their equality is generated.

In μVM, the `unify` operation operates on two addresses in the heap. It returns a Boolean return value (`true` for success, `false` for failure) and as a side-effect, it binds variables to make the terms equal.

**Note:** On failure `unify` _does not_ roll-back bindings it has already performed. This is the responsibility of the caller.

The `unify` operation over addresses `a` and `b` works as follows:
* It checks that either `a` and `b` are `nil` (in which case it returns `true`), or none of them (in which case it continues). If only one of them is `nil` it returns `false`.
* It replaces `a` and `b` with the result of applying `find` to each of them.
* If `a` is a variable, `a` is bound to `b` and return `true`.
* If `b` is a variable, `b` is bound to `a` and return `true`.
* If `a` is a symbol:
  * If `b` is a symbol with the same value as `a` we return `true`.
  * Otherwise, we return `false`.
* If `a` is a constant:
  * If `b` is a constant of the same type and `a` and `b` have the same value, we return `true`. Please note that `a` and `b` may point to different locations in the respective value heap, but still have the same value.
  * Otherwise, we return `false`.
* If `a` is a pair:
  * If `b` is a pair, call `unify` recursively on both `car(a)` and `car(b)` and on `cdr(a)` and `cdr(b)`. Return the conjunction (AND) of both results.


The following C++ code example shows how `unify` can be implemented:

```c++
bool unify(int a, int b) {
  // Make sure either a and b are both nil, or none of them are.
  if (a == -1) {
    return b == -1;
  }
  if (b == -1) {
    return false;
  }
  // Find the roots of both a and b.
  a = find(a);
  b = find(b);
  // If either a or b are variables, use binding.
  if (is_variable(a)) {
    bind(a, b);
    return true;
  }
  if (is_variable(b)) {
    bind(b, a);
    return true;
  }
  if (term_heap[a] & 0xF == 0x1) {
    // a is a symbol.
    return term_heap[a] == term_heap[b];
  }
  if (term_heap[a] & 0xF == 0x5) {
    // a is an int64 constant.
    if (term_heap[b] & 0xF != 0x5) {
      return false;
    }

    return int64_heap[(term_heap[a] >> 4) & 0x0FFFFFFF] ==
           int64_heap[(term_heap[b] >> 4) & 0x0FFFFFFF];
  }
  if (term_heap[a] & 0xF == 0x9) {
    // a is a float64 constant.
    if (term_heap[b] & 0xF != 0x9) {
      return false;
    }

    return float64_heap[(term_heap[a] >> 4) & 0x0FFFFFFF] ==
           float64_heap[(term_heap[b] >> 4) & 0x0FFFFFFF];
  }
  if (term_heap[a] & 0xF == 0xd) {
    // a is a string constant.
    if (term_heap[b] & 0xF != 0xd) {
      return false;
    }

    return string_heap[(term_heap[a] >> 4) & 0x0FFFFFFF] ==
           string_heap[(term_heap[b] >> 4) & 0x0FFFFFFF];
  }
  if (is_pair(a)) {
    if (!is_pair(b)) {
      return false;
    }
    return unify(car(a), car(b)) && unify(cdr(a), cdr(b));
  }
  // This should not happen.
  return false;
}
```
