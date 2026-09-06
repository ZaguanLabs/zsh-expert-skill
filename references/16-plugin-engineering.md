# Plugin engineering

Use this section for reusable Zsh/Oh My Zsh plugins, configuration APIs, idempotent setup, load order, and uninstall behavior.

## Define the plugin contract

A robust plugin states:

- supported Zsh versions and optional modules/commands;
- entrypoint and whether it may be sourced more than once;
- public functions/widgets/styles;
- global state it owns;
- hooks/watchers/keymaps/completions it registers;
- cleanup/unload behavior;
- Oh My Zsh-specific integration, if any.

Do not require a plugin manager unless its lifecycle is essential. A plain `source` and `fpath` integration should work when practical.

## Entrypoint pattern

Top-level sourced files cannot localize state with `emulate -L` by themselves. Wrap setup in an anonymous function:

```zsh
() {
  emulate -L zsh
  setopt extendedglob
  local plugin_dir=${${(%):-%x}:A:h}
  fpath=("$plugin_dir/functions" $fpath)
  autoload -Uz acme::command
}
```

`${(%):-%x}` identifies the currently sourced file in Zsh; normalize with `:A:h`. Do not rely on `$0` unless following a documented plugin standard and tested across direct source, autoload, and manager contexts.

Use `autoload -Uz` so user aliases cannot alter plugin parse results. Prefix globals/functions. Avoid exporting variables unless child processes are the intended consumer.

## Configure with namespaced `zstyle`

```zsh
zstyle -s ':acme:feature' mode mode || mode=auto
zstyle -t ':acme:feature' enabled || return 0
zstyle -a ':acme:feature' commands commands
```

Styles avoid the flat global parameter namespace and permit context-sensitive behavior. Use `-T` only when unset should mean true; use `-t` when unset should mean false. Document the distinction.

Define the context grammar, not just the style names: for example `:acme:operation:project:backend`. Retrieve using a concrete context; definitions use patterns whose specificity controls precedence, rather than simply the last definition. `zstyle -e` computes `reply` at lookup time, so callers must treat style lookup as user-provided callback code and avoid repeatedly invoking expensive dynamic styles in hot loops. Validate the returned type/value at the configuration boundary.

Current Oh My Zsh increasingly uses contexts such as `:omz:plugins:name`; follow the plugin's existing convention rather than inventing uppercase flags.

## Idempotency and ownership

Before registering, check whether your named hook/widget is already present. Store only handles you own. On unload:

- remove named hooks;
- unregister descriptor watchers before closing FDs;
- stop owned workers/process groups;
- restore wrapped widget registrations if still yours;
- remove only your `region_highlight` entries/state/cache;
- leave user data and unrelated aliases untouched.

Never reset a whole hook array or keymap to remove one entry.

## Completion lifecycle

A plugin directory placed on `fpath` before `compinit` can expose `_name` files with `#compdef`. Oh My Zsh adds enabled plugin directories before it runs `compinit`, then sources `name.plugin.zsh` afterward.

Therefore an OMZ plugin should usually:

- keep declarative completion in `_name`;
- avoid calling `compinit`;
- use `compdef` at source time only for dynamic aliases/wrappers after compinit exists;
- invalidate framework completion caches only when mappings truly change.

## Interoperability

- Use `add-zsh-hook` and `add-zle-hook-widget`.
- Do not assume source order; detect and document a real ordering dependency.
- Do not run `bindkey -e/-v` or replace `PROMPT` without explicit purpose.
- Keep per-keystroke work bounded.
- Avoid deferred loading for anything that changes command availability or key behavior.
- Do not use user aliases internally; prefix `command`/`builtin` where identity matters.
- Make errors quiet during normal startup but discoverable through a debug style/function.

## Update and remote code

A plugin should not self-update silently during shell startup. If it provides update tooling, require clear user policy, bound network time, verify the intended remote/branch, use locks, preserve local changes, and report recoverable state. OMZ's updater checks ownership/writability, tty state, Git repository identity, official remote forms, common ancestry, and an update lock; these are useful design constraints, not a license to copy its updater wholesale.

## Framework boundary

If writing specifically for OMZ, use `$ZSH_CUSTOM`, OMZ's plugin layout, and its existing styles. If writing a general plugin, detect OMZ only for optional integration and keep the core independent.

Search terms: plugin entrypoint `%x`, `zstyle` API, idempotent source, Oh My Zsh plugin lifecycle, unload, plugin standard.
