# Portability and Bash migration

Use this section when converting Bash to Zsh, reviewing mixed-shell code, or choosing between native elegance and a portable contract.

## Decide first: native or portable

If a script must run in POSIX `sh` or Bash, keep its shebang and syntax. Do not run a Bash script with `zsh script`; the right shell is selected by the shebang. A Zsh skill should improve Zsh targets, not silently narrow portability.

If native Zsh is accepted, use a Zsh shebang:

```zsh
#!/usr/bin/env zsh
emulate -LR zsh
```

`env -S` with multiple interpreter arguments is not universally portable. Put option setup in the body.

## The largest semantic differences

### Word splitting and globbing

Bash unquoted expansion often splits and globs. Native Zsh ordinary parameter expansion does neither. This Bash pattern:

```bash
args="--flag value"
command $args
```

should become a Zsh array, not `${=args}` by reflex:

```zsh
local -a args=(--flag value)
command "${args[@]}"
```

Use `${=scalar}` only for an API that explicitly accepts a shell-like word list.

### Arrays

Zsh indexed arrays are one-based and `$array` means element 1. Associative syntax and key iteration differ. Avoid `KSH_ARRAYS` unless emulating ksh is the whole execution contract.

### No-match globs

Native Zsh raises `nomatch` by default. Bash commonly passes the literal pattern unless `nullglob`/`failglob` is set. Use `(N)` for optional Zsh globs; preserve default failure for likely mistakes.

### `read`

Bash `read -a`, `-p`, and `mapfile` idioms do not map directly. Zsh `read` supports `-A` for arrays, `-u` descriptors, `-k` keys, and parameter-name/prompt syntax. Prefer a plain `IFS= read -r` loop when portable logic is enough.

### Regex captures

Zsh `[[ text =~ regex ]]` normally fills `MATCH`, `match`, and position arrays. `setopt BASH_REMATCH` changes it to Bash-like storage. Localize the option in compatibility functions rather than changing the whole shell.

### Process substitution and multios

Both shells have `<(...)`/`>(...)`, but Zsh also has `=(...)` and default `MULTIOS`. `command >file | next` has different output routing in native Zsh. Audit every multiple redirection/pipeline during migration.

### Pattern language

Zsh's `EXTENDED_GLOB`, qualifiers, `~` exclusion, numeric ranges, and `(#...)` flags are not Bash extglob. Rewrite patterns semantically; do not mechanically replace `shopt -s extglob`.

### Completion and line editing

Bash `complete`/`compgen` can be enabled through `bashcompinit`, but a native completion should use compsys. Readline bindings do not directly become ZLE widgets/keymaps.

## Compatibility modes

`emulate -L sh` or invoking Zsh as `sh` changes many options, but Zsh is not a drop-in verifier for every shell's extensions. Use the actual target shells in CI.

`SH_WORD_SPLIT`, `KSH_ARRAYS`, `NO_NOMATCH`, `IGNORE_BRACES`, `POSIX_BUILTINS`, and related flags can imitate pieces of other shells while disabling native strengths. Prefer a contained emulation function or whole-script mode, never a random global compatibility cocktail in `.zshrc`.

## Command substitution and status

Both ecosystems have the declaration/status trap:

```zsh
local value
value=$(might_fail) || return
```

Do not assume Bash's `set -e` folklore translates. Zsh has `ERR_RETURN`, `ERR_EXIT`, `always`, and different trap scoping; choose an explicit model and test it.

## Migration procedure

1. Run the original tests under Bash.
2. Replace stringly argv with arrays.
3. Audit all unquoted expansions and globs.
4. Audit array indices/whole-array uses.
5. Audit redirection and pipeline waiting.
6. Replace `shopt`, `[[ regex ]]` captures, `mapfile`, `read`, completion, and prompt code intentionally.
7. Add hostile filename/empty/no-match fixtures.
8. Run both shells only if both remain supported.

Search terms: `SH_WORD_SPLIT`, `KSH_ARRAYS`, Bash migration, `bashcompinit`, no-match, multios, emulation.
