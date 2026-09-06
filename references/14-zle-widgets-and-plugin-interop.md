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

If wrapping is unavoidable, use `zle -A original owned-saved-name` to retain the widget binding, including completion widgets, then delegate with `zle owned-saved-name -- "$@"`. The `$widgets` type is useful for diagnosis or explicit reconstruction. Restore only if the public binding is still yours and delete only your saved name. Do not assume `$WIDGET` identifies an indirectly invoked widget: `zle ... -w` controls that. Preserve or deliberately override numeric arguments and `LASTWIDGET` behavior.

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

## Edit shell arguments as structured text

Use `split-shell-arguments` when a widget must preserve the line's spelling and spacing. It returns alternating whitespace and argument segments in caller-local `reply`, with cursor location in `REPLY` and `REPLY2`; joining with an empty separator reconstructs the original buffer. It preserves quote characters. This supports source-preserving edits that a `(z)`/`(Q)` round trip would reformat.

Use `modify-current-argument` for transforming the argument at the cursor. Its function form receives the current argument and returns replacement text in `REPLY`; its expression form evaluates code containing `$ARG`. Prefer a named helper when data or multiple stages are involved. Inspect its behavior for incomplete quotes and quote the final value for the intended shell-word context.

For word/subword motions, reuse `select-word-style`, `match-words-by-style`, and the `*-match` widgets. They support whitespace, shell-word, character-class, and subword policies through styles. An associative `matched_words` gives named regions such as `word-before-cursor` and `word-after-cursor`; preserve empty regions. Vi shell-word text objects (`select-in-shell-word`, `select-a-shell-word`) already understand quoted arguments. Avoid writing a whitespace regex to rediscover these structures.

## Treat a modal edit as a transaction

Use `vared` to edit a parameter and `recursive-edit` for a temporary mode inside a widget. Clone a keymap with `bindkey -N temporary original` when editing it independently; `bindkey -A` makes an alias sharing the same map. Limit all temporary bindings, prompts, history, and undo state to their owner and restore them in `always`.

Snapshot `UNDO_CHANGE_NO` and use `zle undo saved_change` for a deliberate rollback; local `UNDO_LIMIT_NO` can keep recursive editing from undoing changes preceding the mode. Check `recursive-edit`'s status before committing and restore cursor/mark/selection as needed. `split-undo` defines a user-visible undo boundary.

Widgets that implement kills, yanks, or repeatable vi changes should set the corresponding `zle -f kill`, `yank`, or `vichange` flag; yanks also need correct `YANK_START`/`YANK_END`. Delegate to builtin widgets when that preserves kill-ring and repeat semantics. Handle auto-removable suffixes via `auto-suffix-remove`/`auto-suffix-retain` when inserting punctuation. Use `zle .bracketed-paste parameter` to capture a paste into a parameter for deliberate processing rather than replaying every pasted byte as keystrokes.

PTY assertions should cover undo and cancellation, kill/yank chaining, vi repetition, incomplete syntax, mid-word cursors, Unicode, paste, and coexistence with completion/highlighting.

Search terms: user-defined widget, `$widgets`, `add-zle-hook-widget`, `region_highlight`, `zle -F`, keymap alias, `split-shell-arguments`, `modify-current-argument`, `recursive-edit`, undo, `match-words-by-style`.
