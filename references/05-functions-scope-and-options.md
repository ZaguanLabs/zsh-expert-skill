# Functions, scope, and options

Use this section for reusable APIs, autoloading, dynamic scope, option isolation, and library interoperability.

## The reusable function envelope

```zsh
my_namespace::work() {
  emulate -L zsh
  setopt pipe_fail no_unset

  local input=$1
  local -a result
  ...
}
```

`emulate -L zsh` selects native semantics and sets `LOCAL_OPTIONS`, `LOCAL_PATTERNS`, and `LOCAL_TRAPS`. Add `-R` only when resetting every settable option to native defaults is intended; it can erase useful caller state that ordinary `-L` leaves alone.

Set only required options. `NO_UNSET` in arbitrary interactive hooks can be brittle because many frameworks intentionally probe unset parameters; use it in controlled functions with defaults.

Use `builtin`, `command`, and `noglob` when dispatch identity matters. Avoid naming public functions after common external commands.

## Dynamic scope is both feature and hazard

A called function can see and modify a caller's local parameter. This enables hook protocols such as `vcs_info`, but accidental name collisions are real.

- Prefix internal globals and functions.
- Declare locals before calling helpers.
- Pass state explicitly when the coupling is not intentional.
- Document deliberately dynamic parameters such as `reply`, `REPLY`, `hook_com`, or `ret`.

Use an anonymous function for a temporary scope around one operation:

```zsh
() {
  emulate -L zsh
  local tmp=$1
  ...
} "$value"
```

This also gives process-substitution temporary files a lifetime tied to the function invocation.

## Autoload correctly

Put one autoloadable function per file named after the function, add its directory to `fpath`, then:

```zsh
autoload -Uz my_function
```

`-U` suppresses alias expansion while loading; this is important because aliases are parse-time ambient state. `-z` selects normal Zsh autoload format. `autoload +X name` forces loading without calling, useful before introspection or hook registration.

An autoload file normally contains the function body without an outer `name() {}` wrapper. If it performs initialization as well, understand `KSH_AUTOLOAD`/load-context differences and test both first and subsequent invocation.

## Preserve caller-visible state

If a library changes any of these, localize or restore them:

- shell options and disabled patterns;
- traps;
- `IFS`, locale parameters, `path`, `fpath`;
- aliases and functions it shadows;
- file descriptors;
- hook arrays and ZLE watchers;
- current directory (`builtin cd -q` inside a subshell or restore with `always`).

Avoid global `setopt` inside a function body. Avoid `chpwd()`/`precmd()` singleton functions in plugins; register named hooks.

## Output APIs

Choose one contract:

- stdout for a scalar/text stream;
- `reply` array for a list (common Zsh convention);
- `REPLY` scalar for one value;
- caller-named parameter with validated indirection;
- status for boolean/error classification.

Do not mix diagnostics with data stdout. Use `print -u2 -r --` for errors. Prefer `print -r --` to `echo`; `echo` option and escape behavior varies with options/emulation.

## Namespace and teardown

Stable Zsh lacks first-class namespaces. Prefix public functions and globals, for example `acme::render` and `_acme_state`. A plugin should offer an unload function when it registers hooks, watchers, widgets, or traps:

```zsh
acme::unload() {
  emulate -L zsh
  add-zsh-hook -d precmd acme::precmd
  zle -F "$fd" 2>/dev/null
  (( fd >= 0 )) && exec {fd}<&-
  unfunction acme::precmd acme::unload 2>/dev/null
}
```

Post-5.9 development adds namespaces and private parameters; do not assume them on 5.9.2.

Search terms: `emulate -L`, dynamic scope, autoload `-Uz`, function local parameters, `LOCAL_PATTERNS`, teardown.
