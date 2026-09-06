# Patterns and glob qualifiers

Use this section for recursive selection, filtering, ordering, fuzzy matching, safe no-match handling, and replacing `find`/`sort` pipelines with filename generation.

## Separate four concerns

A native file-selection expression can encode:

1. traversal: `**/` recursively;
2. name pattern: `*.log`, exclusions with `~`, numeric ranges `<1-20>`;
3. metadata filter: qualifiers such as `.` regular file, `/` directory, `@` symlink;
4. ordering/limit/modification: `om[1]`, `OL[1,10]`, `:h`, or an `e` predicate.

Example:

```zsh
local -a newest
newest=( **/*.log(N.om[1,10]) )
```

This means recursive `.log` matches, null on no match, regular files, newest first, first ten. Explain expressions at this density.

## Localize match behavior

Use qualifier flags instead of changing global options when possible:

- `N`: null glob for this pattern;
- `D`: include dotfiles;
- `.`: regular files;
- `/`: directories;
- `@`: symbolic links; `-` toggles following symlink targets for later qualifiers;
- `*`: executable plain files;
- `F`: non-empty directories;
- `L`, `m`, `a`, `c`: size and timestamps with units;
- `u`, `g`: owner/group;
- `o...`, `O...`: ascending/descending sort;
- `[begin,end]`: result slice;
- `Ylimit`: short-circuit traversal after a maximum candidate count.

Prefer explicit `(#q...)` qualifier syntax when parentheses could be read as part of the pattern:

```zsh
setopt localoptions extendedglob
files=( **/*.zsh(#qN.om[1,5]) )
```

## Pattern operators that remove helper processes

With `EXTENDED_GLOB`:

- `^pattern` negates;
- `pat1~pat2` subtracts matches;
- `(#i)` and `(#I)` turn case-insensitive matching on/off locally;
- `(#b)` enables backreferences into `$match`, `$mbegin`, `$mend`;
- `(#aN)` allows up to N errors for approximate matching;
- `<x-y>` matches numeric ranges;
- `##` and `#` mean one-or-more and zero-or-more of the preceding atom.

Keep parentheses balanced and quote a literal pattern passed through a command argument. Inside `[[ string = pattern ]]`, filename generation does not occur, but the right side is still a Zsh pattern.

## Executable predicates and transformations

The `e` qualifier runs code with the candidate in `REPLY`. It can filter and can replace output through `REPLY`/`reply`:

```zsh
recent_without_peer=( *.c(N.e:'[[ ! -e $REPLY:r.o ]]':) )
```

For reusable logic, prefer the `+function` form over a quoted inline program. Keep the predicate side-effect free; it runs once per candidate and can become a performance or injection hazard.

The `+` form reads an alphanumeric/underscore function name, so use `_acme_needs_build`, not a `::`-separated name. A predicate's `REPLY` is an output parameter: do not localize it if you intend to transform the result. A `reply` array can expand one candidate into several output words; unset it on paths that should return only `REPLY`.

```zsh
_acme_needs_build() {
  # Called by filename generation; REPLY is the source pathname.
  [[ ! -e ${REPLY:r}.o || $REPLY -nt ${REPLY:r}.o ]]
}
sources=( "$root"/**/*.c(N.+_acme_needs_build) )
```

This is incremental selection by peer metadata, not a general dependency tracker. Glob sort code `oe`/`o+` computes a sort key through `REPLY` once per candidate; use that when the ordering key needs native metadata or a derived name. Do not spawn an external command per candidate merely to save a visible loop.

Qualifiers in one list are ANDed; comma-separated groups are alternatives. `^` and `-` toggle the interpretation of subsequent qualifiers, not just the next character. `(^F)` includes non-directories; `(/^F)` specifically selects empty directories. Permission-bit qualifiers test mode bits, not effective access through ACLs.

## No-match behavior is a design choice

Default `NOMATCH` catches mistakes. Do not globally set `NO_NOMATCH` or `NULL_GLOB` in a library. Use `(N)` on optional globs and assert non-empty before destructive commands:

```zsh
local -a targets=( ./cache/**/*.tmp(N.) )
(( $#targets )) || return 0
print -rl -- "${targets[@]}"   # dry run
# command rm -- "${targets[@]}"
```

Always anchor destructive globs to an explicit directory and use `--`.

## Ordering is not `ls`

Do not parse `ls`. Glob qualifiers sort native filenames without lossy text conversion:

```zsh
largest=( **/*(N.OL[1,10]) )
oldest=( *(.Om[1]) )
```

Ordering keys include name, size, link count, timestamps, and execution order expressions. Verify uppercase/lowercase direction in a fixture when correctness matters.

## Recursive scale

Globbing materializes matches as arguments. For huge trees, use `zargs` to batch or an external traversal API that streams. `zsh/files` builtins avoid exec overhead and external argument-size limits, but still require memory for every argument and careful control of destructive scope.

`Y10` stops at ten traversal matches; `om[1,10]` sorts all matches before choosing the newest ten. Combining `Y10` with sorting only sorts the early subset, and cannot produce a global top ten. `(N[1])`/`Y1` are useful for existence tests when ordering is irrelevant. `**/` does not follow directory symlinks; `***/` does. Excluding matching result paths with `~` does not in general prune traversal into those directories.

For collision-checked renaming, prefer `autoload -Uz zmv` and a quoted mapping such as `zmv -n '(*).draft' '$1.txt'`. `zmv` checks the mapping for conflicts before executing; the operation is still not atomic if later moves fail. In a programmatically generated destination, quote literal fragments for the destination's evaluation context. For batches, `zargs -r -- "${files[@]}" -- command -- ...` is an argument-list API, not a line parser; it avoids `exec` size limits, not the memory needed to collect files.

Search terms: glob qualifiers, `BARE_GLOB_QUAL`, `EXTENDED_GLOB`, approximate matching, qualifier `e`, `Y` short circuit, `zargs`, `zmv`.
