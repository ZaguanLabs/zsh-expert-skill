# Input, parsing, and serialization

Use this section for option parsers, line/field readers, shell lexical parsing, binary boundaries, and safely transporting arrays.

## Read without interpretation

```zsh
while IFS= read -r line; do
  lines+=("$line")
done < "$file"
```

`-r` prevents backslash processing. A final unterminated line makes `read` return nonzero after assigning it, so use this form when it must be retained:

```zsh
while IFS= read -r line || [[ -n $line ]]; do
  lines+=("$line")
done < "$file"
```

Use `read -u fd`, `-t timeout`, `-k count` for terminal keys, and `-d delim` for custom delimiters. Locale affects characters versus bytes.

## Split only once

```zsh
lines=("${(@f)text}")
parts=("${(@s.:.)record}")
```

`(@s:sep:)` preserves empty fields. Avoid setting global `IFS` or enabling `SH_WORD_SPLIT`. For NUL-delimited external data, read with a NUL delimiter in a loop or use `zsh/system`; do not store a whole NUL stream in one scalar.

## Parse shell words without executing them

`${(z)text}` applies Zsh lexical word splitting. `${(Z:C:)text}` can strip comments while respecting quotes and multiline syntax. `${(@Q)...}` removes one quote layer.

```zsh
local -a words
words=("${(@Q)${(z)serialized}}")
```

This recovers shell-word data produced by a compatible quoting encoder. It does not validate a command and must not be followed by `eval` for untrusted input.

When parsing configuration, define a grammar narrower than Zsh. Accept `NAME=value`, validate the name, keep the value literal, impose file/line limits, and reject command substitutions rather than sourcing the file.

## `zparseopts` for native APIs

Load `zsh/zutil` or autoload a wrapper and parse positional parameters into arrays:

```zsh
emulate -L zsh
zmodload zsh/zutil || return
local -a help output verbose
zparseopts -D -E -- \
  h=help -help=help \
  o:=output -output:=output \
  v+=verbose || return 2
```

Key design choices:

- `-D` removes recognized options from `$@`;
- `-E` allows options after operands;
- `-F` fails atomically on an unknown option-like argument;
- `-K` preserves defaults already in destination arrays;
- `:=array` retains option plus argument; `=array` stores occurrences;
- stable 5.9 lacks the development-line `-G` GNU parser (`--opt=value`), `-n`, and `-v` additions.

Inspect actual array layout in tests. Do not assume GNU long-option abbreviation.

For broadly portable CLIs, `getopts` may be the better contract. Zsh's `zparseopts` shines for native functions and completion helpers.

## Command arrays, not command strings

```zsh
local -a cmd=(git -C "$repo" status --porcelain=v1)
"${cmd[@]}"
```

Optional segments remain arrays:

```zsh
(( verbose )) && cmd+=(--verbose)
cmd+=(-- "$path")
```

Do not invoke with `${=cmd}` unless the scalar is a deliberately word-split user interface and injection consequences are acceptable.

## Serialization choices

In priority order:

1. keep data in the same shell as an array/association;
2. use NUL-delimited records between processes;
3. use JSON or another typed external format;
4. for Zsh-to-Zsh trusted transport, encode each word with `(q)` and decode via `(z)` + `(Q)`;
5. never use ad hoc space-separated text for arbitrary filenames.

`typeset -p` can emit restorable declarations for trusted state. Do not source such output from an untrusted location.

## Bounded input

Before reading a directory-local or remote-generated file:

- validate ownership/type when trust matters;
- cap size with `zstat` and/or bounded `sysread`;
- set a timeout for FIFOs/terminals;
- reject NUL or unsupported encoding explicitly;
- keep diagnostics separate from parsed data.

Search terms: `zparseopts`, expansion flag `(z)`, expansion flag `(Z)`, `read -d`, NUL delimiter, command arrays.
