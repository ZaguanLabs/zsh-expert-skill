# History, directories, and shell hooks

Use this section for history policy, multiple sessions, directory state, `chpwd`, `preexec`, `precmd`, and per-directory behavior.

## History options form a consistency model

Choose deliberately among:

- `APPEND_HISTORY`: append on shell exit;
- `INC_APPEND_HISTORY`: append each command incrementally;
- `INC_APPEND_HISTORY_TIME`: include duration but writes after command finishes;
- `SHARE_HISTORY`: import/export across sessions with extended timestamps;
- duplicate controls (`HIST_IGNORE_DUPS`, `HIST_IGNORE_ALL_DUPS`, `HIST_SAVE_NO_DUPS`, `HIST_EXPIRE_DUPS_FIRST`);
- privacy controls (`HIST_IGNORE_SPACE`, `HIST_NO_STORE`, `HIST_REDUCE_BLANKS`).

Some incremental/share options are mutually exclusive or change ordering semantics. `SHARE_HISTORY` interleaves sessions by timestamp and can surprise users who expect each shell's local sequence. State the chosen behavior rather than enabling every plausible option.

Set `HISTSIZE` larger than `SAVEHIST` if duplicate expiry needs room to prefer old duplicates. Protect the history file permissions.

## `zshaddhistory` is a policy hook

A `zshaddhistory` function/hook can reject or alter saving. Its status has special meaning; verify the exact contract before filtering. Avoid expensive network/repository work in this hook—it runs on every accepted command.

Status 1 rejects saving (the line remains temporarily available for editing); status 2 retains the line in memory but excludes it from the history file. Use `fc -p -a` for a function-local history context that restores automatically, useful in a `vared`-based tool with its own history. History privacy options are retention policies, not secret erasure guarantees.

Never log secret-bearing commands merely because the framework default would. Provide a leading-space privacy path and consider patterns for known credential tools, while recognizing pattern filters are not a complete secret detector.

## Register hooks compositionally

```zsh
autoload -Uz add-zsh-hook
add-zsh-hook chpwd acme::directory_changed
add-zsh-hook preexec acme::before_command
add-zsh-hook precmd acme::before_prompt
add-zsh-hook zshexit acme::shutdown
```

Hook functions run in registration order. Preserve incoming `$?` immediately in `precmd`; `preexec` receives forms of the command line with different expansion/history properties, so choose the right argument for display versus analysis.

A nonzero shell hook status can stop later hooks; ordinary successful observers should explicitly return 0 rather than accidentally returning the last false test. Preserve specialized status protocols such as `zshaddhistory`. `precmd` runs before a new prompt, not each redraw; `periodic` runs at prompt opportunities, not as a background timer.

Remove hooks with `add-zsh-hook -d`; never overwrite the singleton `precmd()` function in a plugin.

## Directory stacks and named directories

Zsh's `AUTO_PUSHD`, `PUSHD_IGNORE_DUPS`, `PUSHD_SILENT`, `PUSHD_TO_HOME`, and `DIRSTACKSIZE` define navigation semantics. Frameworks often configure these. A plugin should not change them globally unless navigation policy is its purpose.

Named directories (`hash -d name=path`, directory parameters) participate in `~name` expansion and prompt shortening. The `cdr` contributed function and `zsh_directory_name` hook enable recent/contextual directory naming without replacing `cd`.

Dynamic directory naming is a bidirectional API: an `n` request maps a logical name to a path; `d` supplies a shortened name and matched prefix length; `c` supplies completion. Implement only the supported modes and return failure for other names. `zsh_directory_name_generic` composes hierarchical mappings such as workspace/project/source through caller-visible associations. This unifies navigation, `%~` rendering, and completion without ad hoc aliases. `cdr` persists recent directories separately from the `pushd` stack.

## Per-directory activation is code execution

Do not automatically source `.zshrc`, `.env`, or arbitrary project files on `chpwd`. Safer design:

1. canonicalize the directory;
2. maintain explicit allow and deny lists;
3. prompt on a tty before first trust;
4. validate size/type/syntax;
5. parse a restricted data grammar where possible;
6. block environment variables that redirect future code loading or native injection;
7. unload previous directory state when leaving.

Current OMZ's dotenv plugin uses per-directory allow/deny lists, syntax checks, a 10 MiB cap, bounded FIFO reads, restricted assignment parsing, and a blocklist for execution-sensitive variables. Reuse these invariants, not its private parser as a general security proof.

## Avoid hook storms

Async/deferred changes that call `chpwd`/`precmd` hooks can recursively trigger other plugins. If manually invoking hook arrays, document why and guard reentrancy. Prefer updating the owned subsystem directly.

Search terms: history options, `zshaddhistory`, `add-zsh-hook`, `chpwd`, directory allowlist, named directories, `cdr`.
