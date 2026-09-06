# Specialized native systems

Use this map when the requested design needs more than scalar/array transformations or ordinary command orchestration. It makes the less familiar capabilities discoverable without prescribing a native replacement for every external tool. Read the named section in the target runtime's manual before implementing an unfamiliar interface; see [24-source-map.md](24-source-map.md).

## Choose by ownership and data flow

| Need | Native capability | Decision that matters |
| --- | --- | --- |
| File metadata | `zsh/stat`, `zstat -H` / `-A`, `-f fd` | Structured metadata avoids GNU/BSD output parsing; inspect an already-open FD when that identity matters. |
| Byte streams, seek, cooperative locks | `zsh/system` | Own descriptors, partial buffers, timeouts, byte offsets, and lock lifetimes. |
| Readiness across descriptors | `zsh/zselect` | Select readable/writable FDs; keep framing above the transport. Timeout units are hundredths of seconds. |
| Terminal-driven child | `zsh/zpty` | Use a named PTY for terminal behavior; quote its command reparse and account for line discipline. |
| Local process IPC | `zsh/net/socket`, `zsocket` | Unix-domain socket paths and permissions define the endpoint; close connections and remove only owned socket paths. |
| Simple TCP sessions | `zsh/net/tcp`, `ztcp`, contributed `tcp_*` | Raw TCP supplies neither TLS nor authentication. Own listeners and connections separately and frame messages. |
| Persistent key/value state | `zsh/db/gdbm`, `ztie` / `zuntie` | A tied association is a live database handle, not an in-memory cache or multi-key transaction. |
| Small file-backed values | `zsh/mapfile` | Reads preserve trailing newlines; writes and unsets mutate files, and failure reporting is limited. |
| Function-private scratch state | `zsh/param/private`, `local -P` | Hide locals from callees without claiming persistent or lexical closures. |
| Date formatting and parsing | `zsh/datetime`, `strftime` | Define timezone/locale and parse coverage; distinguish wall time from elapsed time. |
| Scientific arithmetic | `zsh/mathfunc`, `functions -M` | Choose types and precision, and keep numeric results separate from command status. |
| Repeated regex matching | `zsh/regex`, `zsh/pcre` | Pick a regex language and localize captures; explicitly compiled PCRE state has shared ownership. |
| Full-screen terminal tool | `zsh/curses`, `zcurses` | Own the terminal session, input events, resize behavior, windows, and guaranteed best-effort restoration. |
| Terminal capability output | `zsh/terminfo`, `zsh/termcap` | Use capabilities and arguments rather than hardcoded terminal assumptions. |
| Palette adaptation | `zsh/nearcolor` | Approximate RGB colors for a smaller palette; loading it changes color rendering behavior. |
| Locale-aware display | `zsh/langinfo` | Query encoding/date/number conventions; byte, character, and display-column counts differ. |
| Scheduled shell callbacks | `zsh/sched` | Callbacks run at prompt/editor opportunities, not concurrently during a blocking command. |
| Filesystem attributes | `zsh/attr` | Extended attributes depend on OS/filesystem support; choose symlink behavior and handle failure. |
| POSIX capability sets | `zsh/cap` | Process/file privilege mutation requires an explicit administrative purpose; this is not an ordinary portability trick. |
| Native filesystem operations | `zsh/files` with `zf_*` features | Selective loading avoids command shadowing; these commands have narrower semantics than system tools. |
| Shell introspection | `zsh/parameter` | Parameter/function/option/job tables are structured interfaces; some writes actively change the shell. |
| Editor introspection | `zsh/zleparameter`, `zsh/zle` | Distinguish available widget definitions from an active writable editor context. |
| Completion grammar/policy | `zsh/complete`, `zsh/complist`, `zsh/computil` | Build on compsys helpers; `comparguments`/`comptags` internals are rarely the right application API. |
| Legacy completion | `zsh/compctl` | Maintain compatibility when required; use compsys for a new maintained integration. |
| Profiling | `zsh/zprof` | Measures function calls; supplement it for top-level startup and end-to-end interactive latency. |
| Login/logout observation | `zsh/watch` | An interactive session feature, not process supervision. Keep terminal output bounded. |
| Legacy FTP | `zsh/zftp`, contributed `zf*` | Maintain when FTP is the required protocol; do not mistake it for SFTP or an authenticated encrypted transport. |
| Terminal cloning | `zsh/clone` | Forks shell state onto a prepared unused terminal; it is not a general worker pool or multiplexer's session model. |
| Character deletion widget | `zsh/deltochar` | Reuse `delete-to-char`/`zap-to-char` instead of reimplementing key reading and deletion. |
| First-run shell configuration | `zsh/newuser` | Startup bootstrap with its own discovery rules; do not load it as a general plugin initializer. |
| Compiled extension development | `zsh/example` | An example C module for extending Zsh; use only when a missing primitive justifies build/ABI maintenance. |

The common module mechanics and I/O details are in [09-native-modules.md](09-native-modules.md); editor and completion design are in [14](14-zle-widgets-and-plugin-interop.md) and [13](13-completion-authoring.md).

## Persistent associations as an adapter

```zsh
_acme_read_cached_value() {
  emulate -L zsh
  (( $# == 2 )) || return 2
  zmodload zsh/db/gdbm || return 1
  local -A cache_db
  ztie -r -d db/gdbm -f "$1" cache_db || return 1
  {
    (( ${+cache_db[$2]} )) || return 3
    REPLY=${cache_db[$2]}       # caller owns local REPLY; valid on status 0
  } always {
    zuntie cache_db
  }
}
```

Predeclare the association locally so the database handle has a function lifetime. A read-only tie prevents mutation through this interface; explicit `zuntie` closes it, and local-scope exit also releases the tie. Define record schema, absent-versus-empty behavior, concurrency policy, and invalidation before persisting a cache. Each association access reaches the database; repeated nested expansions can repeat I/O. Never treat a sequence of assignments as an atomic transaction.

## Terminal ownership and event loops

For a full-screen tool, bracket `zcurses init` with `zcurses end` in `always`; delete child windows before parents, refresh deliberately after drawing, and test resize and input timeout events. Do not run a second terminal event loop inside a ZLE callback. For a prompt plugin, keep ZLE in charge and publish state through its widget/FD interfaces.

The TCP function suite demonstrates named sessions, descriptor-to-session maps, per-session hooks, temporary current-session selection, and common logging. Those are useful architecture patterns. Its line-based reads can still block on incomplete lines, as the manual explicitly notes. An interactive session convenience is not automatically a nonblocking protocol implementation.

Use `sched -o` for a callback that needs a prompt-safe visible announcement. Scheduling is cooperative; it does not interrupt a long foreground command to meet a hard deadline. Event list indices shift as events are inserted/deleted, so a stored index is not a stable cancellation token. Track owned command identities and verify the current entry before removing it. Revalidate the directory/request generation when a delayed action fires.

## Reuse contributed systems at the right level

- `age`, `before`, and `after` are reusable glob predicates from the calendar system. They enable human-oriented date selection without adopting the scheduler. Prefer explicit numeric timestamps for machine protocols; the calendar parser has date ambiguity, limited localization, and no general timezone support.
- `zmv` compiles a source-pattern/destination mapping and checks collisions; `zargs` batches argument arrays and can bound parallel invocations. Select before acting, and preserve the mapping/task status when partial failure matters.
- `cdr` and `zsh_directory_name_generic` unify navigation, persistence, and completion; avoid replacing `cd` just to record visits or abbreviate paths.
- `promptinit`, `vcs_info`, and `zformat` separate acquisition, customization, and rendering. Implement extensions through their public hooks/styles instead of copying internal engines.
- `zsh-mime-setup` demonstrates extension-based handler dispatch through styles and suffix aliases. An extension is a routing hint, not verified content type. Handler strings and `mailcap` are code/configuration boundaries; do not enable file execution as an incidental convenience.
- `zed`, `vared`, `read-from-minibuffer`, `split-shell-arguments`, and `modify-current-argument` support native editing tools. Choose whether the operation edits data, an argument, a whole command, or executable function source.
- `throw`/`catch` demonstrate classified nonlocal recovery within one shell. `zrecompile` demonstrates compilation invalidation; `reporter` and `run-help` support diagnostics and discoverability. Load the subsystem only when its lifecycle and output suit the task.

Search terms: `ztie`, `zuntie`, `zcurses`, `zsocket`, `ztcp`, `tcp_expect`, `sched`, `zsh_scheduled_events`, `age`, `zmv`, `zargs`, `zsh-mime-setup`, `zsh/example`.
