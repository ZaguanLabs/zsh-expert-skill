# Native modules

Use this section when a `zsh/*` module can provide a precise primitive without a platform-specific parsing pipeline.

## Load features, not assumptions

```zsh
zmodload -F zsh/stat b:zstat || return 1
zmodload zsh/system || return 1
```

`zmodload -F` requests named features and makes dependencies visible. A module may be unavailable because Zsh was built without its system dependency; handle that as a capability check and offer a fallback.

Useful introspection:

```zsh
zmodload -L
zmodload -e zsh/zle
```

## High-leverage modules

### `zsh/stat`

Use `zstat` for metadata without parsing `stat(1)` variants across GNU/BSD systems:

```zsh
zmodload -F zsh/stat b:zstat
local -A st
zstat -H st -- "$file" || return
(( st[size] > limit )) && return 1
```

Choose link-following behavior explicitly and consult the manual for field names on the target version.

### `zsh/system`

Provides `sysopen`, `sysread`, `syswrite`, `zsystem flock`, `$ERRNO`, and `$sysparams`.

- `sysparams[pid]` yields the actual process PID in a forked shell where `$$` retains the original shell PID.
- `sysread` supports bounded reads and byte counts; EOF has a distinct status.
- `zsystem flock` provides cooperative advisory locking.

Always close allocated descriptors and handle partial reads/writes. A single `syswrite` is not guaranteed to consume an arbitrarily large buffer.

### `zsh/datetime`

Provides `EPOCHSECONDS`, `EPOCHREALTIME`, and `strftime`. Use `EPOCHREALTIME` for profiling intervals; treat wall-clock timestamps as unsuitable for causal ordering. Zsh 5.9.2's ordinary timers do not inherit all development-line monotonic-time changes.

### `zsh/zselect`

Waits until descriptors are readable/writable/error-ready, with timeout in hundredths of a second. A timeout returns status 1. It can poll stdin before an interactive updater prints, avoiding output over already-typed input.

### `zsh/zpty`

Runs a command under a pseudo-terminal. It is the right tool for:

- testing ZLE and interactive programs;
- driving a long-lived worker that expects a tty;
- avoiding pipe behavior differences in interactive clients.

Prefer `zpty -r`/`-w` over raw `sysread`/`syswrite` on the PTY unless the protocol requires exact descriptor control.

### `zsh/parameter`

Exposes live tables such as commands, functions, aliases, options, jobs, modules, and user directories. This is usually safer and faster than parsing `typeset`, `jobs`, or `which` output.

### `zsh/zutil`

Provides `zstyle`, `zparseopts`, `zformat`, and completion internals. Use namespaced style contexts as a configuration API rather than proliferating global variables.

### `zsh/mapfile`

Maps files into an associative parameter. It is elegant but has caveats around file size, writes, and special files. Use it for small controlled files, not unbounded or untrusted input.

### `zsh/files`

Provides built-in `mv`, `cp`, `ln`, `mkdir`, `rm`, `rmdir`, `sync`. It avoids process startup and can help with very large generated argument lists, but it also changes command resolution. Load feature names deliberately or call qualified builtins; never surprise a caller by globally shadowing utilities.

### Regex and math modules

`zsh/regex` supports POSIX ERE for `[[ =~ ]]`; `zsh/pcre` plus `RE_MATCH_PCRE` enables PCRE when compiled. Match results populate `MATCH`, `match`, `MBEGIN`, `MEND`, `mbegin`, `mend`. Localize the option. `zsh/mathfunc` adds numeric functions; declare floats explicitly.

## Module selection rule

Choose a native module when it improves semantic precision or portability. Do not use one merely to remove a readable external command. Capability checks, cleanup, and clearer data flow matter more than process-count minimalism.

Search terms: `zmodload -F`, `zsh/system`, `zstat -H`, `zselect`, `zpty`, `sysparams`, `mapfile`.
