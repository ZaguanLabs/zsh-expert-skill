# Exceptional native designs

Use this section as a design index when the request benefits from Zsh's unusual strengths. Load the linked topic before implementing. These are architectural recipes, not copy-paste one-liners.

## Replace a `find | sort | head` pipeline

Use recursive globbing plus metadata qualifiers, native sort, and a slice:

```zsh
newest=( "$root"/**/*.log(N.om[1,10]) )
```

This preserves arbitrary filenames and makes selection declarative. For millions of files, use a streaming traversal instead. Read [04-patterns-and-glob-qualifiers.md](04-patterns-and-glob-qualifiers.md).

## Transactional file update with native locking

Use `zsystem flock` for cooperation, create a temporary file in the target directory, write/validate it, then rename. Bind cleanup to `always`; close the lock FD on every path. Read [06-control-flow-errors-and-traps.md](06-control-flow-errors-and-traps.md) and [09-native-modules.md](09-native-modules.md).

## Real-file process substitution

When a consumer requires seekable input, use `=(producer)` rather than managing a temporary file manually. Bind its lifetime to an anonymous function and never disown the responsible shell. Read [07-redirection-fds-and-process-substitution.md](07-redirection-fds-and-process-substitution.md).

## Stateful async prompt without terminal races

Issue cancellable jobs, send the actual child PID over an allocated FD, register `zle -F`, tag requests with directory/generation, and repaint only from the parent when the newest result arrives. This pattern is distilled from zsh-async, zsh-autosuggestions, and current Oh My Zsh. Read [10-async-concurrency-and-jobs.md](10-async-concurrency-and-jobs.md) and [15-prompts-vcs-and-terminal.md](15-prompts-vcs-and-terminal.md).

## A completion that behaves like a small parser

Model option exclusion, option arguments, subcommand states, contextual tags, descriptions, and cached external data with `_arguments -C`, `_describe`, `_alternative`, and `_call_program`. This produces help-aware interactive grammar rather than word lists. Read [13-completion-authoring.md](13-completion-authoring.md).

## Plugin configuration without global-variable sprawl

Expose a namespaced `zstyle` tree with boolean, scalar, and array styles. Pair it with idempotent setup and unload functions. This scales from standalone plugins to OMZ custom plugins. Read [16-plugin-engineering.md](16-plugin-engineering.md).

## Safe directory-local environment activation

Use canonical per-directory trust decisions, persistent allow/deny lists, a bounded restricted assignment parser, protected-variable policy, syntax/size checks, and explicit unload on directory exit. Never blindly `source .env`. Read [17-history-directories-and-hooks.md](17-history-directories-and-hooks.md) and [19-security.md](19-security.md).

## Parse shell-quoted data without executing it

For trusted Zsh-generated serialized words, tokenize with `(z)` and remove one quote layer with `(@Q)`. This recovers array boundaries without `eval`. For untrusted formats, define a smaller grammar or use JSON/NUL. Read [08-input-parsing-and-serialization.md](08-input-parsing-and-serialization.md).

## Context-sensitive path transformation

Use modifiers (`:A`, `:h`, `:t`, `:r`, `:e`) and arrays to derive paths without `dirname`/`basename` subprocesses. Keep canonicalization separate from security containment. Read [03-expansion-algebra.md](03-expansion-algebra.md).

## Metadata-driven file batches

Select files by type, ownership, permission, size, and age in one glob qualifier expression; batch with `zargs` when argv may overflow. Start destructive operations with `print -rl --` and an explicit rooted pattern. Read [04-patterns-and-glob-qualifiers.md](04-patterns-and-glob-qualifiers.md).

## Multi-component ZLE highlighting

Register a redraw hook, append only owned `region_highlight` entries, use memo metadata where stable, cap work for long buffers, and coexist with syntax highlighting/autosuggestions. Read [14-zle-widgets-and-plugin-interop.md](14-zle-widgets-and-plugin-interop.md).

## Runtime introspection without text parsing

Use `zsh/parameter` tables to detect commands, functions, widgets, aliases, options, modules, and jobs. This enables self-diagnosing plugins and compatibility checks without parsing `which`, `bindkey`, or `jobs`. Read [02-parameters-and-arrays.md](02-parameters-and-arrays.md) and [09-native-modules.md](09-native-modules.md).

## Completion dump as a content-addressed cache

Key discovery state by Zsh version, host, framework revision, and ordered `fpath`; rebuild and compile under a lock when metadata changes. Preserve compaudit. This is an expert lesson from OMZ's current loader. Read [11-startup-files-and-oh-my-zsh.md](11-startup-files-and-oh-my-zsh.md).

## Dynamic-scope hook protocol

When a family of hooks intentionally shares structured state, declare caller locals such as `hook_com`, `user_data`, and `ret`, then call prefixed hooks in order with a documented stop/status rule. This is how `vcs_info` achieves extensibility. Use dynamic scope only as an explicit protocol. Read [05-functions-scope-and-options.md](05-functions-scope-and-options.md).

## User-input-aware background maintenance

Before printing/updating during startup, temporarily make tty input noncanonical, poll fd 0 with `zselect -t 0`, and restore `stty` in `always`. If the user already typed, defer visible output to `precmd`. Oh My Zsh uses this to avoid update prompts overwriting input. Read [06-control-flow-errors-and-traps.md](06-control-flow-errors-and-traps.md) and [09-native-modules.md](09-native-modules.md).

## Beautiful-solution test

Adopt an advanced native design only if it improves at least two of: boundary preservation, process/language portability, explicit lifecycle, composability, observable latency, or testability. If it merely saves characters, keep the straightforward code.
