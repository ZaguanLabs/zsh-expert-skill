# Async, concurrency, and jobs

Use this section for nonblocking prompts, workers, file-descriptor callbacks, cancellation, coprocesses, and job control.

## Pick an execution architecture

For occasional background computation, a process substitution plus `zle -F` is smaller than a general worker. For repeated jobs, use a long-lived `zpty`/coprocess worker with a framed protocol. For batch parallelism outside ZLE, ordinary background jobs plus bounded concurrency may be simplest.

Never let a background child write directly to the interactive terminal. Route results to the parent and repaint through ZLE.

## Single-flight async request

The robust pattern used by modern Oh My Zsh and zsh-autosuggestions is:

1. if a prior request exists, unregister its `zle -F` handler and close its descriptor;
2. terminate the owned PID/process group;
3. allocate a new read descriptor from `< <( worker )`;
4. have the child send its actual PID first (`sysparams[pid]`);
5. register `zle -F fd callback`;
6. in the callback, read to EOF, validate freshness, update state, close/unregister, repaint only if changed.

Store FD, PID, request generation, working directory, and result separately. A result for an old `$PWD` or buffer must not overwrite current state.

## Callback skeleton

```zsh
_acme_async_ready() {
  emulate -L zsh
  local -i fd=$1
  local err=$2 data

  if [[ -z $err || $err == hup ]]; then
    IFS= read -r -d '' -u $fd data
    # Validate generation/context before committing data.
  fi

  zle -F $fd
  exec {fd}<&-
  zle .reset-prompt
  zle -R
}
```

The callback's second argument may report `hup`, `nval`, or `err` depending on platform. Treat EOF/hup as potentially carrying final buffered data. Cleanup must be idempotent.

## PID and process groups

In a forked shell, `$$` can still identify the original shell; load `zsh/system` and use `$sysparams[pid]` for the actual child PID.

With `MONITOR` (job control), Zsh can create a process group for a background job, so `kill -TERM -$pid` can terminate descendants. Without it, negative-PID group killing may target the wrong group; kill the child PID and accept/document descendant limitations or create a dedicated worker architecture.

Never kill based on command names. Verify that a stored PID still belongs to the request generation when races matter.

## Framing worker messages

Pipe reads are chunked, not message-oriented. A worker protocol needs framing:

- NUL-delimited quoted Zsh words for trusted Zsh-to-Zsh transport;
- length-prefix plus payload for arbitrary text;
- separate stdout/stderr/status/time fields;
- a buffer that retains incomplete frames across callbacks.

Concurrent children writing to one channel can interleave. Serialize output with a mutex/token or keep one writer. Batch prompt repaint until the result buffer is empty.

## Coprocesses and `zpty`

Zsh exposes one coprocess channel at a time; a new coprocess can replace the previous one. This makes raw coprocesses awkward for libraries. `zpty` names workers and exposes read/write operations, which is better for multiple independent subsystems.

A `zpty` worker inherits functions/state existing when it starts. Functions defined later are unavailable unless explicitly sent/evaluated. Prefer passing job state as arguments over mutating worker globals.

On teardown, unregister ZLE watchers before deleting the PTY. Clear partial protocol buffers and callbacks.

## Bounded batch parallelism

Track PIDs in an array/association and start at most `N` jobs. Reap one before starting another. Zsh job parameters from `zsh/parameter` can help, but do not parse `jobs` output. Preserve each task's status; `wait` on many jobs can otherwise obscure which one failed.

## Avoid fake async optimization

Deferred startup is not automatically safe. It changes when commands, widgets, environment, and completions become available and often runs plugin initialization inside ZLE. Only defer components whose temporary absence and load context are tested. See the performance reference.

Search terms: `zle -F`, `sysparams[pid]`, `zpty`, coprocess, async prompt, process group, message framing.
