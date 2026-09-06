# Arithmetic and numeric design

Use this reference for counters, sizes, timestamps, bit fields, numeric validation, simulations, or a native mathematical API.

## Declare the numeric model

Zsh has integer and double-precision floating point arithmetic. Type the operands before a calculation; assigning a truncated integer result to a float does not recover the fraction.

```zsh
local -i completed=3 total=8
local -F 3 fraction
(( total > 0 )) || return 2
(( fraction = completed / (1.0 * total) ))
```

`-F 3` sets output formatting, not three-decimal internal precision. `-E` changes floating output to exponential notation. An undeclared variable first assigned in arithmetic can acquire an integer type, so `for (( f=0; f<1; f+=0.1 ))` can fail to progress. Declare fractional loop variables explicitly, or use an integer iteration count and derive the fractional coordinate to avoid accumulated rounding.

Use scaled integers for exact bounded counters. Do not use binary floats for exact decimal accounting, and do not assume arbitrary-precision integers or overflow checks. Choose another language when precision requirements exceed the shell's numeric representation.

## Parenthesize unfamiliar precedence

Native Zsh gives bitwise operators and shifts different precedence from C. Write the intended grouping, e.g. `(( (flags & mask) == expected ))`. Local `C_PRECEDENCES` selects C-like ordering when that is the explicit API. In both modes, unary minus binds above exponentiation: `-3**2` is 9; `-(3**2)` is -9.

`(( expression ))` reports status 1 for numeric zero and 0 for nonzero. Therefore assignment, decrement, or a post-increment can look like failure under `ERR_EXIT`/`ERR_RETURN`. A numeric result and a command status are different channels. In an ordinary setter, explicitly return success after assigning a valid zero; in a predicate, use the arithmetic status intentionally.

## Validate text before evaluating it

Arithmetic recursively interprets parameter values as expressions. Quoting a value does not make `typeset -i`, arithmetic subscripts, or `(( ... ))` safe for arbitrary text. Establish a narrow numeric grammar and a length/range bound first.

```zsh
_acme_parse_count() {
  emulate -L zsh
  setopt extendedglob
  (( $# == 1 )) || return 2
  local raw=$1
  [[ $raw == [0-9]## && ${#raw} -le 7 ]] || return 2
  local -i count=$((10#$raw))
  (( count <= 1000000 )) || return 2
  REPLY=$count                 # caller declares local REPLY
  return 0
}
```

The small length bound makes conversion safe before range checking; `10#` makes leading zeros decimal regardless of the caller's octal preference. If signs, fractions, exponent notation, or other bases are valid, define and test that grammar separately rather than allowing arbitrary shell arithmetic. A numeric range glob `<1-20>` matches a numeric string, but adjacent wildcards can enlarge the language: `<0-9>*` also matches longer digit strings.

## Build small mathematical APIs

Load `zsh/mathfunc` for scientific primitives such as `sqrt`, `sin`, and `hypot` when supported by the build. Contributed `zmathfunc` supplies `min`, `max`, and `sum`; those are not automatically supplied by `zsh/mathfunc`.

`functions -M` registers a shell function for use inside arithmetic:

```zsh
_acme_square_impl() {
  (( $1 * $1 ))
  true
}
functions -M acme_square 1 1 _acme_square_impl
print -r -- $((acme_square(0)))
print -r -- $((acme_square(3)))
# Owner teardown: functions +M acme_square; unfunction _acme_square_impl
```

The result is the last arithmetic value computed, while the shell function must return status 0. Ending in `true` preserves the value and succeeds for zero; ending in `return 0` evaluates another arithmetic value and replaces the result. The registration's minimum/maximum argument count enforces arity. `functions -Ms` passes a string argument for a deliberately string-based math function. These registrations are global; namespace and unregister owned APIs.

`zmathfuncdef` is a contributed convenience wrapper, and `zcalc` demonstrates an interactive arithmetic language with history and RPN state. Reuse the relevant primitive rather than embedding a calculator for a simple numeric task.

## Represent time and randomness deliberately

`strftime -s result format timestamp` returns formatted time in the current shell. `epochtime` provides seconds and nanoseconds together; capture its pair once instead of reading changing clock parameters separately. `EPOCHREALTIME` is wall-clock time and may jump. A local floating `SECONDS` can measure elapsed intervals without spawning `date`, subject to the runtime's clock behavior.

`RANDOM` is a small repeatable pseudorandom generator, not a source of secret tokens. `rand48(seed_name)` supports independent deterministic sequences through explicit seed parameters when available. Control seeds for reproducible tests and do not assume forked workers have independent streams. Newer random modules need the version/capability checks in [22-version-gates.md](22-version-gates.md).

Search terms: `C_PRECEDENCES`, `FORCE_FLOAT`, `OCTAL_ZEROES`, `functions -M`, `zmathfunc`, `zcalc`, arithmetic recursion, `epochtime`, `rand48`.
