# Testing, debugging, and profiling

Use this section to validate scripts, startup files, completions, widgets, traps, and performance.

## Layer tests by semantic risk

1. Parse every changed Zsh file with `zsh -f -n -- file`.
2. Execute pure functions under `zsh -f` with controlled options and locale.
3. Use temporary directories containing hostile filenames and boundary data.
4. Test startup under a temporary `ZDOTDIR`.
5. Use a PTY for ZLE, completion, prompt, job-control, terminal, and signal behavior.
6. Run supported Zsh versions/OSes in CI.

The included `scripts/verify-zsh.zsh` performs parse checks by default. `--smoke` executes a file under `zsh -df` with a temporary `ZDOTDIR`; execution is explicit because shell files can have side effects.

## Fixture matrix for shell data

Include:

- empty, unset, and one-element arrays;
- empty array elements;
- spaces, tabs, newlines, quotes, backslashes, glob metacharacters;
- leading `-`, names equal to `.`/`..`, dotfiles;
- Unicode, combining characters, invalid locale bytes when relevant;
- no glob matches, one match, many matches;
- readonly/unwritable paths, symlinks, broken symlinks;
- command absence and nonzero/partial output;
- interrupted operations and stale async results.

Assert arrays element-by-element, not by joined display.

## Isolated startup

```zsh
tmp=$(mktemp -d)
ZDOTDIR=$tmp zsh -dfi
```

`-f` disables user rc files; `-d` disables global rc files after unavoidable `zshenv` handling. For a test rc, place it in the temporary directory and start the appropriate interactive/login mode. Set a minimal `HOME`, `PATH`, `TERM`, and locale when the test needs true isolation.

Check startup output: a healthy `.zshrc` should not print in noninteractive contexts and should not block without a tty.

## Trace surgically

- `functions -T target` traces one function even though completion normally disables global XTRACE.
- `PS4` can include `%N`/`%i`/timestamps for source/function/line context.
- `_complete_debug` captures completion tracing.
- `typeset -p`, `functions`, `zstyle -L`, `bindkey -L`, `zle -la`, and module parameter tables expose reproducible state.
- `${(V)value}` reveals invisible characters; `${(qqqq)value}` shows a quoted representation.

Never leave global `set -x` in startup and redact secrets before attaching traces.

## PTY testing

Use `zpty` or a test harness such as upstream Zsh's `comptest`. Drive exact key sequences and assert buffer, cursor, matches, rendered prompt markers, and process cleanup. Set terminal rows/columns and keymap explicitly.

For async tests, control the worker with barriers rather than sleeps. Assert old generations are discarded, FDs are unregistered, children are terminated, and a reused descriptor does not invoke the old callback.

## Test traps and cleanup

Exercise success, ordinary failure, `return`, Ctrl-C/TERM, timeout, child crash, and cleanup failure. Verify final status and filesystem/descriptor/process state. A cleanup test that only checks the happy path is insufficient.

## Profile correctly

Use `zprof` for function cost, `$EPOCHREALTIME` for targeted phases, and `zsh-bench` for user-visible startup. Benchmark completion from a PTY and repeat after caches are cold/warm. Set a regression threshold wide enough for CI noise but tight enough to catch a new external process in a hot path.

## Upstream tests are executable documentation

When expansion/trap/option behavior is ambiguous, consult the corresponding upstream `.ztst` files (`D04parameter`, `D02glob`, `C03traps`, `Y*` completion, `X*` ZLE) and reproduce the smallest case on the target version.

Search terms: `zsh -n`, temporary `ZDOTDIR`, `zpty`, `_complete_debug`, `functions -T`, `zprof`, `.ztst`.
