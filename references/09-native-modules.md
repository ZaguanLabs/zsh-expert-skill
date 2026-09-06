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

- `sysparams[pid]` yields the actual process PID in a forked shell where `$$` retains the original shell PID. Where available, `sysparams[procsubstpid]` identifies the last process-substitution child; capture it before another substitution replaces it and verify the target runtime.
- `sysread` supports bounded reads and byte counts; EOF has a distinct status.
- `zsystem flock` provides cooperative advisory locking.

Always close allocated descriptors and handle partial reads/writes. A single `syswrite` is not guaranteed to consume an arbitrarily large buffer.

`sysopen -o cloexec,nonblock` makes inheritance/readiness policy explicit. `nofollow`, `create`, and `excl` help when opening rather than prechecking a file is the operation that must enforce a condition; they do not make every ancestor trustworthy. `sysseek` and `systell(fd)` support record offsets in seekable files.

Treat `sysread` status as a protocol: 0 means bytes read, 4 timeout, 5 EOF, 2 read/poll failure, and 3 output-write failure when forwarding. Capture `$ERRNO` immediately for system errors. A timeout does not set it. `syswrite -c count` reports actual bytes written; advance the buffer by bytes, not multibyte characters.

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

The interface is active: assignment writes the file and `unset "mapfile[$filename]"` deletes it. Errors are not reported through a reliable status interface; use an explicit read/write when failure must be distinguished from empty content. Unlike `$(<file)`, a mapfile value retains trailing newlines. Whole-array values are empty placeholders, not all file contents.

### `zsh/files`

Provides built-in `chgrp`, `chmod`, `chown`, `ln`, `mkdir`, `mv`, `rm`, `rmdir`, and `sync`, with corresponding `zf_` names. It does not provide `cp`. Load selected prefixed features, for example `zmodload -F zsh/files b:zf_mkdir`, to avoid globally shadowing utilities. These are smaller interfaces, not drop-in GNU/BSD replacements: native `mv` does not move across devices and native `chmod` accepts octal modes. Builtins avoid external `exec` argument limits, but still materialize arguments in shell memory.

### Regex and math modules

`zsh/regex` supports POSIX ERE for `[[ =~ ]]`; `zsh/pcre` plus `RE_MATCH_PCRE` enables PCRE when compiled. Match results populate `MATCH`, `match`, `MBEGIN`, `MEND`, `mbegin`, `mend`. Localize the option. `zsh/mathfunc` adds numeric functions; declare floats explicitly.

Use `pcre_compile` and `pcre_match` when repeatedly applying one PCRE benefits from explicit compilation; compilation replaces module-level compiled-pattern state, so coordinate ownership. For arithmetic APIs and numeric validation, read [25-arithmetic-and-numeric-design.md](25-arithmetic-and-numeric-design.md). `zsh/param/private` offers per-call private locals on stable Zsh; see [05-functions-scope-and-options.md](05-functions-scope-and-options.md).

## Module selection rule

Choose a native module when it improves semantic precision or portability. Do not use one merely to remove a readable external command. Capability checks, cleanup, and clearer data flow matter more than process-count minimalism.

For sockets, GDBM-backed associations, curses, scheduling, attributes, capability sets, and the less common contrib systems, use the decision map in [26-specialized-native-systems.md](26-specialized-native-systems.md). Check individual features with `zmodload -F ...`; a loaded module does not prove a particular feature is enabled. Feature prefixes distinguish builtins (`b:`), parameters (`p:`), math functions (`f:`), and conditions (`c:`/`C:`). Loading or unloading a shared module is shell-wide state, not localized by `emulate -L`.

Search terms: `zmodload -F`, `zsh/system`, `zstat -H`, `zselect`, `zpty`, `sysparams`, `mapfile`.
