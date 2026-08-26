# Parameters and arrays

Use this section for data modeling, subscripts, associations, special parameters, and safe argument boundaries.

## Choose the type first

```zsh
local scalar
local -a words
local -A by_name
local -i count=0
local -F 3 ratio
local -r constant=value
```

Explicit types prevent arithmetic and empty/unset surprises. In Zsh 5.9, `TYPESET_TO_UNSET` can leave declarations unset, but do not assume it is enabled.

Indexed arrays are one-based in native mode. `$array` means `$array[1]`, not the whole array. Use:

```zsh
(( $#words ))                 # number of elements
print -rl -- "${words[@]}"    # one argument per element
print -r -- "${(j:,:)words}"  # explicit join
words+=("$value")
```

Do not globally enable `KSH_ARRAYS` to make imported Bash habits work; it changes subscripting and expansion throughout the caller.

## Preserve boundaries

In native mode, scalar expansion does not automatically split. Convert once at the boundary:

```zsh
lines=("${(@f)text}")          # newline split, retain array nature
fields=("${(@s.:.)record}")   # literal ':' split
argv=(command --flag "$value")
"${argv[@]}"
```

`(f)` is shorthand for splitting on newlines. The `(@)` flag inside quotes preserves one word per array element and also preserves empty fields when combined with `(s)`.

Never serialize an argv as a space-delimited scalar. If textual transport is unavoidable, use a reversible format and decode deliberately.

## Associative arrays

```zsh
local -A color=(ok green fail red)
(( $+color[$key] ))            # key exists, even if value is empty
value=$color[$key]
keys=("${(@k)color}")
values=("${(@v)color}")
for key value in "${(@kv)color}"; do
  ...
done
unset "color[$key]"            # quote dynamic subscripts
```

Associative order is not a stable API. Sort explicitly when output must be deterministic: `${(ok)assoc}` for ordered keys or build pairs and define the ordering rule.

## Subscript search is an algorithm

Zsh subscripts can search without external loops:

```zsh
idx=${array[(I)$needle]}       # index of last exact/pattern match form
idx=${array[(i)$needle]}       # index search; inspect case choice
matches=("${(@M)array:#pattern}")
rest=("${array:#pattern}")
```

`(r)`/`(R)` select values matching a pattern; `(i)`/`(I)` return indices. Uppercase variants generally choose the last or all matching form depending on context. For uncommon combinations, prove behavior with a tiny test instead of guessing.

The `${+name}` family tests definition without conflating unset and empty:

```zsh
(( ${+parameters[feature]} ))
(( ${+commands[rg]} ))
(( ${+widgets[my-widget]} ))
```

## Tied and unique arrays

`typeset -T SCALAR array separator` ties a scalar view to an array. Zsh already ties `PATH` to `path`, `FPATH` to `fpath`, and similar specials. Prefer the array side for edits:

```zsh
typeset -U path
path=("$HOME/bin" $path)
```

The `-U` attribute removes later duplicates, so putting preferred entries first is significant. Localizing a special tied parameter preserves its special behavior, which is useful for temporary `path`/`fpath` overlays.

## Indirection

On stable 5.9/5.9.2, `${(P)name}` is the principal native indirection mechanism:

```zsh
local target=reply
local reply=value
print -r -- "${(P)target}"
```

Parameter names are syntax. Validate untrusted names before indirection:

```zsh
setopt localoptions extendedglob
[[ $target == [A-Za-z_][A-Za-z0-9_]# ]] || return 2
```

Named references exist on the post-5.9 development line, not in stable 5.9.2; see the version reference.

## Hidden and special parameters

`typeset -h` suppresses the special behavior of a special parameter when shadowed/localized; it is not a visibility flag. `typeset -H` suppresses a value in ordinary `typeset` listings, but explicit naming/pattern access can still reveal it. Neither is secret storage.

Useful introspection tables from `zsh/parameter` include `parameters`, `commands`, `functions`, `aliases`, `widgets`, `jobstates`, `options`, and `modules`. Load the module if necessary and use these tables to reason about the live shell without parsing human-readable output.

Search terms: `typeset -T`, tied parameters, expansion flag `@`, associative key existence, subscript flags, `parameters` hash.
