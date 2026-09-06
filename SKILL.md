---
name: zsh-expert
description: Design, implement, review, debug, and optimize native Zsh scripts, startup files, plugins, completions, ZLE widgets, prompts, and framework integrations. Use when the target is Zsh and expert shell semantics matter; do not use for scripts that must remain portable POSIX sh or Bash.
metadata:
  version: "1.0.1"
---

# Zsh Expert

Produce native Zsh that is precise, composable, and maintainable. Exploit Zsh-specific capabilities when they simplify the result, but do not turn dense syntax into a goal of its own.

## Design in native Zsh

Before implementing a substantial solution, consider the shell's own data and execution model. Look for a useful composition of arrays, expansion, glob queries, dynamic scope, autoloaded functions, modules, and the completion/editor APIs. Use [23-exceptional-recipes.md](references/23-exceptional-recipes.md) when choosing an architecture; follow its topic links for implementation details.

Choose by the operation: set reconciliation wants array operators; filesystem selection wants glob qualifiers; shared helper state wants a documented output protocol; an interactive grammar wants compsys or ZLE's shell-word utilities; byte streams want descriptors and framing. Consider [specialized native systems](references/26-specialized-native-systems.md) when a task needs capabilities beyond ordinary shell scripting.

Explain the benefit and the essential invariant of an advanced technique. Prefer it when it materially improves correctness, expressiveness, composability, or measured performance. Do not force every feature into every program, or reject a useful native design merely because it is unfamiliar.

## Establish the contract

Before changing code, identify:

- execution context: script, autoloaded function, startup file, plugin, completion function, ZLE widget, or prompt;
- minimum Zsh version and operating systems;
- native Zsh versus sh/ksh emulation;
- standalone Zsh versus Oh My Zsh or another framework;
- whether code handles untrusted text, filenames, repositories, environment files, or terminal input;
- whether latency is user-visible.

If the repository states a minimum version, honor it. Otherwise target the installed version, avoid unreleased features, and gate newer stable features with `autoload -Uz is-at-least` or a direct `$ZSH_VERSION` check.

## Work from these invariants

- Zsh does not perform implicit IFS splitting or filename generation on ordinary unquoted parameter expansion in native mode. Model lists as arrays and expand them with `"${array[@]}"` when boundaries matter.
- Function scope is dynamic. Normally start reusable functions with `emulate -L zsh`; add only the options they need. Completion functions inherit compsys' option environment: preserve it rather than resetting it blindly. Emulation localizes options, patterns, and traps, not arbitrary shell state or parse-time aliases.
- Do not combine a declaration with a fallible command substitution when its status matters. Declare first, then assign.
- Treat `${(e)}`, `${~...}`, `eval`, `source`, prompt substitution, completion command output, and directory-local files as execution or pattern-compilation boundaries.
- Prefer hook arrays through `add-zsh-hook` and `add-zle-hook-widget` over replacing a singleton hook or wrapping every widget.
- Make `fpath` complete before `compinit`. Preserve `compaudit` checks. Framework convenience is not permission to use `compinit -u`.
- Interactive callbacks must unregister file-descriptor watchers, close descriptors, reject stale async results, and repaint only when visible state changed.
- Preserve the caller's aliases, options, traps, keymaps, hook registrations, prompt, and file descriptors unless ownership of them is part of the API.
- Verify semantics under `zsh -f`, and test interactive behavior in a pseudo-terminal. A Bash linter is not a Zsh oracle.

## Route to the smallest useful knowledge set

Read only references relevant to the request. For cross-cutting work, load the primary topic plus security and testing.

### Language and data

- Execution order, parsing contexts, subshells, statuses: [references/01-execution-model.md](references/01-execution-model.md)
- Scalars, indexed/associative arrays, ties, special parameters: [references/02-parameters-and-arrays.md](references/02-parameters-and-arrays.md)
- Nested expansion, flags, splitting, joining, modifiers: [references/03-expansion-algebra.md](references/03-expansion-algebra.md)
- Extended patterns, recursive globbing, qualifiers, sorting: [references/04-patterns-and-glob-qualifiers.md](references/04-patterns-and-glob-qualifiers.md)
- Numeric types, precedence, validation, custom math functions: [references/25-arithmetic-and-numeric-design.md](references/25-arithmetic-and-numeric-design.md)

### Reusable programs

- Functions, autoloading, scope, option hygiene: [references/05-functions-scope-and-options.md](references/05-functions-scope-and-options.md)
- Status propagation, traps, `always`, cleanup: [references/06-control-flow-errors-and-traps.md](references/06-control-flow-errors-and-traps.md)
- Redirections, multios, descriptors, process substitution: [references/07-redirection-fds-and-process-substitution.md](references/07-redirection-fds-and-process-substitution.md)
- Reading, tokenizing, option parsing, serialization: [references/08-input-parsing-and-serialization.md](references/08-input-parsing-and-serialization.md)
- `zsh/*` modules and when they replace external tools: [references/09-native-modules.md](references/09-native-modules.md)
- Sockets, persistent associations, curses, scheduling, contrib systems: [references/26-specialized-native-systems.md](references/26-specialized-native-systems.md)
- Jobs, coprocesses, workers, and async callbacks: [references/10-async-concurrency-and-jobs.md](references/10-async-concurrency-and-jobs.md)

### Interactive systems

- Startup order and Oh My Zsh integration: [references/11-startup-files-and-oh-my-zsh.md](references/11-startup-files-and-oh-my-zsh.md)
- User-facing completion styles and diagnostics: [references/12-completion-configuration.md](references/12-completion-configuration.md)
- Authoring `_arguments` and stateful completions: [references/13-completion-authoring.md](references/13-completion-authoring.md)
- ZLE widgets, highlighting, keymaps, plugin interop: [references/14-zle-widgets-and-plugin-interop.md](references/14-zle-widgets-and-plugin-interop.md)
- Prompt escaping, VCS state, terminal capabilities: [references/15-prompts-vcs-and-terminal.md](references/15-prompts-vcs-and-terminal.md)
- Plugin APIs, namespaces, lifecycle, OMZ conventions: [references/16-plugin-engineering.md](references/16-plugin-engineering.md)
- History, directory state, and shell hooks: [references/17-history-directories-and-hooks.md](references/17-history-directories-and-hooks.md)

### Quality and boundaries

- Meaningful latency measurement and startup optimization: [references/18-performance.md](references/18-performance.md)
- Trust boundaries, quoting, completion permissions, terminal safety: [references/19-security.md](references/19-security.md)
- Tests, tracing, profiling, isolated reproduction: [references/20-testing-debugging-and-profiling.md](references/20-testing-debugging-and-profiling.md)
- Bash migration and deliberate portability: [references/21-portability-and-bash-migration.md](references/21-portability-and-bash-migration.md)
- Stable 5.9/5.9.2 features versus post-5.9 development: [references/22-version-gates.md](references/22-version-gates.md)
- High-leverage native designs worth considering: [references/23-exceptional-recipes.md](references/23-exceptional-recipes.md)
- Research provenance and authoritative follow-up links: [references/24-source-map.md](references/24-source-map.md)

## Implement and verify

Prefer a short, explicit design over a trick. Explain any expansion with more than one transformation stage. Keep destructive examples in dry-run form first.

For changed files, run `zsh -n`. For non-interactive smoke tests, use `scripts/verify-zsh.zsh`; it parses by default and executes only with `--smoke`. Use a temporary `ZDOTDIR` for startup tests. For completion, ZLE, prompt, signals, or job-control behavior, use a PTY and assert observable buffer, match, or terminal state.

When maintaining this skill's semantic guidance, run `zsh -df scripts/test-semantics.zsh`. Its assertions exercise the native behaviors used in the references; they do not replace tests of the user's program.

When reviewing Oh My Zsh code, distinguish three layers in the answer:

1. core Zsh semantics;
2. compsys/ZLE/contrib conventions shipped with Zsh;
3. Oh My Zsh lifecycle and configuration conventions.

Do not recommend copying a large framework implementation when the required invariant can be expressed as a small native component.
