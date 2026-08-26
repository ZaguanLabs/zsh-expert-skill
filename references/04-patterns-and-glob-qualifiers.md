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

Globbing materializes matches as arguments. For huge trees, use `zargs` to batch or an external traversal API that streams. `zsh/files` builtins avoid exec overhead but do not remove argument-count and destructive-scope concerns.

Search terms: glob qualifiers, `BARE_GLOB_QUAL`, `EXTENDED_GLOB`, approximate matching, qualifier `e`, `Y` short circuit, `zargs`, `zmv`.
