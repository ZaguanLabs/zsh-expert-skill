# Completion configuration

Use this section for user-facing compsys behavior, `zstyle` contexts, matcher performance, caching, grouping, and debugging.

## Mental model

Completion builds a context with fields like completer, command, argument position/function, and tag. Tags say what kind of matches exist; styles say how a context should behave.

Start broad, then add the narrowest exception:

```zsh
zstyle ':completion:*' verbose yes
zstyle ':completion:*:*:kill:*:processes' verbose no
```

Avoid `zstyle '*' ...` unless a style is intentionally global outside completion too.

## Initialize once

```zsh
autoload -Uz compinit
compinit
```

Ensure every completion directory is in `fpath` first. Load `zsh/complist` before `compinit` if `menu-select` must be redefined by initialization. In Oh My Zsh, OMZ owns this lifecycle; configure styles rather than rerunning it.

## Matcher lists cost full completion passes

Each element of `matcher-list` can rerun the entire completion. One to three entries is the practical range. Put multiple matcher specifications in one string when they should apply in the same pass.

Example staged matching:

```zsh
zstyle ':completion:*' matcher-list \
  '' \
  'm:{a-zA-Z}={A-Za-z}' \
  'm:{a-zA-Z}={A-Za-z} r:|[-_./]=* r:|=*'
```

Do not enable approximate correction first; it is expensive. Use it only after ordinary completion fails or on a repeated attempt.

## Group and order semantically

```zsh
zstyle ':completion:*' group-name ''
zstyle ':completion:*:*:-command-:*:*' tag-order \
  'commands:-external:external commands' \
  'functions:-functions:shell functions' \
  'builtins:-builtins:builtins'
```

Use tag-specific styles for local directories, process lists, ignored patterns, descriptions, warnings, and menu thresholds. Preserve discoverability: aggressive ignored patterns should still allow `single-ignored show` or a fallback tag order.

## Cache expensive producers

```zsh
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path "$cache_dir"
```

Caching only affects completion functions that use `_store_cache`/`_retrieve_cache`. Authors should supply a `cache-policy` that checks age and relevant source mtimes/version, not merely a permanent file. Cache directories must be private and results from privileged contexts must not be shared with unprivileged ones.

## Useful diagnostics

- `Ctrl-X h` (`_complete_help`) shows tags/context at the cursor.
- `_complete_debug` captures a traced completion attempt.
- `compaudit` reports insecure completion paths.
- `whence -v _function` and `$^fpath/_function(N)` locate definitions.
- `zstyle -L ':completion:*'` prints reproducible style definitions.
- `compinit -w` on 5.9 explains why the dump is rebuilt or skipped.

When a style seems ignored, inspect the live context rather than adding more wildcards.

## Bash completion compatibility

`bashcompinit` defines compatibility `complete`/`compgen`; it does not turn Bash completions into native compsys designs. Use it as a fallback when an upstream project ships only Bash completion. Prefer native `_arguments` completion when maintaining the integration: it supports tags, descriptions, context, caching, and richer state.

## Oh My Zsh defaults are policy

OMZ enables menu selection, in-word completion, completion caches, case/partial matching, filtered users, and bash completion compatibility. These are reasonable framework defaults, not universal truths. Measure matcher cost and preserve the user's explicit styles in plugins.

Search terms: completion context, tags and styles, `matcher-list`, `tag-order`, `_complete_help`, `_complete_debug`, completion cache.
