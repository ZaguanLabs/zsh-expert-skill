# Startup files and Oh My Zsh

Use this section for login/interactive startup, `ZDOTDIR`, `fpath`, compinit ordering, OMZ customizations, and cache invalidation.

## Startup order

Zsh reads, subject to `RCS`/`GLOBAL_RCS`:

1. `/etc/zshenv`, then `$ZDOTDIR/.zshenv` for every invocation;
2. `/etc/zprofile`, then `.zprofile` for login shells;
3. `/etc/zshrc`, then `.zshrc` for interactive shells;
4. `/etc/zlogin`, then `.zlogin` for login shells;
5. `.zlogout`, then global `zlogout` when a login shell exits normally.

If `ZDOTDIR` is unset, `$HOME` is used instead. `/etc/zshenv` cannot be bypassed; keep it tiny. `zsh -f` skips subsequent rc files, and is the foundation for isolated tests.

Put only universally required environment in `.zshenv`; no output, tty access, aliases, completion, or expensive commands. Put interactive options, widgets, prompts, and frameworks in `.zshrc`. Use `.zprofile` for login environment setup that must precede `.zshrc`; use `.zlogin` for post-interactive login actions, not duplicated environment mutations.

## Oh My Zsh load phases

Current OMZ roughly:

1. establishes `$ZSH`, `$ZSH_CUSTOM`, and cache directories;
2. adds core/custom function and completion paths;
3. adds each enabled plugin directory to `fpath` before completion initialization;
4. runs `compinit` with a version/host-specific dump and security handling;
5. sources core libraries, enabled plugins, custom `*.zsh`, then the theme;
6. applies final completion colors.

For user customization:

- set OMZ variables, `plugins=(...)`, and early `fpath` additions before sourcing `oh-my-zsh.sh`;
- put ordinary overrides after the source line or in `$ZSH_CUSTOM/*.zsh` while understanding its phase;
- do not call `compinit` a second time unless rebuilding the completion lifecycle intentionally;
- a custom plugin's directory is already on `fpath` before its `*.plugin.zsh` is sourced.

## Completion dump correctness

A dump is a cache of discovered completion definitions. Invalidate it when:

- the set/order of `fpath` directories changes;
- a `#compdef` line or function mapping changes;
- the Zsh version changes;
- framework revision changes in a way that affects completion.

OMZ names dumps with host/version and records its revision plus `fpath`, deleting stale dumps when metadata differs. This is more reliable than a time-only check. Compile with `zrecompile` under a lock; never let concurrent shells race on the same `.zwc`.

`compinit -C` skips discovery/security checks when a dump exists. Use it only when an external invalidation and security policy is already trustworthy.

## Completion security

Default `compinit` audits ownership and group/world writability. `-i` excludes insecure entries; `-u` trusts them. Preserve the audit and fix ownership/permissions rather than disabling it.

OMZ's normal path uses `compinit -i` and reports excluded directories. `ZSH_DISABLE_COMPFIX=true` switches to unsafe `-u`; do not recommend it as a generic fix.

## Framework-specific versus native

OMZ variables such as `ZSH_THEME`, `ZSH_CUSTOM`, `ZSH_CACHE_DIR`, `ZSH_COMPDUMP`, `CASE_SENSITIVE`, and `HYPHEN_INSENSITIVE` are framework APIs, not Zsh parameters. Prefer current namespaced `zstyle` settings when OMZ exposes them; old uppercase flags may be compatibility layers.

OMZ's source helper can suppress aliases contributed by selected libs/plugins through `zstyle`. This demonstrates that aliases are ambient parse-time state; plugin code should not depend on user aliases and should minimize new global aliases.

## Diagnosing startup

```zsh
zsh -f                         # no user rc files
zsh -xlic exit                 # broad trace, noisy
ZDOTDIR=$tmp zsh -dfic exit    # isolated interactive config
```

Use `zprof` for sourced-function time and `zsh-bench` for user-visible first prompt/command/input latency. Inspect `functions -t` or targeted `XTRACE`, not a permanent global trace in `.zshrc`.

Search terms: startup files, `ZDOTDIR`, OMZ load order, zcompdump metadata, `compinit -i`, `zrecompile`.
