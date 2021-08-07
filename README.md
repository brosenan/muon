# Muon

Muon is an experimental language built from first principles. It can be described as either:

* A pure logic-programming language,
* A Lisp that uses logical deductions in place of macros, or
* A test-bed for programming language experimentation.

## Installation

You'll need to have Java 7 and up installed.

Then type:

```
> git clone https://github.com/brosenan/muon.git
> cd muon
> ./install.sh
```

The `install.sh` script will download the latest `.jar` file and will add the `muon` script to the path in the `~/.bashrc`.

Now, enter a new `bash` shell and try:

```
> muon --help
```

Or:

```
> muon -Ta examples.language-test
```

And have fun...

## Getting Started

Depending on how you wish to use Muon, there are two different ways to start.

* If you are interested in Muon as a logic-programming language, please consider [the language documentation](language.md).
* If you are interested in Muon as a Lisp, please consider the documentation for [expr](expr.md), our Lisp-like language.

In either case we recommend opening the test file in an editor, running `muon` in autotest mode (`-Ta`) on the relevant test module
(either `examples.language-test` or `expr-test`) and hacking around the tests.

## So, What is Muon, Really?

OK, So I guess the answer we provided at the top of this file is not really satisfying, so here is the longer answer.

### The Name Muon

[Muon](https://en.wikipedia.org/wiki/Muon) is an elementary particle. It is a lepton similar to an electron, just ~207 times more massive.
The choice of name for this language follows a convention I established in a [previous project](https://github.com/brosenan/neutrino), naming
languages that are built from first principles after the building blocks of the universe...

### Muon as a Pure Logic Programming Language

Muon is a truly, genuinely purely declarative. The language only defines one operator: `<-`, which allows for the definition of [rules](language.md#rules).
Numbers, strings and symbols have no special meaning.

### Muon as a Practical Language

A purely-declarative programming language is very limited in what it is capable of doing.
To fix this problem, Muon introduces the concept of a [Query, Evaluate, Parse Loop (QEPL)](muon-clj/qepl.md).
This loop exists outside the Muon program and performs the following:
* _Queries_ the program for an expression to evaluate.
* _Evaluates_ that expression. This may have side-effects.
* _Parses_ the value returned by the expression.
* _Loops_ back, providing the parsed result of the evaluation as argument for the next iteration.

The QEPL also maintains the state of a program, given as a Muon term. Each step will provide, along with the expression to be evaluated, the next state of the program.

By defining solutions for that query, a Muon program can use the QEPL to do things it cannot do by itself, such as perform calculations on number and strings,
read input, write output and more.

### Muon as a Lisp

Muon is a Lisp. It is a Lisp because its syntax is based on [s-expressions](https://en.wikipedia.org/wiki/S-expression) (specifically, they are based on
[EDN](https://github.com/edn-format/edn)). But this is only where the similarity begins.

The [expr](expr.md) module defines a Lisp-like language for Muon. That is, it provides solutions for the queries made by the QEPL
based on definitions provided by the users of that module. With this module, users can define impure functions that can eventually do
anything the QEPL can, and the QEPL can do anything the language in which it is implemented can.

One difference Muon holds from most Lisps is that it does not use macros. Instead of macros, developers can use logic deduction to define new language concepts.

### Muon as a Testbed for Language-related Ideas

There are pros and cons for building a language from scratch, based on first principles. The cons include having no ecosystem in place, no community,
no documentation I can refer prospective users to... nothing. But this lack of... anything... opens the door to a many opportunities. Here I'll explore some.

#### A Testbed for Language Concepts

One thing one can easily do with Muon is define new languages and new language concepts. As evidence, the [expr module](lib/expr.mu) defines an entire
functional programming language in less than 100 lines of code (as of writing these lines).

Logic deduction is not a common approach for implementing language features, but it is an effective one. In fact, the QEPL approach is highly related to
[small-step operational semantics](https://en.wikipedia.org/wiki/Operational_semantics#Small-step_semantics), a tool used by theoretical computer scientists
to define the semantics of a language.

#### A Testbed for Static Analysis

Muon is a dynamic language. Except for a few error messages that can be produced by the module system about the use of namespaces, any valid EDN file will make a valid
Muon module, and a Muon program is just a set of those. This makes it easy to define new kinds of definitions (such as how the `expr` module provides a way to
define functions), but at the same time makes it hard to detect mistakes.

For example, if a user typed `defn` instead of `defun` when defining a new function in `expr`, Muon has no reason to believe they made a mistake. There is nothing special
about `defun` except for the fact that `expr` provides rules for interpreting it.

This creates an opportunity for developing static analysis strategies which will try to find these mistakes statically. Muon, as a logic-programming language, is supposed
to be well equipped for such a task.

#### A Testbed for Specialization and Compilation

This is something I'm especially excited about. One of the advantages of having a pure logic-programming language is the fact that it makes [partial evaluation / specialization](https://en.wikipedia.org/wiki/Partial_evaluation) easy and safe. Since Muon itself does not give any special meaning to numbers or strings,
it should be possible to make a query to a Muon program, replacing all values with arbitrary symbols representing any possible value.
In such a case, unless the program matches against a specific value (which can be determined by replacing the symbol with a logic variable) the program's behavior
should be unaffected by the fact that we provide symbols in place of values. But the difference is that instead of performing a specific computation on specific values,
we now describe the general computation, on _any_ value.

This can work very well with the QEPL approach. A compiler can query the Muon program iteratively, but instead of evaluating the expressions, it can build a program
from these expressions. Instead of providing the next query the result of the previous one, it will provide it with a symbol that would represent it in the generated
program.

The main challenge with this approach is identifying loops and subroutines, which are essential to guarantee that the compilation process will terminate.
