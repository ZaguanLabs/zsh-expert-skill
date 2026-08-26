# Completion authoring

Use this section when writing or repairing a native completion function.

## File and registration

Create an autoload file named `_command` on `fpath` with a first line:

```zsh
#compdef command alias-command
```

Inside:

```zsh
_command() {
  local context state state_descr line
  typeset -A opt_args

  _arguments -C \
    '(-h --help)'{-h,--help}'[show help]' \
    '(-o --output)'{-o+,--output=}'[write to file]:output file:_files' \
    '1:subcommand:->subcommand' \
    '*::arguments:->args' && return 0

  case $state in
    subcommand)
      _describe -t commands 'subcommand' '(
        build:build artifacts
        inspect:inspect state
      )'
      ;;
    args)
      case $line[1] in
        build) _files -g '*.zsh(-.)' ;;
        inspect) _message 'no more arguments' ;;
      esac
      ;;
  esac
}
```

Use descriptions and tags; do not merely call `compadd` on raw words.

## `_arguments` design

- Encode mutual exclusion groups in parentheses.
- Use `+`/`=` forms that match whether option arguments may attach.
- Use `-C` for state transitions and update `curcontext` correctly.
- Use `*::` when the remainder is delegated based on a subcommand.
- On 5.9+, `_arguments -0` NUL-delimits values in `opt_args`, avoiding colon ambiguity.
- Return immediately when `_arguments` completes the request; otherwise handle `$state`.

For wrapper commands, `_normal` or service-command patterns can reuse another command's completion. Zsh 5.9.2 adds `_as_if`, which completes as if another command and prefix arguments were present.

## Generate matches with semantic helpers

- `_describe` for value/description pairs;
- `_values` for named values with arguments;
- `_alternative` for several tagged sources;
- `_files` rather than expanding globs yourself;
- `_path_files` only for specialized path behavior;
- `_wanted`/`_requested` when defining custom tags;
- `_guard` to validate positional forms;
- `_call_program` to run an external producer under user-configurable styles;
- `_cache_invalid`, `_retrieve_cache`, `_store_cache` for expensive stable data.

Never parse display-formatted output when a machine format exists. Force a stable locale only around the producer/parsing operation, as current Oh My Zsh does for Git status regexes.

## Command execution is a trust boundary

Completion runs while the user is editing a command and may run in attacker-controlled repositories. Avoid executing project files, package scripts, or arbitrary command substitutions. Bound time and output. Respect compsys `command`, `gain-privileges`, cache, and user configuration styles where applicable.

Quote every value passed through `_call_program` or an `eval`-using helper. Prefer arrays and direct invocation. Development-line `_call_program -q/-Q` is not in stable 5.9.2.

## Dynamic completion and caching

Cache keys must include everything that changes results: command version, target host/context, config path/mtime, repository root, and sometimes user identity. Never let a cache from `sudo` or another host leak into ordinary completion.

If generation fails, return a useful fallback (`_files`, static subcommands, or no matches) and avoid printing diagnostics over ZLE unless debugging is enabled.

## Test from the cursor's point of view

Cover:

- empty word, partial word, cursor in the middle;
- option before/after operands and `--`;
- attached and separate option arguments;
- aliases/wrappers and subcommands;
- spaces, colons, newlines, glob characters in candidates;
- no producer command, producer failure, slow producer, stale cache;
- user matcher-list, grouping, descriptions, and menu selection.

Use the upstream `comptest` style harness or a PTY; asserting helper text alone does not prove the right matches were offered.

Search terms: `_arguments`, `opt_args`, completion state, `_describe`, `_alternative`, `_call_program`, `#compdef`, `_as_if`.
