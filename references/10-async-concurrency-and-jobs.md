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
6. in the callback, consume available bytes without waiting for a full record, assemble frames, validate freshness, and commit complete results; close/unregister on terminal paths and repaint only if changed.

Store FD, PID, request generation, working directory, and result separately. A result for an old `$PWD` or buffer must not overwrite current state.

## Callback as a state machine

Readiness means some input or EOF, not a complete line or NUL-delimited result. A plain `read -d ''` can freeze ZLE if the worker sends a partial result and stalls; `read -t` only checks initial readiness. Use `sysread -t 0` or nonblocking descriptors, with a persistent buffer for each request.

- On bytes read, append within a documented size limit and consume only complete frames.
- On timeout/would-block, keep the partial frame and return to ZLE with the watcher still registered.
- On EOF, drain any final bytes, reject a truncated frame, then unregister and close.
- On `hup`, attempt to drain buffered data before teardown; on `nval`/`err`, record failure and release owned state.
- On a complete result, compare generation and context before publishing. Remove the watcher before closing its descriptor, and redraw only after a visible change.

Bound both the total buffered bytes and the work done in one callback; a continuously readable worker must not starve keyboard input. Model startup PID handshakes with the same framing rules. For a one-result worker, specify whether a complete frame or EOF ends the request, and reap/cancel the owned child accordingly. Keep cleanup idempotent.

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

`zpty name arg ...` concatenates its command arguments as shell code; it is not an argv-preserving launch API. Quote dynamic words for that reparse, or start a constant worker function and send data over its protocol. Terminal echo, CR/LF processing, and control characters also make a PTY different from a raw pipe; use a pipe/socket for binary protocols that do not need terminal behavior.

On teardown, unregister ZLE watchers before deleting the PTY. Clear partial protocol buffers and callbacks.

## Bounded batch parallelism

Track PIDs in an array/association and start at most `N` jobs. Reap one before starting another. Zsh job parameters from `zsh/parameter` can help, but do not parse `jobs` output. Preserve each task's status; `wait` on many jobs can otherwise obscure which one failed.

For ordinary argument batching, consider contributed `zargs -P N`; retain an explicit worker pool when task identities, retries, per-task statuses, or cancellation are part of the API. Never borrow Bash's `wait -n` without verifying support in the target Zsh.

## Avoid fake async optimization

Deferred startup is not automatically safe. It changes when commands, widgets, environment, and completions become available and often runs plugin initialization inside ZLE. Only defer components whose temporary absence and load context are tested. See the performance reference.

Search terms: `zle -F`, `sysparams[pid]`, `zpty`, coprocess, async prompt, process group, message framing.
