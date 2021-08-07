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
> muon -T expr-test
```

And have fun...
