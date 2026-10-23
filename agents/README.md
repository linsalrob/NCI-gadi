# Agent instructions

Shared instructions for AI coding agents (Claude Code and Codex CLI) on NCI Gadi. They cover
PBS Pro, Gadi queues and SU accounting, conda and inode limits, git safety rules, and where
to find reference databases such as the ColabFold MSA database under `if89`.

This is the Gadi counterpart of the `agents/` directory in
[linsalrob/pawsey](https://github.com/linsalrob/pawsey), which does the same for Setonix.

## What's here

| File | What it is |
|---|---|
| `AGENTS.md` | The main instructions every agent follows. Start here. |
| `AGENTS.claude.md` | Extra instructions for Claude Code only. |
| `AGENTS.codex.md` | Extra instructions for Codex CLI only. |
| `skills/` | Add-ons that let an agent ask ChatGPT or Claude for a second opinion. |
| `hooks/post-merge` | Git hook that reruns `build.sh` after every `git pull`. |
| `build.sh` | Installs everything into your home directory. |

## Install

### Optional: agent handoffs

The `ask-chatgpt` and `ask-claude` skills use a private GitHub repository for handoffs
between agents. To use them, create a private repository called `agent-handoffs`:

```bash
gh repo create agent-handoffs --private --clone
```

and add these lines to your `~/.bashrc`:

```bash
export AGENT_GH_OWNER=your-github-name
export AGENT_HANDOFF_REPO=your-github-name/agent-handoffs
```

If `AGENT_HANDOFF_REPO` is not set, the handoff skills are not installed and the installed
instructions tell the agent not to use them.

### Build

```bash
git clone git@github.com:linsalrob/NCI-gadi.git
NCI-gadi/agents/build.sh
```

This writes:

| Installed file | Built from |
|---|---|
| `~/.claude/CLAUDE.md` | `AGENTS.md` + `AGENTS.claude.md` |
| `~/.codex/AGENTS.md` | `AGENTS.md` + `AGENTS.codex.md` |
| `~/.claude/AGENTS.md` | `AGENTS.md` alone, for reference |
| `~/.claude/skills/*/SKILL.md`, `~/.codex/skills/*/SKILL.md` | `skills/*/SKILL.md` |

An existing file that `build.sh` did not write, or that has been edited since, is saved as
`<file>.bak.<date>` before it is replaced.

## Updating

Edit the files here, not the installed copies, then run `build.sh` again. After the first
run, `git pull` reinstalls automatically through the post-merge hook.

Files are copied, not linked, so the installed config does not depend on `/g/data` being
mounted or on uncommitted edits in the working tree.

Some of `AGENTS.md` is specific to the `ob80` project and its conda directory; change those
paths if you use this from another project.
