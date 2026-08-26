# Research source map

Use this section to verify a subtle claim, update the skill for a newer Zsh release, or inspect the expert implementation that motivated a pattern. The skill synthesizes these sources; it does not reproduce their manuals or code wholesale.

## Stable primary baseline

- [Zsh 5.9.2 release source](https://github.com/zsh-users/zsh/tree/zsh-5.9.2) — pinned stable semantics and tests. Researched commit `ddee3e7a751a4f03d5a1041fd44bb7af7bc0cebb` (2026-07-12).
- [Zsh manual, 5.9.2 release](https://zsh.sourceforge.io/Doc/Release/) — authoritative grammar, expansion, builtins, ZLE, completion, modules, and contrib documentation.
- [Zsh release notes](https://zsh.sourceforge.io/releases.html) — stable feature and compatibility changes.
- [Zsh FAQ](https://zsh.sourceforge.io/FAQ/) — authoritative explanations of shell differences, splitting, startup, and common traps.
- [A User's Guide to the Z-Shell](https://zsh.sourceforge.io/Guide/) by Peter Stephenson — deeper conceptual explanations and worked examples; older, so verify syntax against stable tests.

When behavior is unclear, inspect stable upstream tests rather than relying on memory:

- `Test/D04parameter.ztst`, `D05array.ztst`, `D06subscript.ztst`;
- `Test/D02glob.ztst`, `D03procsubst.ztst`, `D08cmdsubst.ztst`;
- `Test/C03traps.ztst`, `C04funcdef.ztst`, `E01options.ztst`;
- `Test/X*` for ZLE and `Test/Y*` for completion.

## Upstream development watch

- [Zsh upstream default branch](https://github.com/zsh-users/zsh) — future features and fixes. Researched commit `17af4a46c8983d9b1c164868fe30c0b0738c1e58` (2026-08-23), reporting `5.9.999.3-test`; treat it as post-5.9 development.
- [zsh-workers archive](https://www.zsh.org/mla/workers/) and [zsh-users archive](https://www.zsh.org/mla/users/) — design discussion and edge-case provenance. Confirm conclusions in merged docs/tests.

## Oh My Zsh corpus

- [Oh My Zsh repository](https://github.com/ohmyzsh/ohmyzsh) — framework lifecycle, plugin practices, completion dump invalidation, secure completion handling, async prompts, update locks, terminal integration, and directory-local trust. Researched commit `146461f7c6d95f4ba1220559d66eb113418b40a8` (2026-08-25).
- High-value files at that revision: `oh-my-zsh.sh`, `lib/async_prompt.zsh`, `lib/completion.zsh`, `lib/compfix.zsh`, `lib/termsupport.zsh`, `lib/diagnostics.zsh`, `tools/check_for_upgrade.sh`, and `plugins/dotenv/` plus its security tests.

OMZ is an implementation corpus, not the authority for core Zsh semantics. Some APIs are intentionally experimental/private, and some legacy plugins predate current best practices.

## Expert community implementations

- [Grml zsh configuration](https://github.com/grml/grml-etc-core/blob/master/etc/zsh/zshrc) — large, field-tested completion/style/hook configuration. Researched repository commit `da237eecc9a816024b069fb7d0d7ade81389c749` (2026-08-20).
- [zsh-lovers](https://github.com/grml/zsh-lovers) — mailing-list-derived examples of glob qualifiers, modifiers, redirections, `zmv`, and modules. Researched commit `892525cd3db53371b9261b4d4197bd1571d470da` (2026-08-09). Use as discovery material; many one-liners are intentionally playful or old and must be revalidated.
- [zsh-async](https://github.com/mafredri/zsh-async) — `zpty` worker, framed results, callback batching, cancellation, and watcher cleanup. Researched commit `ee1d11b68c38dec24c22b1c51a45e8a815a79756` (2023-01-05).
- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) — cancellable async requests, actual child PID transport, typed widget wrapping, and ZLE integration. Researched commit `85919cd1ffa7d2d5412f6d3fe437ebdbeeec4fc5` (2025-06-24).
- [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) — redraw-hook ordering, additive `region_highlight`, widget compatibility, highlighter modularity, and tests. Researched commit `2fc57d63067c18b1100ecdbf684fa5baf49459d1` (2026-08-21).
- [zsh-bench](https://github.com/romkatv/zsh-bench) — user-visible latency methodology and evidence against `time zsh -lic exit`/unsafe deferral as universal optimization. Researched commit `28b1b1bc888159f0a2cf50f9d29381758341aba1` (2026-04-27).

## Direct manual routes

- [Expansion](https://zsh.sourceforge.io/Doc/Release/Expansion.html)
- [Parameters](https://zsh.sourceforge.io/Doc/Release/Parameters.html)
- [Options](https://zsh.sourceforge.io/Doc/Release/Options.html)
- [Functions](https://zsh.sourceforge.io/Doc/Release/Functions.html)
- [Redirection](https://zsh.sourceforge.io/Doc/Release/Redirection.html)
- [Conditional expressions](https://zsh.sourceforge.io/Doc/Release/Conditional-Expressions.html)
- [Shell builtins](https://zsh.sourceforge.io/Doc/Release/Shell-Builtin-Commands.html)
- [Completion system](https://zsh.sourceforge.io/Doc/Release/Completion-System.html)
- [Completion widgets](https://zsh.sourceforge.io/Doc/Release/Completion-Widgets.html)
- [Zsh line editor](https://zsh.sourceforge.io/Doc/Release/Zsh-Line-Editor.html)
- [Zsh modules](https://zsh.sourceforge.io/Doc/Release/Zsh-Modules.html)
- [User contributions](https://zsh.sourceforge.io/Doc/Release/User-Contributions.html)
- [Startup files](https://zsh.sourceforge.io/Doc/Release/Files.html)

## Maintenance procedure

For a skill update:

1. pin the newest stable Zsh tag and read `NEWS` plus `README` incompatibilities;
2. diff relevant `Doc/Zsh/*.yo` and `.ztst` tests from the prior baseline;
3. inspect current OMZ core changes, not only its README;
4. re-run verified examples on the oldest supported and newest stable Zsh;
5. move stable features out of the development warning only after release;
6. retain commit/date provenance for community-derived architecture.
