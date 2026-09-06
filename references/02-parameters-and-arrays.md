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

Indexed arrays are one-based in native mode. `$array` means all elements, like `$array[*]`; unquoted expansion drops empty elements, and `"$array"` joins elements. `"${array[@]}"` preserves individual elements, including empties. `KSH_ARRAYS` changes both indexing and unsubscripted expansion. Use:

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
idx=${array[(Ie)$needle]}      # last literal match; 0 if absent
idx=${array[(ie)$needle]}      # first literal match; $#array+1 if absent
matches=("${(@M)array:#pattern}")
rest=("${(@)array:#pattern}")
```

For indexed arrays, `(r)`/`(R)` select first/last matching values; `(i)`/`(I)` return first/last matching indices. Add subscript flag `e` for literal matching. Without `e`, even `$needle` can be a pattern here. Use `(( ${array[(Ie)$needle]} ))` for literal membership; the forward miss sentinel is nonzero, so `(i)` alone is not a boolean membership test. Associative `(R)` returns all matching values and `(I)` all matching keys, in unspecified order. Associative `(k)`/`(K)` instead treat stored keys as patterns matching the supplied value: useful for dispatch, but overlapping patterns require explicit precedence.

## Sets, pairs, and structural edits

```zsh
local -a wanted=('one file' '' '*.c' 'one file') done=('*.c')
local -a pending common
pending=("${(@)wanted:|done}")  # literal difference; RHS is an array NAME
common=("${(@)wanted:*done}")   # literal intersection
```

These retain left-hand order and duplicates; they are membership filters, not mathematical sets. Use `(@u)` for first-occurrence uniqueness when appropriate. This avoids turning names containing `*` or `[` into patterns.

Use `${(@)keys:^values}` to interleave paired arrays; `:^` truncates to the shorter input, while `:^^` cycles the shorter to the longer length. Validate equal lengths when constructing an association so truncation cannot silently lose data. Keep `(kv)` associations paired through iteration; sorting a flat key/value sequence corrupts the relation. For deterministic records, sort keys and look up each value.

Indexed array range assignment splices: `items[2,3]=(replacement ...)`; `items[2]=()` deletes and shifts later elements. Associations have no positional order or nested array values. For structured records, use parallel arrays with an explicit index or a deliberately encoded record format.

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

Useful introspection tables from `zsh/parameter` include `parameters`, `commands`, `functions`, `aliases`, `jobstates`, `options`, and `modules`. `widgets` and `keymaps` come from `zsh/zleparameter`. Load the owning module if necessary. Avoid common special names (`path`, `commands`, `options`, `status`) for ordinary scratch variables: they can alter the shell or reject assignment.

Search terms: `typeset -T`, tied parameters, expansion flag `@`, associative key existence, subscript flags, `parameters` hash.
