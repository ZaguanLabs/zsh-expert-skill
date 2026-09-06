# Local manual corpus review

Research record for the 2026-09-06 skill revision. Use this when auditing coverage or repeating the research, not as an additional default context load. The engineering guidance is routed from `SKILL.md` and [24-source-map.md](24-source-map.md).

## Corpus accounting and method

Source: `~/dev/ai/zaguan/PowerHouse/inspiration/zsh/zsh_html/`.

All 200 HTML files were inventoried, read by the extraction pass, and parsed. The corpus contains 26 numbered manual chapters, 21 older introduction files, six indexes, three navigation/document-information pages, and 144 redirect stubs. The release pages identify Zsh 5.9.2, generated 2026-07-12. Extracted text, including navigation and index entries, contains approximately 249,000 whitespace-delimited words; this is not a count of unique manual prose.

The review used chapter-wide structural and paragraph surveys, followed by detailed rereads of the sections driving changes and direct runtime probes. Redirects were resolved to their destination chapter and anchor; all 144 resolved within the supplied directory. Indexes were treated as discovery/cross-reference material, not additional independent explanations. Historical introduction examples were checked against release semantics before adoption. This is a coverage and synthesis record, not a claim that every documented behavior has been runtime-tested.

No manual text or HTML corpus is bundled with the skill. The local source path is provenance only; agents can use installed manuals or the public upstream links without that directory.

## Numbered manual chapters

| Source HTML | Ideas retained or disposition | Guidance |
| --- | --- | --- |
| `The-Z-Shell-Manual.html` | Documentation generation and version identity; provenance rather than programming rules. | 24, this record |
| `Introduction.html` | Authority hierarchy and upstream discovery; mailing-list/site references are follow-up sources. | 24 |
| `Roadmap.html` | Native patterns, functions, contrib utilities, and extensible editing as design choices. | SKILL, 23, 26 |
| `Invocation.html` | Native/emulated execution contract, option parsing before execution, restricted-shell limitations. | 01, 19, 21 |
| `Files.html` | Startup/shutdown ordering, configurable global paths, unavoidable global zshenv. | 11, 20 |
| `Shell-Grammar.html` | Parsing versus execution, pipeline scope, multi-variable loops, case fallthrough/retesting, try/always limits. | 01, 02, 05, 06 |
| `Redirection.html` | Descriptor ownership, multios ordering/waiting, redirection-only command policy. | 07, 10 |
| `Command-Execution.html` | Command identity, dispatch modes, process boundaries. | 01, 21 |
| `Functions.html` | Autoload lifecycle, compiled lookup, anonymous scopes, shell hook statuses, function/list traps. | 05, 06, 17, 18 |
| `Jobs-_0026-Signals.html` | Foreground/background ownership, process groups, disown and cleanup, signal behavior. | 06, 10, 20 |
| `Arithmetic-Evaluation.html` | Numeric types, promotion, native precedence, custom arithmetic APIs. | 25 |
| `Conditional-Expressions.html` | Literal versus pattern/regex tests, captures, numeric evaluation boundaries, filename-generation context. | 03, 04, 19, 25 |
| `Prompt-Expansion.html` | Expansion order, native conditions, truncation, non-recursive `psvar` insertion. | 15 |
| `Expansion.html` | Array shape, phase order, set/zip/product operations, quoting by interpreter, computed matches and glob queries. | 02, 03, 04, 07, 08, 23 |
| `Parameters.html` | Native whole-array semantics, subscript miss sentinels, dynamic scope, ties, special names, time and context parameters. | 01, 02, 05, 25 |
| `Options.html` | Options as semantic contracts, parse-time versus local settings, loop/error policies, NUL handling, history consistency. | 01, 05, 06, 08, 17, 20, 21 |
| `Shell-Builtin-Commands.html` | Declaration phases, sticky emulation, feature loading, `functions -M`, `read` readiness, explicit output APIs. | 01, 05, 08, 09, 25 |
| `Zsh-Line-Editor.html` | Keymap alias/copy distinction, editor state, undo, paste, widget metadata, descriptor callbacks. | 10, 14, 15, 20 |
| `Completion-Widgets.html` | Candidate versus display identity, prefix/suffix surgery, matching grammar, automatic restoration. | 12, 13 |
| `Completion-System.html` | Context/tag/style policy, parser helpers, related-field completion, source-specific matching, caching. | 12, 13, 16, 23 |
| `Completion-Using-compctl.html` | Compatibility and old completion architecture; preserve when required, prefer compsys for new maintained work. | 12, 21, 26 |
| `Zsh-Modules.html` | Capability-driven adapters, byte I/O, stable private locals, persistent associations, terminal/network systems. | 05, 07, 09, 10, 25, 26 |
| `Calendar-Function-System.html` | Reusable date predicates, parser/locale limits, cooperative scheduling, recurrence identity. | 04, 26 |
| `TCP-Function-System.html` | Session identity, maps, hooks, framing, logging, partial-line blocking limitations. | 10, 26 |
| `Zftp-Function-System.html` | Session-local state, caching, reconnect/transfer lifecycles; retained as a legacy protocol option. | 26 |
| `User-Contributions.html` | `zmv`, `zargs`, shell-word editing, word styles, dynamic directories, named exceptions, prompt/VCS/configuration protocols, diagnostics. | 04–06, 13–18, 20, 23, 25, 26 |

Numbers refer to the correspondingly numbered files in this directory. Their purpose is to route decisions, not reproduce each manual entry as a skill rule.

## Older introduction and discovery material

The complete older introduction consists of `intro.html` and `intro-1.html` through `intro-20.html`:

| Files | Subject and treatment |
| --- | --- |
| `intro.html`, `intro-1.html`, `intro-20.html` | Attribution, orientation, closing comments; historical provenance. |
| `intro-2.html` | Glob traversal, exclusion, numeric patterns, qualifiers; distilled into selection/query design. |
| `intro-3.html` | Startup files; defer to the release chapter for current details. |
| `intro-4.html` | Functions and autoloading; extract reuse and parse-time alias lessons, not old unsafe examples. |
| `intro-5.html`, `intro-6.html` | Named directories and directory stacks; use current hook and naming APIs. |
| `intro-7.html`, `intro-8.html` | Process substitution and multios; retain composition ideas with current lifetime/wait rules. |
| `intro-9.html` | Alias convenience and hazards; distinguish interactive macros from reusable functions. |
| `intro-10.html` | History designators and editing; interactive convenience rather than program serialization. |
| `intro-11.html`, `intro-14.html` | Editing and bindings; replace key-sequence tricks with current widget APIs where appropriate. |
| `intro-12.html`, `intro-13.html` | Legacy completion and argument context; transfer the grammar idea to compsys. |
| `intro-15.html`, `intro-16.html` | Expansion and shell parameters; native arrays and typed/tied state, with release-verified semantics. |
| `intro-17.html` | Prompt presentation; prefer current prompt escapes and explicit display-data boundaries. |
| `intro-18.html` | Session watching; specialized interactive capability in reference 26. |
| `intro-19.html` | Options; treat them as explicit semantic choices rather than a universal configuration bundle. |

The six discovery indexes are `Concept-Index.html`, `Editor-Functions-Index.html`, `Functions-Index.html`, `Options-Index.html`, `Style-and-Tag-Index.html`, and `Variables-Index.html`. `index.html`, `zsh_toc.html`, and `zsh_abt.html` supply the title, contents, navigation, generation metadata, and documentation notices. They do not require separate engineering chapters.

Redirect stub accounting by destination: Shell Grammar 9; Completion Using compctl 8; ZLE 13; Expansion 16; Parameters 5; Introduction 7; Completion System 7; Calendar 5; Invocation 2; Completion Widgets 5; Options 4; User Contributions 19; Zftp 3; TCP 4; Modules 37. Total: 144. Redirect aliases such as `Array-Parameters.html` and `The-zsh_002fparam_002fprivate-Module.html` were resolved into those chapter sections rather than counted as separate manuals.

## Corrections that matter to generated code

- Native `$array` expands the array, not element 1; quoting determines joining and preservation of empty elements.
- A foreground pipeline's final shell component can retain state in native Zsh.
- `:c` resolves a command path; capitalization is `(C)`.
- Expansion `(R)` and subscript `(R)` have different meanings; uniqueness precedes expansion sorting.
- Embedded NUL is supported inside native parameters and builtin I/O; external argv/environment remains the boundary.
- `zsh/param/private` is present in the stable release documentation, with a significant module-load/parse-order constraint.
- `widgets`/`keymaps` belong to `zsh/zleparameter`; `zsh/files` has prefixed filesystem builtins but no `cp`.
- `emulate -L` is not parse-time alias isolation, and a completion function should preserve the compsys option environment.
- `read -t` is not a complete-record deadline; FD readiness can precede a terminator indefinitely.
- `always` has process-exit/parse-error limits, and a signal function trap's incoming status need not be the signal status.
- `Y` limits traversal candidates, not a globally sorted top-N result.

## Validation boundaries

The maintained checks in `scripts/test-semantics.zsh` exercise array boundaries, literal filtering and membership, nested expansion shape, quoting/serialization, NUL I/O, partial-frame readiness, pipeline state/status, cleanup, arithmetic, private scope, glob selection, alias-safe autoloading, prompt insertion, and optional GDBM persistence. Run them on each supported runtime; a skip is not proof of a module's behavior.

The review environment used Zsh 5.9.2 on Mageia Linux. The semantic suite passed 83 assertions. Separate PTY probes confirmed the documented completion example's subcommand and file selection, quoting of a candidate containing spaces and metacharacters, spelling-preserving shell-word splitting with complete and incomplete quotes, and editor responsiveness while a watched descriptor held an incomplete frame with its writer still open. These probes do not establish full plugin interoperability or cross-version behavior.

GDBM was unavailable in that build, so its example was syntax-checked and reviewed against the supplied manual; the persistence test reports a skip. Specialized systems such as curses, remote TCP/FTP sessions, and capability mutation were not exercised merely to populate this skill. Their references provide selection criteria and direct manual routes, not claims of end-to-end validation.
