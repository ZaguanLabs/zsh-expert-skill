# Redirection, file descriptors, and process substitution

Use this section for precise stream routing, multios, named descriptors, process substitution, and lifetime/waiting bugs.

## Redirections are left to right

```zsh
command >file 2>&1   # stderr follows stdout to file
command 2>&1 >file   # stderr keeps the old stdout
```

Make the intended descriptor graph explicit. `|&` is `2>&1 |`. `&>file` redirects stdout and stderr together but differs from `>file 2>&1` when multios are involved.

Use `>|` only when overriding `NO_CLOBBER` is deliberate. For libraries, do not toggle the caller's clobber policy globally.

## Named file descriptors

Let Zsh allocate descriptors above the conventional range:

```zsh
local -i fd
exec {fd}<"$path" || return
{
  IFS= read -r -u $fd line
} always {
  exec {fd}<&-
}
```

Keep the descriptor number in an integer/local parameter, close it on every path, and unregister any `zle -F` watcher before closing. With `NO_CLOBBER`, allocating again through a parameter that still names an open descriptor is an error; close or unset it first. Explicit descriptor ownership is clearer than relying on incidental scope.

## Multios are implicit `tee`

With default `MULTIOS`:

```zsh
print data >one >two
print data >copy | consume
```

Zsh inserts a helper that fans out one descriptor. This is elegant for interactive commands but surprising in scripts ported from other shells. Important hazards:

- all destinations open immediately;
- a following external command may start before the multio helper finishes;
- `command >file | next` sends output to both, unlike most shells;
- redirection order changes what gets duplicated.

When completion of the fan-out matters, group the producer in braces so the parent waits as documented, or use an explicit `tee` and wait for the pipeline.

## Three process-substitution forms

- `<(list)` supplies a readable pipe/FIFO path;
- `>(list)` supplies a writable path and its consumer is asynchronous relative to the parent in important cases;
- `=(list)` materializes output in a temporary regular file, useful when the consumer seeks or closes inherited descriptors.

Use `=(...)` only where a real pathname is required. Its file is temporary and lifetime is syntax-dependent. Passing it as an argument to an immediately invoked anonymous function ties cleanup to the function:

```zsh
() {
  emulate -L zsh
  consumer "$1"
} =(producer)
```

If a job containing `=(...)` is disowned, the parent can forget the temporary file. Wrap the job in a subshell that remains responsible for cleanup.

## Waiting traps

`producer > >(consumer)` does not guarantee that a following command sees `consumer` finished. If the result matters, redesign around an explicit pipe/group, a temporary file, or a tracked PID. Do not add `sleep`.

Process substitution helpers can outlive the visible command and do not always appear in the ordinary job table as expected. Test completion order, error propagation, and cancellation.

## Fast file reads

`$(<file)` reads a file without forking and strips trailing newlines as command substitution does. Use it for bounded text files:

```zsh
local content
content=$(<"$file") || return
```

For binary/NUL data, large files, FIFOs, or bounded reads, use `zsh/system` `sysread` or an external binary-safe tool. Shell parameters cannot preserve NUL bytes as ordinary text.

## Here-documents and here-strings

Quote the here-doc delimiter to suppress expansion:

```zsh
command <<'EOF'
$literal $(not-run)
EOF
```

A here-string `<<< "$value"` adds a newline. Use `print -rn -- "$value" | command` when exact lack of a trailing newline matters, accepting the pipeline semantics.

Search terms: multios, process substitution, named file descriptor, `=(...)`, wait process substitution, `NO_CLOBBER`.
