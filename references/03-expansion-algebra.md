# Expansion algebra

Use this section when a solution needs parameter flags, nested substitutions, modifiers, precise splitting/joining, quoting, or pattern-controlled replacement.

## Treat each expansion as a pipeline

Read from the inside out and name intermediate stages when more than two transformations occur. Zsh's formal expansion order is subtle: nested substitution, subscripts, parameter-name replacement, joining/splitting, modifiers, quoting, lexical parsing, sorting, uniqueness, and re-evaluation do not all commute.

Prefer:

```zsh
local -a lines selected
lines=("${(@f)text}")
selected=("${(@M)lines:#(#i)*error*}")
print -rl -- "${selected[@]}"
```

over an unexplained five-flag expression.

## High-value flags

- `(@)` preserves array elements inside double quotes.
- `(j:sep:)` joins array elements; `(F)` joins with newlines.
- `(s:sep:)` splits literally; `(f)` splits on newlines; use `(@s:...:)` to preserve empty fields.
- `(z)` tokenizes as Zsh command-line words; `(Z:C:)` can omit comments. This parses shell lexical structure but does not make the result trusted.
- `(Q)` removes one level of shell quoting; `(q)`, `(qq)`, `(qqq)`, `(q-)` produce different reversible/display-oriented quoting forms.
- `(V)` makes non-printing characters visible for diagnostics.
- `(k)`, `(v)`, `(kv)` select associative keys, values, or alternating pairs.
- `(M)` retains matched portions/elements; `(R)` selects matching values; `(B)`, `(E)`, `(N)` expose match positions/counts in relevant substitutions.
- `(o...)`/`(O...)` sort ascending/descending; `n` is numeric, `-` correctly handles negative numeric sort in 5.9+.
- `(u)` removes duplicates after ordering; a `typeset -U` array maintains uniqueness on assignment.
- `(P)` dereferences a parameter name.
- `(%)` performs prompt escapes; never apply it blindly to untrusted content.
- `(e)` re-evaluates parameter, command, and arithmetic substitutions. Treat it like `eval`.

## Quote and unquote deliberately

For display/debugging:

```zsh
print -r -- ${(qqqq)value}
print -r -- ${(V)value}
```

For reversible shell-word transport within Zsh:

```zsh
encoded=${(j: :)${(q)argv}}
decoded=("${(@Q)${(z)encoded}}")
```

This is appropriate only when both ends intentionally use Zsh syntax. Prefer NUL-delimited or structured formats across process/language boundaries.

Do not unquote with `(Q)` and then pass through `(e)` merely to recover arguments. That turns data into code.

## Modifiers are path algebra

Modifiers apply to parameters, history, and generated filenames:

- `:h` head/dirname, `:t` tail/basename;
- `:r` remove final extension, `:e` extension;
- `:a` absolute path with lexical normalization;
- `:A` resolve as far as possible, including symlinks;
- `:P` physical path resolution in supported contexts;
- `:l`, `:u`, `:c` lowercase, uppercase, capitalize;
- `:s/old/new/`, `:gs/old/new/` substitution.

Do not treat lexical normalization as a containment check. For security, resolve the intended existing ancestor and compare canonical path components.

## Pattern activation is explicit

Parameter values are normally data. `${~pattern}` activates filename generation/pattern interpretation in contexts that support it; `(#q...)` attaches explicit glob qualifiers. Quote or isolate pattern strings so that pattern compilation is visible in code review.

```zsh
local pattern='*.log'
local -a files
files=( ${~pattern}(N.) )
```

Validate or construct untrusted patterns from literals; Zsh patterns can be computationally expensive and can select far more files than intended.

## Substitution and arrays

Quoted scalar substitutions stay scalar. Quoted array substitutions join unless `(@)` is active. Pattern removal and replacement operate per element when the expansion is array-valued at that level.

If the correct behavior depends on whether an inner expansion remains an array, use explicit `(@)` at the inner level and test empty elements. Do not rely on visually similar nested forms being equivalent.

## Current-shell command substitution

Stable 5.9.2 supports ordinary `$(...)`; post-5.9 development adds non-forking `${ ... }`, `${| ... }`, and `${{param} ... }`. Never emit those without a version gate; see [22-version-gates.md](22-version-gates.md).

Search terms: parameter expansion flags, nested substitution rules, lexical splitting `(z)`, quote flag, path modifiers, current-shell substitution.
