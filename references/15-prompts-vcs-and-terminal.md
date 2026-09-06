# Prompts, VCS, and terminal state

Use this section for prompt escapes, asynchronous VCS information, width accounting, terminal capabilities, and command titles.

## Prompt layers

Prompt strings can undergo:

1. parameter assignment/quoting when configured;
2. parameter/command/arithmetic expansion if `PROMPT_SUBST` is set;
3. prompt escapes controlled by `PROMPT_PERCENT`/`PROMPT_BANG`;
4. terminal rendering with zero-width escape regions.

Treat repository branch names, virtualenv names, host-provided text, and command strings as untrusted display data. Escape percent signs when text will undergo prompt expansion and avoid feeding data into `PROMPT_SUBST` syntax.

Wrap raw zero-width terminal escapes in `%{...%}` and keep cursor-motion effects outside ordinary prompt segments. Prefer `%F{color}`/`%f`, `%K{color}`/`%k`, and `%B`/`%b` over hard-coded ANSI when prompt escapes suffice.

## Preserve the incoming status

`precmd` work overwrites `$?`. Capture it immediately and pass it to prompt computation:

```zsh
acme::precmd() {
  local -i last_status=$?
  acme::refresh_prompt "$last_status"
}
```

Async requests should receive that status explicitly. A child cannot reconstruct the user's previous command status after the parent runs more commands.

## `vcs_info` for composable synchronous prompts

```zsh
autoload -Uz vcs_info add-zsh-hook
zstyle ':vcs_info:git:*' formats '%b'
acme::precmd() { vcs_info }
add-zsh-hook precmd acme::precmd
PROMPT='%n@%m %~ ${vcs_info_msg_0_}%# '
setopt prompt_subst
```

`vcs_info` is configured through contexts and supports hooks with `hook_com`, `user_data`, and a return protocol. Use public `vcs_info*` APIs; `VCS_INFO_*` functions are internal.

VCS checks can dominate prompt latency in large/network filesystems. Disable unused backends and features through styles. Use async computation when the stale-then-refresh experience is acceptable.

## Async prompt invariants

- Render a fast baseline immediately.
- Tag each request with directory/repository identity and a monotonically increasing generation.
- Cancel the previous request on a new prompt.
- Ignore stale results.
- Store output separately from prompt code.
- Repaint through `zle .reset-prompt`/`zle -R`, never from a child.
- Coalesce multiple results before repaint.
- Clean up FD, PID, watcher, and partial buffer.

Oh My Zsh's async prompt layer stores per-handler FDs/PIDs/output, cancels prior requests, uses `sysparams[pid]`, and registers `zle -F`. Its API is explicitly unstable; learn the lifecycle, not the private function names.

## Terminal titles and escape sequences

Only write terminal control sequences to a tty. Sanitize BEL, ESC, C0/C1 controls, and title terminators from dynamic text. For preexec hooks, use the tokenized command only for display and limit its length.

Terminal capability detection is imperfect. Respect `TERM`, `terminfo`, `COLORTERM`, multiplexers, and opt-out settings. Do not assume OSC 8 hyperlinks or truecolor merely because one terminal brand usually supports them.

Use `echoti`/terminfo for portable capabilities when available. If emitting ANSI/OSC directly, provide a conservative fallback and do not query the terminal from noninteractive shells.

## Prompt width and multibyte text

ZLE needs correct printable width. `%{...%}` marks nonprinting sequences, not zero-width Unicode. Combining characters, emoji, East Asian width, and fonts can still produce display discrepancies. Keep truncation based on prompt escapes (`%<...<`) when possible and test in actual target terminals.

## Use prompt grammar for presentation

Native conditionals can handle success/failure, privileges, jobs, directory depth, and available text without command substitution. `%D{...}` supplies formatted time; `%<...<`/`%>...>` truncate a region, and `%<<` ends that truncation region. Keep reset sequences outside text that might disappear. This often removes both forks and per-prompt condition code.

When the component owns the prompt and its `psvar` slots, put dynamic display text in `psvar` and refer to it with `%1v`, `%2v`, etc. A fixed prompt template such as `'%(?.%F{green}.%F{red})%1v%f %# '` separates status/style syntax from data. `psvar` text is inserted without recursively treating its percent signs as prompt escapes; it still needs terminal-control sanitization. Do not appropriate another theme's slots. A plugin that does not own the prompt should expose data/render APIs for the theme to integrate.

The contributed `promptinit` theme system provides setup/preview/restore conventions; inspect those when integrating a theme there instead of adding an independent lifecycle. `zformat` offers named substitutions and conditional formatting for other renderers without needing `eval` or the full prompt engine.

Search terms: prompt expansion, `PROMPT_SUBST`, `vcs_info`, async prompt, zero-width escapes, terminal title, `precmd` status, `psvar`, `zformat`, `promptinit`.
