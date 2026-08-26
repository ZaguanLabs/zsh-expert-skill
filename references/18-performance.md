# Performance

Use this section for startup, completion, prompt, and per-keystroke latency. Optimize observable latency, not folklore metrics.

## Measure the experience

Interactive Zsh has distinct latencies:

- first prompt;
- first command availability;
- steady command-to-prompt delay;
- input/key-to-display delay;
- completion latency;
- prompt refresh latency.

`time zsh -lic exit` measures only that command path and can reward deferred initialization while the first real command remains slow or incomplete. Use `zsh-bench` for user-visible startup metrics and a PTY fixture for completion/ZLE latency.

Record distribution across multiple warm and cold runs, not one best number. Note filesystem cache, network mounts, Git repository size, plugin set, and terminal.

## Profile before changing architecture

```zsh
zmodload zsh/zprof
# source/configure workload
zprof
```

`zprof` measures function calls, not all top-level source time or user-visible rendering. Add targeted `$EPOCHREALTIME` timestamps around load phases. Use `functions -T name` or a temporary targeted trace when control flow is unclear.

## High-value optimizations

- Remove external processes from hot loops when native parameters/modules make code clearer.
- Cache expensive completion producers with correct invalidation.
- Disable unused `vcs_info` backends and expensive repo checks.
- Keep ZLE redraw hooks O(buffer length) or better; cap/skip pathological buffers.
- Build `fpath` once before `compinit`; avoid duplicate initialization.
- Autoload infrequently used functions instead of sourcing large bodies.
- Avoid repeated command detection; `$commands` and `$functions` are cheap.
- Batch prompt updates and completion matches.
- Use arrays rather than repeated reparsing of command strings.

## `zcompile` with realistic expectations

Compiled `.zwc` files reduce parsing cost for substantial stable function sets. They do not fix external commands, network access, completion generation, or synchronous VCS checks. Recompile when sources change, use a lock, and remove stale `.zwc.old` files only when ownership is certain.

Do not precompile rapidly changing user files without robust invalidation. Measure the end-to-end effect.

## Deferred initialization is a semantic change

During deferral, commands, aliases, widgets, environment variables, completions, and hooks may be absent. Deferred code commonly runs inside ZLE, a context many plugins do not expect. The zsh-bench research concludes that most initialization is unsafe to defer and that a fast complete config can stay below perceptual thresholds without it.

Only defer when:

- temporary absence is explicitly acceptable;
- no user input can observe a half-loaded API;
- ordering dependencies are modeled;
- execution inside ZLE is supported;
- first-command and input tests prove behavior.

Do not defer autosuggestions merely because syntax highlighting was deferred; their ordering and widget behavior interact.

## Completion performance

Each `matcher-list` entry can perform a full completion pass. `_approximate` and `_correct` are expensive. External completion producers need cache and timeout strategies. Narrow style contexts and tags before reducing features globally.

## Oh My Zsh performance

OMZ's size alone does not determine latency; enabled plugins and external work do. Its core already caches/compiles completion dumps and autoloads functions. Profile the actual enabled set. Replace a slow plugin only after identifying its load/hot-path cost and required behavior.

Search terms: zsh-bench, first prompt lag, first command lag, `zprof`, `EPOCHREALTIME`, `zcompile`, deferred initialization.
