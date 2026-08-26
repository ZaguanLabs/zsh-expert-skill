# Security

Use this section whenever code handles untrusted text, filenames, repositories, completion paths, local config, terminal escapes, elevated commands, or updates.

## Identify evaluation boundaries

These can turn data into behavior:

- `eval`, `source`, `.`;
- `${(e)value}`;
- `${~pattern}` and active Zsh patterns;
- `PROMPT_SUBST`/`print -P` on dynamic text;
- completion helpers that invoke commands or use `eval` internally;
- aliases (parse-time rewriting);
- directory-local environment/config files;
- terminal control sequences;
- dynamic parameter names with `(P)`;
- generated code passed to `zsh -c`.

Eliminate the boundary when arrays, a restricted grammar, or a direct function call can express the result. If it remains, validate input before it reaches the boundary and document the accepted language.

## Filenames are arbitrary data

Always use arrays, quote each element, and terminate options:

```zsh
local -a files=( "$root"/**/*.tmp(N.) )
(( $#files )) || return 0
command rm -- "${files[@]}"
```

Anchor destructive globs, verify the resolved root is intended, dry-run first, and reject empty/broad roots. Do not parse `ls` or line-delimited `find` for arbitrary names.

Globs can cause argument explosion; use bounded qualifiers, `zargs`, or streaming traversal.

## Completion path integrity

Completion files are sourced code. `compinit` rejects entries not owned by root/current user and group/world-writable directories. Preserve `compaudit`; use `compinit -i` to omit insecure paths and fix permissions. `-u` and `ZSH_DISABLE_COMPFIX=true` explicitly disable protection.

A completion cache is executable Zsh data. Keep its directory user-owned and not writable by others. Invalidation must not switch to an attacker-controlled dump.

## Directory-local trust

Repositories are attacker-controlled inputs. `chpwd`, prompts, and completion fire merely by entering or tab-completing in a directory. Do not source `.envrc`, `.env`, package metadata, Git hooks, or generated completions automatically without an explicit trust model.

If parsing environment assignments, block variables that redirect future execution: `ZDOTDIR`, `ENV`, `BASH_ENV`, `PATH`, loader injection variables, Git execution/config variables, editor/pager hooks, runtime preloads such as `NODE_OPTIONS`, and special exported Zsh parameters. A blocklist is defense in depth; a narrow allowlist grammar is stronger.

## Terminal output is active

Untrusted text containing ESC, BEL, carriage return, backspace, or OSC terminators can alter titles, hyperlinks, clipboard, display, or apparent command output. For diagnostics use `${(V)value}` or sanitize controls. Limit lengths. Never echo attacker-controlled bytes inside OSC sequences.

`%{...%}` only informs prompt width; it does not sanitize the content.

## Updates and remote execution

Never recommend `source <(curl ...)` or `sh -c "$(curl ...)"` as a routine installation pattern. Download, verify provenance/signature or pinned digest where available, inspect, and execute as a separate explicit action.

An updater should check ownership/writability, repository identity, configured remote/branch, clean/local state, common ancestry, and concurrency lock. It should bound network time and leave a recoverable failure state.

## Privilege boundaries

Completion for `sudo` can use different command paths and environment; do not cache privileged results into a shared unprivileged cache. Do not use setuid/setgid assumptions with process substitution paths—some programs close inherited descriptors for security, which is one reason `=(...)` exists.

Avoid running shell code as root merely to update a user's configuration. Validate resolved ownership before writing.

## Secrets

History, xtrace, completion debug logs, process arguments, prompts, and `typeset -p` can expose secrets. Disable/redirect tracing around secret handling, do not embed secrets in argv when an FD/stdin API exists, and make debug output visible-safe and redacted. Hidden parameter attributes are not secret storage.

Search terms: `compaudit`, evaluation flag `(e)`, prompt injection, terminal escape injection, directory local config, updater security, arbitrary filenames.
