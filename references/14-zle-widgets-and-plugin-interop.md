# ZLE widgets and plugin interoperability

Use this section for line-editor widgets, keymaps, highlighting, descriptor watchers, and coexistence with autosuggestions/syntax highlighting.

## Widget anatomy

```zsh
acme::accept_path() {
  emulate -L zsh
  LBUFFER+="${(q)selected}"
}
zle -N acme-accept-path acme::accept_path
bindkey -M emacs '^X^P' acme-accept-path
bindkey -M viins '^X^P' acme-accept-path
```

Core mutable parameters include `BUFFER`, `LBUFFER`, `RBUFFER`, `CURSOR`, `MARK`, `region_highlight`, `POSTDISPLAY`, and `KEYMAP`. Character offsets are not necessarily byte offsets under `MULTIBYTE`.

Quote inserted shell words with `(q)` when the widget inserts one argument. If it inserts syntax intentionally, build and document that syntax rather than applying blanket quoting.

## Call original widgets correctly

Builtins can be invoked as `.widget`. User and completion widgets require different registration forms. The `$widgets` associative table classifies entries as `builtin`, `user:function`, or `completion:widget:function`.

If wrapping is unavoidable, snapshot according to that type and pass `-- "$@"`. Do not assume `$WIDGET` is always trustworthy: other plugins may invoke a widget without `zle ... -w`.

Prefer hook facilities over wrapping:

```zsh
autoload -Uz add-zle-hook-widget
add-zle-hook-widget zle-line-pre-redraw acme::redraw
add-zle-hook-widget zle-line-finish acme::finish
```

Hook order is registration order. A hook that mutates `BUFFER` should run before a highlighter that paints it. Modern zsh-syntax-highlighting therefore asks to be sourced after other redraw hooks that change the line.

## Highlight without stealing ownership

Append entries to `region_highlight`; do not replace the entire array. Zsh 5.9 supports optional `memo=` metadata, which lets a component identify and replace its own regions. Respect regions from other plugins.

Styles use ZLE highlight syntax (`fg=`, `bg=`, `bold`, `underline`, etc.). New development-line layering/opacity/highlight groups are not stable 5.9.2 APIs.

Limit expensive highlighting for very long buffers and avoid filesystem/network probes on each keystroke. zsh-syntax-highlighting supports a maximum buffer length and slow-path blacklists; the architectural lesson is to bound work at the redraw boundary.

## Keymaps are references

`main` is often an alias to `emacs` or `viins`; rebinding only `main` can be lost when the alias changes. Bind explicit maps your plugin supports. Do not reset all keymaps or run `bindkey -e`/`bindkey -v` inside a plugin.

When temporarily switching maps, store `bindkey -lL main` in a lexically parsed array and restore it. Bracketed paste and menu-select use their own widget/keymap behavior; test both.

## Descriptor handlers

`zle -F fd handler` runs when the descriptor becomes ready. The callback gets `fd` and possibly an error condition. On every terminal path:

1. read all complete available state without blocking;
2. unregister with `zle -F fd`;
3. close `exec {fd}<&-` or `>&-`;
4. update only owned global state;
5. repaint only when necessary.

Leaving a watcher registered for a reused descriptor can call a handler on unrelated user I/O—one of the nastiest interactive plugin bugs.

## Completion widget interop

`compinit` redefines completion widgets, so it must run after completion functions are discoverable and before plugins that wrap those widgets. On Zsh versions where highlighting/autosuggestions wrap all widgets, they must be initialized after custom widgets. On current hook-based versions, registration order still matters.

Avoid load-order folklore in new plugins: expose a setup function, use official hooks, detect required functions/modules, and make setup idempotent.

## Test in a PTY

Assert:

- buffer/cursor after the key sequence;
- emacs, vi insert/command, and menu-select maps as applicable;
- multibyte and combining characters;
- paste, history search, completion, accept-line, Ctrl-C;
- coexistence with autosuggestions and syntax highlighting in both source orders;
- teardown and descriptor reuse.

Search terms: user-defined widget, `$widgets`, `add-zle-hook-widget`, `region_highlight`, `zle -F`, keymap alias, plugin load order.
