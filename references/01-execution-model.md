# Execution model

Use this section for parsing, command lookup, subshells, pipelines, status, and context-sensitive syntax.

## Think in parse phases

Zsh parses aliases before executing commands. Reserved words and assignment syntax are recognized by the parser, not by ordinary command dispatch. Expansion then proceeds in a defined order; filename generation is late. Redirections are applied left to right.

Consequences:

- An alias cannot safely behave like a function with arguments. Use a function.
- Quoting a pattern suppresses its pattern meaning in `[[ lhs = pattern ]]`; quoting ordinary values is still correct.
- A string assembled at runtime does not become shell syntax merely because it contains metacharacters. Avoid `eval`; use arrays for commands and `${~spec}` only when deliberately compiling a pattern.
- `noglob command ...` is a precommand modifier, useful when a command's arguments naturally contain glob syntax.

## Command lookup and command identity

Use the parameter module's tables instead of spawning `which`:

```zsh
(( $+commands[git] ))       # external command is discoverable
(( $+functions[widget] ))   # function exists or is marked for autoload
(( $+aliases[ll] ))
whence -w -- git            # classify
whence -p -- git            # external path only
```

Use `command` to bypass functions and aliases, `builtin` to require a builtin, and an absolute path only when path identity is itself part of the contract. `command -p` requests a standard utility path and is valuable inside libraries that must not inherit a poisoned `PATH`.

## Subshell boundaries

These normally fork or isolate state:

- `( list )` runs in a subshell;
- `$(list)` runs in a subshell and strips trailing newlines;
- process substitution runs helper processes;
- each external pipeline component is a process.

These run in the current shell:

- `{ list; }`;
- a shell function;
- an anonymous function `() { ... } args` with function-local parameters;
- a `while` loop fed by redirection rather than by a pipeline.

Therefore prefer:

```zsh
while IFS= read -r line; do
  rows+=("$line")
done < "$file"
```

over designs that rely on variables changed inside a piped loop.

`$ZSH_SUBSHELL` is a diagnostic counter for forked shell contexts. `zsh_eval_context`/`ZSH_EVAL_CONTEXT` reveals contexts such as `toplevel`, `shfunc`, `file`, `cmdsubst`, `globqual`, and `zle`; use it sparingly for defensive entrypoint checks.

## Status has structure

- `$?`/`$status` is the last status.
- `$pipestatus` preserves every pipeline component's status.
- `setopt PIPE_FAIL` changes a pipeline's aggregate status to the rightmost nonzero component.
- `!` negates the aggregate status.
- `if`, `while`, `until`, `&&`, and `||` are control contexts; `ERR_EXIT` has exceptions around them.

Capture status before another command overwrites it:

```zsh
command expensive
local -i rc=$?
(( rc == 0 )) || return rc
```

Do not use `local result=$(command)` when failure matters: the declaration can mask the substitution's status. Use:

```zsh
local result
result=$(command) || return
```

## Native syntax worth using

- `for item ("$@") { ... }` and `repeat n do ... done` are clear in native-only code.
- `[[ ... ]]` avoids pathname generation and supports Zsh patterns.
- Arithmetic commands `(( ... ))` return false for numeric zero.
- `=command` expands to a command path during filename expansion; use it for interactive convenience, not opaque library code.
- `<<<` is a here-string and appends a newline; account for that in byte-sensitive code.

## Avoid accidental semantic mode changes

The executable name and `emulate` mode can change defaults. Reusable Zsh code should establish native behavior with `emulate -L zsh`; portability code should explicitly choose `emulate -L sh` and avoid native syntax rather than mixing modes.

Search terms: `zsh_eval_context`, `ZSH_SUBSHELL`, precommand modifier, command lookup, pipeline status, reserved word.
