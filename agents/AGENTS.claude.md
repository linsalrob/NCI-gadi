## Claude Code overlay

Everything above this heading is the shared base (`agents/AGENTS.md`), common to every CLI
agent. Everything from here down applies to Claude Code only and is appended when
`build.sh` builds `~/.claude/CLAUDE.md`. Edit this file, not the shared base, for anything
that applies to Claude Code and no other agent.

Claude Code loads `~/.claude/CLAUDE.md` as global user memory. It does **not** load
`AGENTS.md`, which is why `build.sh` installs the shared base plus this overlay at that path.

For the shared base's `<AGENT>` placeholders: this session's `<AGENT>` is `Claude`
(`CLAUDE` in all-caps contexts), so a PR re-review request is
`gh pr comment <current-pr> --body "@claude review"`.

### Tool use

- Prefer the dedicated tools over shell equivalents: `Read` over `cat`/`head`/`sed -n`,
  `Grep` over `grep`/`rg`, `Glob` over `find`, `Edit`/`Write` over `sed -i`/heredocs.
- Prefer `Edit` (patch-style) over `Write` (full-file rewrite); read a file before editing it.
- Batch independent tool calls into a single message so they run in parallel.
- Use the session scratchpad directory given in the environment context for temporary
  files.
- Use the todo list for multi-step work.

### Relationship to Claude Code's permission system

Claude Code enforces permissions through `~/.claude/settings.json` (and project
`.claude/settings.json`), not through this file. The shared base's "Standing approvals"
lists state policy: Claude proposes those commands without hesitation and does not propose
anything outside them, but the harness still prompts unless the same command is allowlisted
in settings. If a routine command prompts often, consider adding it to an allowlist (see the
`fewer-permission-prompts` skill).

### Documentation MCP servers

Whether Context7 or another documentation MCP server is available depends on the user's own
Claude Code setup; this repository configures none. Use the shared base's guidance only when
such tools are actually present in the session.

### Claude Code's built-in systems

Claude Code's own skills, subagents, persistent memory, and artifact tooling are documented
in its system prompt and are not restated here. This overlay adds only Gadi-specific policy
on top of that.
