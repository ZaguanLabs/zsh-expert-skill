# Zsh Expert

Expert native Zsh engineering for coding agents.

Zsh Expert is an [Agent Skill](https://agentskills.io) for designing, reviewing,
debugging, and optimizing Zsh code. It gives an agent a Zsh-native mental model
for scripts, startup files, completions, ZLE widgets, prompts, plugins, framework
integrations, and asynchronous interactive code.

This is an agent skill, not a shell plugin: do not source it from `.zshrc`.

## Why use it?

Advice written for Bash or POSIX `sh` is often subtly wrong in native Zsh.
Zsh Expert steers an agent toward correct expansion semantics, scoped options,
composable hooks, safe completion setup, careful terminal handling, and tests
that exercise Zsh itself.

The skill is designed to produce code that is:

- native to Zsh without being needlessly cryptic;
- explicit about version, framework, execution context, and trust boundaries;
- isolated from the caller's aliases, options, traps, keymaps, and descriptors;
- compatible with existing hooks and interactive plugins;
- verified with `zsh -f` and, where needed, a pseudo-terminal.

## Coverage

| Area | Topics |
| --- | --- |
| Language and data | Execution order, arrays and set operations, expansion algebra, patterns, glob queries, arithmetic and custom math functions |
| Reusable programs | Functions, dynamic/private scope, option hygiene, statuses, traps, descriptors, parsing, native modules, jobs, sockets and persistent associations |
| Interactive systems | Startup files, compsys, completion authoring, ZLE, prompts, VCS state, hooks, plugin and framework lifecycles |
| Quality and boundaries | Performance, security, testing, debugging, profiling, Bash migration, version gates |

The core instructions route the agent to the smallest relevant subset of 26
focused reference chapters, with a separate manual coverage record. Security
and testing guidance are added for work that crosses multiple areas.

## Install

You need an Agent Skills-compatible host. The instructions below use the local
skill locations supported by Codex; see OpenAI's
[Build skills](https://developers.openai.com/codex/skills) guide for the full
discovery model.

### Personal installation

Install the skill once for use across repositories:

```zsh
mkdir -p "$HOME/.agents/skills"
git clone https://github.com/ZaguanLabs/zsh-expert-skill.git \
  "$HOME/.agents/skills/zsh-expert"
```

### Repository-scoped installation

Add it to a project when the skill should travel with that repository:

```zsh
mkdir -p .agents/skills
git submodule add https://github.com/ZaguanLabs/zsh-expert-skill.git \
  .agents/skills/zsh-expert
```

Codex detects skills in `.agents/skills` from the working directory through
the repository root, as well as personal skills in `$HOME/.agents/skills`. If
the skill does not appear after installation, restart Codex.

## Use

Invoke the skill explicitly by mentioning it in your prompt:

```text
$zsh-expert Review this plugin for option leakage and hook conflicts.
```

```text
$zsh-expert Write a stateful completion function for this CLI.
```

```text
$zsh-expert Diagnose why this async ZLE widget sometimes redraws stale output.
```

```text
$zsh-expert Port this Bash script to idiomatic native Zsh 5.9.
```

Codex can also select the skill automatically when a request clearly concerns
Zsh. In Codex CLI or the IDE extension, use `/skills` to confirm that
`zsh-expert` is available.

## How it works

[`SKILL.md`](SKILL.md) establishes the working contract and the invariants an
agent should preserve. It then routes the task to focused material in
[`references/`](references/) instead of loading the entire knowledge base for
every request. This progressive-disclosure structure keeps routine tasks lean
while retaining depth for security, interactive behavior, performance, and
version-sensitive work.

```text
zsh-expert/
├── SKILL.md                 # Required metadata, workflow, and routing
├── agents/openai.yaml       # Display metadata and default prompt
├── references/              # 26 chapters plus manual coverage record
├── scripts/verify-zsh.zsh   # Parse and opt-in smoke-test helper
├── scripts/test-semantics.zsh # Native behavior regression checks
├── LICENSE
└── README.md
```

The references separate core Zsh semantics, Zsh's contributed systems such as
compsys and ZLE, and optional framework-specific behavior.
[`references/24-source-map.md`](references/24-source-map.md) maps the research
to authoritative upstream material.

## Research foundation

Oh My Zsh was a major source of inspiration and a valuable implementation
corpus for this skill. Its mature handling of startup order, plugin lifecycles,
completion caches, asynchronous prompts, terminal state, updates, and security
helped identify engineering patterns worth teaching.

Those lessons were generalized into native Zsh guidance and checked against
upstream Zsh semantics. Oh My Zsh is neither a dependency nor the skill's
primary target; framework-specific behavior is called out explicitly where it
matters.

A subsequent review processed all 200 files in a supplied Zsh HTML corpus,
including the release manual, older introduction, indexes, and redirects.
The resulting guidance emphasizes compositions: array reconciliation, literal
pattern construction, programmable glob queries, shell-aware editing, completion
grammars, numeric APIs, and module-backed applications. The
[coverage record](references/27-manual-coverage.md) explains what informed each
area and which earlier semantic claims were corrected.

## Versioning

The current version is **v1.0.1**, expanding native Zsh design guidance and
correcting semantics through a comprehensive manual review and runtime checks.

This project follows [Semantic Versioning](https://semver.org/). The release
number is stored as a string in `SKILL.md` under `metadata.version` and mirrored
by a matching Git tag. Agent Skills clients may use custom metadata differently,
so the Git tag remains the portable release marker.

## Verify Zsh files

The bundled helper parses one or more files with an isolated Zsh:

```zsh
scripts/verify-zsh.zsh path/to/file.zsh another-file.zsh
```

Add `--smoke` to execute each file under `zsh -df` with a temporary `ZDOTDIR`:

```zsh
scripts/verify-zsh.zsh --smoke path/to/safe-script.zsh
```

Smoke mode executes the supplied files. Use it only for code you trust and
expect to run non-interactively. Completion, ZLE, prompt, signal, and job-control
behavior still requires a pseudo-terminal test that asserts visible state.

## Contributing

Keep the core skill concise and route detailed material into the relevant
reference chapter. When behavior varies by Zsh version, distinguish stable
5.9/5.9.2 behavior from post-5.9 development and link authoritative evidence
in the source map.

Before submitting changes:

1. Parse changed Zsh files with `zsh -n` or `scripts/verify-zsh.zsh`.
2. Run safe non-interactive examples with `scripts/verify-zsh.zsh --smoke`.
3. Test interactive changes in a pseudo-terminal.
4. Check that links from `SKILL.md` and this README still resolve.
5. For changes to semantic guidance, run `zsh -df scripts/test-semantics.zsh`.

## License

Licensed under the [Apache License 2.0](LICENSE).
