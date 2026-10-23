## Codex CLI overlay

Everything above this heading is the shared base (`agents/AGENTS.md`), common to every CLI
agent. Everything from here down applies to Codex CLI only and is appended when `build.sh`
builds `~/.codex/AGENTS.md`. Edit this file, not the shared base, for anything that applies
to Codex CLI and no other agent.

For the shared base's `<AGENT>` placeholders: this session's `<AGENT>` is `Codex` (`CODEX`
in all-caps contexts), so a PR re-review request is
`gh pr comment <current-pr> --body "@codex review"`.

### Standing approvals

Codex may run the commands listed under the shared base's "Standing approvals for routine
commands" without asking for additional approval when they are relevant to the task and
used non-destructively. This does not override the sandbox, network, or approval policy set
in `~/.codex/config.toml`.

GitHub network failures inside a restricted sandbox may be retried with the environment's
required network elevation rather than treated as an authentication failure.

### Codex CLI GitHub helper scripts

Codex CLI ships GitHub helper scripts in its plugin cache. These are approved with
Python 3.11:

```text
python3.11 ~/.codex/plugins/cache/openai-curated-remote/github/*/skills/gh-fix-ci/scripts/inspect_pr_checks.py ...
python3.11 ~/.codex/plugins/cache/openai-curated-remote/github/*/skills/gh-address-comments/scripts/fetch_comments.py ...
```

These paths exist only under Codex's own home directory. Do not assume an equivalent script
exists elsewhere unless you have located it.

If the user has asked Codex to address PR review feedback and a review thread has been
addressed by the pushed change, Codex may mark that specific thread as resolved. Do not
resolve informational, disputed, ambiguous, or unaddressed threads.

### Tool use

Codex has no session scratchpad. Put temporary files in a task-specific directory under
`/scratch/<proj>/$USER/tmp`, as the shared base's "Tool use" section describes.

### Context7 MCP

No Context7 (or other) MCP server is configured for Codex CLI by this repository. Treat the
shared base's documentation-MCP guidance as inactive until an MCP config wires one up, and
fall back to official version-matched documentation.
