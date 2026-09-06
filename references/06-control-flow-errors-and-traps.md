# Control flow, errors, and traps

Use this section for reliable cleanup, signal handling, `ERR_EXIT`, return-status preservation, and transactional shell operations.

## Prefer explicit status flow

For reusable code, explicit checks are easier to reason about than a global `set -e`:

```zsh
local output
output=$(command -- "$arg") || {
  local -i rc=$?
  print -u2 -r -- "command failed ($rc)"
  return rc
}
```

`ERR_EXIT` and `ERR_RETURN` have exceptions in conditions, `&&`/`||` lists, pipelines, negation, and nested functions. Their behavior also changed in development after 5.9.2. Use them only with tests covering the exact control forms.

`setopt PIPE_FAIL` is useful when a pipeline is one logical operation. Inspect `$pipestatus` when each failure has different meaning.

## `always` is native `finally`

Zsh's try/always construct provides cleanup across ordinary control transfers and many shell errors:

```zsh
local tmp
tmp=$(mktemp) || return
{
  produce >| "$tmp" || return
  consume "$tmp"
} always {
  command rm -f -- "$tmp"
}
```

After the always block, ordinary `$?` comes from the try block, not the cleanup list. Inside the always block, `$TRY_BLOCK_ERROR` is 1 only for a shell error that aborts the try list; it is not the status of an ordinary nonzero command. Setting it to zero deliberately clears such an error. Test `return`, `break`, signal, ordinary failure, and runtime-error paths separately.

Use `always` to restore `stty`, directories, temporary files, locks, file descriptors, widgets, or temporary hooks. It is superior to a broad `EXIT` trap for function-local resources.

It is not a guarantee across `exit`, process replacement, `SIGKILL`, or an error that prevents the construct from being parsed. `TRY_BLOCK_INTERRUPT` represents an interrupt pending from the try block; clearing it deliberately consumes the interrupt. Keep ordinary command failure, shell error, and cancellation separate, and avoid a `return` in cleanup that overwrites the operation's intended control flow.

## Trap models differ

Zsh supports:

- list traps: `trap 'code' INT`;
- function traps: `TRAPINT() { ... }`;
- hook arrays for shell lifecycle events, which are not Unix signals.

Function traps and list traps differ in subshell inheritance and reset behavior. If a reusable function installs traps, use `emulate -L zsh` or `setopt localtraps` so it does not replace the caller's trap permanently.

The return status of a function signal trap is meaningful: zero tells Zsh the signal was handled and normal execution may continue; a nonzero return preserves interrupted behavior. To mimic SIGINT termination from `TRAPINT`, use `return $((128 + $1))`, where `$1` is the signal number. The incoming `$?` is not necessarily a signal status. A `return` in a list trap instead returns from the surrounding context.

Avoid doing complex, non-reentrant work in traps. Set a flag, terminate owned children, close known descriptors, and let normal control flow finish cleanup.

## Locking and atomicity

For a portable intra-Zsh mutex, `mkdir lockdir` is atomic and exposes stale-lock recovery choices. For advisory file locks, use `zmodload zsh/system` and `zsystem flock`; every participant must cooperate.

Important `zsystem flock` details:

- the file must exist;
- request the descriptor with `-f var` and close that descriptor to unlock;
- printing to the lock descriptor or redirecting to the same file can release/replace the lock unexpectedly;
- a subshell can make lifetime automatic, but state changes then do not return to the parent;
- 5.9 adds fractional timeouts and the `-i` wait interval.

Write updated state to a temporary file in the same directory, `fsync` if durability is required, then rename. A shell `>` directly over a config file is not transactional.

## Child ownership

Track every PID/process group you create. On cancellation:

1. unregister the read watcher;
2. close the parent descriptor;
3. send `TERM` to the owned process group when job control created one, otherwise to the PID;
4. optionally escalate after a bounded wait;
5. reap if the execution model permits it.

Never use a broad process-name kill as cleanup.

## Control-flow tools beyond boolean status

Use `case ... ;&` for unconditional fallthrough into the next body and `;|` to resume testing later patterns. The latter can express independent classification rules, but changes to the tested variable can affect later matches. Choose explicit status classes for ordinary APIs and `setopt local_loops` when a helper's `break`/`continue` must not reach a caller's loop.

For deeply nested same-shell operations, contributed `throw`/`catch` can implement named exceptions with `always`. Autoload them explicitly, quote catch patterns, and reset `EXCEPTION` at the outermost owner. An unhandled exception leaves that variable set; a later unrelated shell error can otherwise look like the old exception. Exceptions do not propagate through a forked worker: send a classified result over its protocol. Use this mechanism only when nonlocal recovery makes the code clearer than explicit returns.

Search terms: try always, `TRY_BLOCK_ERROR`, function traps, `LOCAL_TRAPS`, `ERR_RETURN`, `zsystem flock`, process group.
