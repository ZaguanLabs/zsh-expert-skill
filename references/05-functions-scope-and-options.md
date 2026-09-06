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

Post-5.9 development adds namespaces; use prefixes on the stable baseline. Private parameters are already available through the optional stable `zsh/param/private` module, with a different purpose from namespaces.

## Design an intentional dynamic-scope API

For a list-returning helper, have the caller declare `local -a reply`; the helper assigns `reply=(...)` without redeclaring it. This returns arbitrary elements without command substitution, serialization, or a subshell. A scalar helper can use the same protocol with `REPLY`. Document required inputs, output types, and which outputs are valid on failure. Copy the output before calling another helper that shares the protocol.

Do not use `typeset -g` as a guaranteed route to the outermost global: it can operate on an existing dynamically visible parameter. Caller-named outputs also need collision handling with the helper's own locals, not just identifier validation. A fixed `reply` protocol is often simpler.

Stable private parameters let implementation scratch state avoid leaking into callees:

```zsh
_acme_operation() {
  emulate -L zsh
  zmodload zsh/param/private || return 1
  local -P scratch=(one two)  # recognized local syntax before module loading
  _acme_helper               # cannot read this invocation's scratch
}
```

`private scratch=(...)` requires the module's reserved word to exist when the function is parsed; loading it inside that same body is too late. `local -P` avoids that parse-order trap. Private values are per-invocation, not persistent closure state. Callees can still see an outer non-private parameter of the same name. Do not export private parameters; tied parameters cannot be private, and special parameters require deliberately hiding their special behavior.

## Isolate loading as well as execution

`emulate -L` in a function body runs after that body was parsed. For a library that must load under foreign options, use constant-code sticky emulation, e.g. `emulate zsh -c 'autoload -Uz _acme_operation'`, or a loader that establishes parsing options before sourcing definitions. Functions defined/marked in sticky emulation regain that environment on invocation. It is not a general sandbox.

Use `autoload -r`/`-R` when resolving a function's location at registration is intentional; `-R` reports missing definitions. Compiled functions record alias and autoload choices: use `zcompile -U` and the appropriate `-z`/`-k` at compilation. A digest explicitly placed in `fpath` is used without comparing source age, so its owner must invalidate it.


Search terms: `emulate -L`, dynamic scope, autoload `-Uz`, function local parameters, `LOCAL_PATTERNS`, teardown.
