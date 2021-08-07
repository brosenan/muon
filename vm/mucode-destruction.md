# Destruction Instructions

The instructions described in this section are intended to deconstruct the term at the top of the stack. Deconstruction includes four parts:

1. Removing the object from the stack.
2. Checking that the object at the top of the stack matches some expectation, or failing if it does not.
3. Binding variables or performing unifications, when applicable.
4. In the case of pairs, pushing the components of the pair to the stack to allow further deconstruction.

All the instructions described in this section follow roughly the same algorithm:

* Pop an address from the stack and `find` its underlying value.
* If the value is a free variable:
    * Bind the expected value to that variable.
    * Succeed.
* Else, if the value matches the expectation (type and/or value):
    * In the case of a pair, push the two components to the stack.
    * Succeed.
* Else, fail.

## Symbols and Literals.

The operations `D_SYMBOL`, `D_INT64`, `D_FLOAT64` and `D_STRING` are similar in their format to the heap object each of them is intended to match against, with the exception of one bit. For example, the instruction `D_SYMBOL` with symbol bits `1010 1010 1010 1010 1010 1010` is encoded as:

```
   +---------------------------------------+
MSB|1010 1010 1010 1010 1010 1010 0001 0001|LSB
   +---------------------------------------+
                                     ^
```

While the heap value it is expected to match is represented as:

```
   +---------------------------------------+
MSB|1010 1010 1010 1010 1010 1010 0000 0001|LSB
   +---------------------------------------+
                                     ^
```

As a result, for either comparison and binding, the operation's implementation needs to first zero that bit in the instruction. The same implementation can be used for all the above instructions (they only differ in their op-codes).

The following C++ code example shows a common implementation for all these instructions.

```c++
bool d_literal_inst(int32_t op) {
    int32_t expected = op & ~0x10;
    int ref = find(stack_pop());
    if (ref == -1) {
        return false;
    } else if (is_variable(ref)) {
        bind(ref, allocate_term(expected));
        return true;
    } else {
        return term_heap[ref] == expected;
    }
}
```

## D_NIL

`D_NIL` expects the object popped from the stack to be `nil`.

The following C++ code example shows an example for how it can be implemented.

```c++
bool d_nil_inst(int32_t op) {
    int ref = find(stack_pop());
    if (ref == -1) {
        return true;
    } else if (is_variable(ref)) {
        bind(ref, -1);
        return true;
    } else {
        return false;
    }
}
```

## D_PAIR

`D_PAIR` deconstructs a pair. It pushes the components of the pair such that the first element is on top.

For example, consider the following "before" stack:

```
top    | (foo, bar) |
       | baz        |
       | apple      |
bottom | banana     |
```

After a successful invocation of `D_PAIR` the stack will look as follows:


```
top    | foo     |
       | bar     |
       | baz     |
       | apple   |
bottom | banana  |
```

If the object at the top of the stack is a free variable, `D_PAIR` allocates two new variables, pushes them to the stack, creates a pair based on them and binds the original variable to that pair.

The following C++ code example shows an example for how `D_PAIR` can be implemented.

```c++
bool d_pair_inst(int32_t op) {
    int ref = find(stack_pop());
    if (ref == -1) {
        return false;
    } else if (is_variable(ref)) {
        stack.push_back(allocate_term(0));  // right.
        stack.push_back(allocate_term(0));  // left.
        // The new pair's value will always point to the two elements before it in the heap
        // as its left and right components. This means that its value will be constant:
        //    +---------------------------------------+
        // MSB|llll llll llll lllr rrrr rrrr rrrr rr10|LSB
        //    |0000 0000 0000 0010 0000 0000 0000 1010|
        //    +---------------------------------------+
        // (l = 1 and r = 2)
        bind(ref, allocate_term(0x0002000a));
        return true;
    } else if (is_pair(ref)) {
        stack.push_back(cdr(ref));  // right.
        stack.push_back(car(ref));  // left.
    } else {
        return false;
    }
}
```

## D_VAR

`D_VAR` [unifies](variable-operations.md#unification) the object it pops from the top of the stack with one of the [locals](non-restorable-data-structures.md#locals).

The following C++ code example shows an example for how `D_VAR` can be implemented.

```c++
bool d_var_inst(int32_t op) {
    return unify(stack_pop(), get_local((op >> 8) & 0xFFFFFF));
}
```
