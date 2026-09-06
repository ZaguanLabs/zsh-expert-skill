# Version gates

Use this section whenever code relies on a recently added feature or is copied from the current Zsh development branch.

## Baselines

This skill's stable research baseline is Zsh 5.9.2, released July 12, 2026. Much of the installed world still uses 5.8.1 or 5.9. Check the project's declared minimum and the runtime:

```zsh
autoload -Uz is-at-least
if is-at-least 5.9; then
  ...
fi
```

The upstream `is-at-least` function handles test/dev suffixes more reliably than lexical string comparison.

Do not infer a feature solely from documentation generated from the upstream default branch. The default branch identified itself as `5.9.999.3-test` during this research and contains post-5.9 work intended for 5.10.

## Stable 5.9 additions worth gating

Compared with 5.8.1, 5.9 includes:

- `_arguments -0` for NUL-delimited `opt_args`;
- `zsystem flock -i` and fractional `-t`;
- `compinit -w` explanations;
- `CLOBBER_EMPTY`, `CASE_PATHS`, `TYPESET_TO_UNSET`, `SHORT_REPEAT`;
- parameter expansion sort flag `(-)` for negative numbers;
- expansion flag `(*)` to activate extended-glob matching locally;
- `functions -T` / `function -T` tracing support;
- `_numbers` and richer numeric completion descriptions;
- `strftime -n`.

If supporting 5.8, supply a clear fallback rather than silently changing output.

## Stable 5.9.2 additions

The 5.9.2 release adds:

- POSIX real-time signal support where available;
- `kill -q` for queued signal values and `kill -L` signal listing;
- completion helper `_as_if`.

Capability also depends on platform and build, so module/signal detection remains necessary.

## Post-5.9 development: do not emit ungated

The upstream development line contains, among other changes:

- named references and namespaces, with some interfaces in `zsh/ksh93`;
- non-forking current-shell substitutions `${ ... }`, `${| ... }`, `${{param} ... }`;
- `zparseopts -G`, `-n`, `-v` and a `zgetopt` wrapper;
- `zsh/random` with `SRANDOM` and random math functions;
- ZLE highlight layers, opacity, named highlight groups, cursor form, and richer terminal capability parameters;
- `_shadow` and development `_call_program` quoting options;
- refined `ERR_EXIT`/`ERR_RETURN` behavior;
- monotonic internal timing changes;
- namespace-related changes beyond the existing stable `zsh/param/private` module.

These may be excellent designs, but copying examples from `master` into stable 5.9 code produces parse-time failures that a runtime branch cannot guard if the parser must read the new syntax.

Do not classify every unfamiliar feature as development-only. The supplied 5.9.2 release manual includes private locals via `zsh/param/private`, array set/zip operators, `functions -M`, `zsocket`, GDBM ties, and curses. Detect optional module availability separately from language version. In particular, private locals have their own parse-order requirement; see [05-functions-scope-and-options.md](05-functions-scope-and-options.md).

For syntax introduced in a newer version, isolate it in a separate autoload/source file selected only after the version check, or use a safely quoted `eval` of constant developer-authored code after capability detection. Prefer the separate file.

## Feature detection

Use the narrowest check:

```zsh
zmodload -e zsh/system || zmodload zsh/system || return
(( $+functions[_as_if] )) || autoload -Uz +X _as_if 2>/dev/null
(( $+widgets[zle-line-pre-redraw] ))
```

Version checks are appropriate for syntax and documented behavior changes. Capability checks are better for optional modules, external commands, terminal support, and backported functions.

## Document assumptions in generated code

At the top of a plugin/script, state the minimum version and why. In tests, include the oldest supported version and current stable. If development features are requested, label them experimental and link the exact upstream revision.

Search terms: `is-at-least`, Zsh 5.9 NEWS, 5.9.2 release, 5.10 development, parse-time version gate.
