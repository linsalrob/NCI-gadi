# Shared Agent Guidance for NCI Gadi (installed as `~/.codex/AGENTS.md`, `~/.claude/CLAUDE.md`)

Global working agreements for AI coding agents (Codex CLI, Claude Code) on NCI Gadi. These
instructions apply when no more specific project or directory guidance overrides them.

## Scope and provenance

- This file is the shared base. It lives in `agents/AGENTS.md` in the
  `linsalrob/NCI-gadi` repository and is installed by `agents/build.sh`.
- `build.sh` appends an agent-specific overlay (`agents/AGENTS.codex.md` or
  `agents/AGENTS.claude.md`) and installs the result as `~/.codex/AGENTS.md` and
  `~/.claude/CLAUDE.md`. The overlay names the agent and covers anything that applies to
  one agent only.
- `<AGENT>` below (and in the `ask-chatgpt` / `ask-claude` skills) is a placeholder for the
  agent running the session; the overlay says what it is.
- Do not edit the installed copies. Edit the sources, commit, push, and rerun
  `agents/build.sh`.

## Instruction precedence

- System, harness, sandbox, permission-mode, and execution-environment requirements take
  precedence over this file.
- Then follow explicit user instructions for the current task.
- Then follow the nearest project or subdirectory instruction file that the agent reads
  (`AGENTS.md` for Codex; `CLAUDE.md`, `.claude/CLAUDE.md` and imported `@path` files for
  Claude Code).
- Use this global file as the default when no more specific instruction applies.
- Project-specific instructions may specialise these defaults but must not weaken safety
  rules concerning secrets, destructive operations, or unrelated user changes.
- When instructions conflict, identify the conflict and follow the more specific
  non-destructive instruction.

## Core operating principles

- Begin by identifying:
  1. the goal and acceptance criteria;
  2. constraints involving scope, safety, time, compute, or data;
  3. the files, commands, tests, documentation, or external sources that must be inspected;
  4. whether the request depends on current or version-specific information.
- Prefer safe, reversible, and workspace-scoped actions.
- Perform useful read-only inspection before asking questions.
- Ask a focused question only when the answer would materially change the implementation or
  when proceeding could cause destructive or difficult-to-reverse consequences.
- Otherwise, make the narrowest reasonable assumption, state it when material, and continue.
- Do not claim that a command, test, build, deployment, or validation succeeded unless it
  was actually run successfully.
- Use the agent's plan or todo list for multi-step work so progress is visible; skip it for
  trivial or single-step tasks.

## Accuracy, recency, and sourcing

When a request depends on recency, including words such as "latest", "current", "today", or
"as of now":

1. Establish the current date and time.
   - Preferred local command: `date -Is`.
   - State the relevant date explicitly when it affects the answer.

2. Prefer official and primary sources:
   - upstream vendor documentation;
   - versioned language, framework, library, cloud, or tool documentation;
   - release notes and changelogs;
   - standards, specifications, research papers, or official advisories.

3. Prefer the most recent authoritative information:
   - confirm the target version;
   - use documentation matching that version;
   - record publication, release, or advisory dates when relevant;
   - cross-check multiple authoritative sources when details are safety-, security-, or
     compatibility-sensitive.

### Documentation MCP servers

- Use a documentation MCP server (for example Context7) when one is connected and
  appropriate for targeted library or API documentation; otherwise use official
  version-matched documentation.
- If known, pin the library explicitly, for example `/supabase/supabase`.
- State or determine the target version.
- Retrieve only the documentation needed for the task.
- Summarise relevant details rather than copying large documentation sections.

### Web search policy

- Use web search and fetch tools when they materially improve correctness, such as for current
  APIs, security advisories, release notes, compatibility changes, or recent external
  information.
- Prefer official documentation and primary sources.
- Use reputable, widely cited secondary sources only when primary sources are unavailable or
  insufficient.
- Include publication, release, or advisory dates in the response when they materially
  affect the conclusion.

## External AI collaboration

The `ask-chatgpt` and `ask-claude` skills exist to hand a question to an external model
through GitHub.

- Invoke them when the user asks ("Ask ChatGPT", "Ask Claude", or the explicit slash
  command).
- Also invoke them proactively when a consequential scientific, strategic, or design
  decision would materially benefit from a second model's input — for example a
  methodological choice that would be expensive to reverse, an ambiguous biological
  interpretation, or a significant architectural fork.
- Do not use them for routine implementation questions that can be resolved by reading the
  code, the data, or the documentation.
- Never include secrets, credentials, or identifiable/embargoed research data in a handoff.

## Existing workspace state

- Assume uncommitted changes belong to the user.
- Never revert, delete, overwrite, reformat, stage, or commit unrelated changes.
- Inspect `git status` and relevant diffs before editing a repository.
- Identify whether requested changes overlap existing user modifications.
- Preserve both sets of changes where possible and clearly report any conflict.
- Do not use destructive cleanup commands such as `git reset --hard`, `git clean -fd`, or
  broad recursive deletion unless explicitly requested.
- Do not remove or replace files merely because they appear unused without confirming they
  are within scope.

## Default autonomy and safety

- Default to read-only exploration and analysis until edits are required.
- When editing, keep changes inside the intended workspace or repository.
- Prefer the smallest safe action that completes the requested task.
- Do not modify production systems, production data, remote services, or external resources
  unless the user explicitly requests that operation.
- Use preview, validation, or dry-run modes when they are supported and materially useful.
- Never perform destructive remote operations merely because credentials or authenticated
  tools are available.
- A permission mode that auto-accepts edits is not authorization for destructive or remote
  operations; it only removes the prompt for actions already in scope.

## Execution environment

- Use the repository's existing environment and tooling conventions.
- Prefer existing Docker, Apptainer/Singularity, Conda/Mamba, uv, virtualenv, Nix, module,
  or task-runner workflows over creating a new environment.
- We are a member of if89 and so we can add additional modules using `module use /g/data/if89/apps/modulefiles`
- Do not install system packages or modify host configuration unless explicitly instructed.
- Use an isolated environment when dependencies must be installed.
- Do not introduce Dockerfiles, container definitions, lockfiles, or environment manifests
  unless they are required by the task or requested by the user.
- If the repository already has a container or environment workflow, follow it.
- For HPC repositories, respect documented scheduler, module, filesystem, accelerator, and
  container conventions.
- Do not assume Docker is appropriate on an HPC system when Apptainer/Singularity,
  environment modules, or a scheduler-native workflow is established.
- Do not run heavy computation on a login node; submit through the scheduler or use an
  interactive allocation.

### conda and mamba

- mamba is installed
- you can activate any mamba environment
- you are able to create any new environments as appropriate to install software
- mamba preferred over conda, but both work
- **On Gadi, every conda environment must be recorded in
  [linsalrob/agent-handoffs#26](https://github.com/linsalrob/agent-handoffs/issues/26)**
  ("conda and inodes on Gadi"). Environments in `/g/data/ob80/re3494/conda` consume the
  project's inode quota. Read the issue before creating an environment, and reuse one
  that is already listed when it fits. Post a comment when you create an environment,
  giving its name, path, purpose and the project that needs it, and post again when it
  is no longer needed. Only environments the issue marks as no longer needed may be
  deleted to reclaim inodes; never delete one on the strength of its looking unused.
  Agents that are not on Gadi can ignore the issue.
- **Any agent on Gadi is authorised to run `mamba clean --all --yes` to free inodes**,
  provided no mamba or conda process is running as `$USER`. `pkgs_dirs` and `envs_dirs`
  are both `/g/data/ob80/re3494/conda`, so the package cache builds up beside the
  environments. The clean removes only tarballs and the unpacked packages that no
  environment links to. Check for running processes by PID first (see "Never kill
  processes by pattern" below for why `pgrep -f` is unreliable):

  ```bash
  ps -u "$USER" -o pid,args --no-headers | awk '/(mamba|conda|micromamba)( |$)/ && !/awk/'
  ```

  Run the clean only if that prints nothing. This covers the current login node only, so
  also check `qstat -u $USER` for jobs that may be installing packages. Record the
  result on agent-handoffs#26. This authorisation does not extend to deleting
  environments.

### NCI Gadi (PBS Pro) specifics

- **Querying a job array requires the `[]` suffix.** `qstat <jobid>` on an array parent
  returns `qstat: Unknown Job Id`, which looks exactly like a job that vanished or was
  rejected. It is a query-syntax artifact, not a failed job. Use:

  ```text
  qstat -u $USER              # arrays appear as 178061911[].gadi-pbs
  qstat -t '178061911[]'      # lists the parent and every subjob with its state
  ```

  Before concluding an array job failed, re-check with `qstat -u $USER`. Do not resubmit the
  work as individual jobs on the basis of a bare `qstat <jobid>` failure — that duplicates
  the run, and two jobs writing the same output directory can collide.
- Array jobs must be submitted as **rerunable**: without `#PBS -r y`, `qsub -J` is refused
  with `qsub: cannot submit non-rerunable Array Job`. Gadi defaults to `-r n`.
- **`max_array_size = 10`.** Far smaller than `max_queued = 1000` suggests, and a wider
  array is refused outright rather than queued. Work around it by having each subjob handle
  a block or a stride of the real work — strided chunk assignment for a download job, a
  `CHUNK_START` offset for a GPU job — not by submitting more subjobs.
- **`#PBS -o` paths containing `^array_index^` collide when several arrays are in flight**,
  because the token expands to the same value in each of them. Include a per-array prefix in
  the path. Note also that `^array_index^` only expands for an actual array job: leave it in
  a non-array script and it is written literally.
- `gpuvolta` is a V100 (compute capability **7.0**, 32 GB) queue, 4 GPUs / 48 cores / 384 GB
  per node; request `ncpus=12, ngpus=1` per GPU. Billing is by CPU (3 SU/CPU-hour), so one
  GPU-hour costs 36 SU. `dgxa100` is A100 (sm_80) but is limited to 1 running job per user.
- **`CUDA_VISIBLE_DEVICES` is unset inside a GPU job.** PBS restricts device visibility by
  cgroup instead, so a framework that falls through to PyTorch's own device count gets the
  right answer. Do not set the variable by hand to "fix" the empty value — that is how you
  hide the GPU you were allocated.
- **A GPU job dying with `Bus error` (SIGBUS) is usually `/dev/shm` exhaustion by DataLoader
  workers, not GPU OOM.** The symptom is deceptive: the job reports GPU memory pinned at
  31.5 GB of a 32 GB V100 and dies, which reads exactly like an out-of-memory kill and sends
  you looking for a bigger card. It is not. PyTorch `DataLoader` workers pass tensors through
  POSIX shared memory, the PBS cgroup gives `/dev/shm` far less than the node's RAM, and the
  worker's write fails as SIGBUS rather than as a clean allocation error. The bigger the
  per-sample tensors — long sequences, deep MSAs — the sooner it fires, so it appears only on
  the largest inputs and looks size-related.

  Diagnose it by the exit signature, not the memory figure: a real CUDA OOM raises
  `torch.cuda.OutOfMemoryError` with an allocation summary, whereas this leaves only
  `Bus error` from the shell and no Python traceback. The fix is `--num_workers 0` (or
  whatever the tool's equivalent is), which removes the shared-memory path entirely; it costs
  little for GPU-bound inference. 158 of 2,464 co-folding jobs failed this way and **all 158
  succeeded on the same GPU with workers disabled and nothing else changed.** Reach for
  `num_workers 0` before requesting a larger GPU or a smaller batch. (The shared-memory
  mechanism is inferred from the exit signature and from the fix working, not from a direct
  measurement of `/dev/shm` inside the failing job; a truncated memory-mapped file on a
  network filesystem can also raise SIGBUS. The remedy is the same either way, but say
  "consistent with" rather than "caused by" unless you have checked.)
- **Make the worker count a variable in any job script that wraps an ML tool**, so this can
  be changed at resubmission without editing a script that queued jobs have already
  snapshotted.
- **Compute nodes have no outbound network, and no queue has both GPUs and internet.**
  Anything that needs the internet (model weights, MSA servers, package installs, dataset
  downloads) must be staged beforehand from a login node or the `copyq` queue, both of which
  do have access. Cache models from a login node and run the job with `HF_HUB_OFFLINE=1`, so
  a missing cache fails loudly instead of hanging on a network call that cannot succeed.
- **`copyq` is capped at 10 hours for a 1-CPU job**, and `qsub` rejects anything longer. Work
  that moves more data than fits in one window must be incremental and resumable across
  submissions rather than relying on a single long transfer.
- **SU are granted per quarter and do not carry over — check `nci_account -P <proj>` before
  costing any multi-week plan.** The report's first line names the period (`Period=2026.q3`)
  and gives Grant / Used / Reserved / Avail; quarters end 31 Mar, 30 Jun, 30 Sep, 31 Dec.
  Whatever is in `Avail` on the last day is lost, so "this costs 70% of the allocation" is
  meaningless without the days remaining beside it: a plan spanning a quarter boundary is
  not one budget but this quarter's remainder plus next quarter's grant. Two consequences,
  in opposite directions — near a boundary an expiring balance is worth spending down by
  widening concurrency, because the constraint flips from SU to wall-clock and queue limits;
  and a long plan costed against a single `Avail` figure is understating what it needs. The
  same report also prints storage and **inode** use per filesystem, which is the cheapest
  way to check the quota that bites before disk does.
- Job cost is CPU-hours, not GPU-hours: `ncpus × walltime_hours × 3 SU`. A 12-CPU, 3-hour
  `gpuvolta` job is 108 SU regardless of how little of the GPU it uses.
- Pin CUDA-dependent wheels to a build that still ships `sm_70` if the target is `gpuvolta`;
  current default PyTorch wheels (CUDA 12.8+) have dropped Volta support.
- PBS copies the job script at submit time, so editing a submitted script does not change
  what a queued job runs.
- Always pass `-l storage=gdata/<proj>+scratch/<proj>` for the filesystems the job touches,
  and use `$PBS_JOBFS` for scratch-heavy work, copying results out before the job ends.
- **The default jobfs allocation is 100 MB, and `$TMPDIR` points at it.** Anything that
  spills to temporary space therefore has a 100 MB ceiling unless `-l jobfs=<size>` was
  requested — `sort` most of all, but also `join`, `comm`, and any tool that buffers to disk.
  **`rclone rcat` belongs on that list and is easy to miss**, because it reads from a pipe
  and looks like pure streaming: it spools its whole input to `$TMPDIR` before uploading,
  so `tar | zstd | rclone rcat` needs jobfs the size of a compressed unit even though the
  pipeline stages nothing itself. It is invisible on a login node, where `$TMPDIR` has
  room, and SIGTERMs the job under PBS. Request `-l jobfs=<size>` and
  `export TMPDIR="$PBS_JOBFS"`.
  A verification step that piped 618 M values through `sort -u` used 333 MB, was killed by
  PBS, and its `trap ... EXIT` cleanup then deleted the 5.4 GB output the job had already
  finished producing. Two rules follow:
  - request jobfs explicitly whenever the job sorts, joins, or buffers at scale;
  - **publish before you verify.** Do the cheap integrity checks, rename the result into
    place, drop the cleanup trap, and only then compute expensive statistics — non-fatally.
    A verification step must not cost more than the work it verifies, nor be able to take
    the result down with it.
- **`qsub -v` splits its variable list on commas**, so a value containing a comma cannot be
  passed that way at all: the submission is rejected outright. The empty jobid that comes
  back then makes any dependent `-W depend=afterok:$JOBID` illegal, so the failure surfaces
  as a confusing dependency error one step later. Derive list-valued parameters inside the
  job script instead of passing them in.
- **PBS writes `<jobname>.o<jobid>` beside the submitted script whenever `-o` is omitted**,
  so scheduler logs accumulate in the script tree and end up in `git status`. Give every job
  an explicit `-o`, and ignore `*.o[0-9]*` / `*.e[0-9]*` in the repository.
- **The full ColabFold MSA database is already staged on Gadi under `if89` — never download
  it.** 1.9 TB at `/g/data/if89/apps/colabfold_batch/1.5.2/database`, holding
  `uniref30_2302_db`, `colabfold_envdb_202108_db` and `pdb100_230517`, each with a
  `*_READY` marker. Reach it through the module rather than hardcoding the path, since the
  directory is version-pinned (`1.4.0` and `1.5.2` are both installed):

  ```bash
  module use /g/data/if89/apps/modulefiles
  module load colabfold_batch/1.5.2      # sets COLABFOLDDIR and COLABFOLD_BATCH_BASE
  DB="${COLABFOLDDIR}/database"          # or ${COLABFOLD_BATCH_BASE}/database - same value
  ```

  The module sets **both** `COLABFOLDDIR` and `COLABFOLD_BATCH_BASE` to
  `/g/data/if89/apps/colabfold_batch/<version>`, so either works (verified by loading the
  module and reading the environment). Beware of testing this with a pipeline: `module load
  ... | head` runs the load in a subshell, so the variables never reach the parent shell and
  look unset. Jobs need `-l storage=gdata/if89` alongside their own projects, and
  `colabfold_search --db-load-mode 1` (mmap) — do not try to load 1.9 TB into RAM.
- Two lookalikes under `if89` are **not** the ColabFold database: `/g/data/if89/colabfold_db`
  holds only a `test.sh`, and `/g/data/if89/proteinfold_dbs/proteinfold_minidbs/*` are
  nf-core CI miniatures (23 GB of subsampled 1000-sequence FASTAs).
- **MSA database composition changes the answer, not just the runtime.** Substituting a
  UniRef50-only local MMseqs2 search for real ColabFold MSAs destroyed a known-correct
  interface (DockQ 0.52 → 0.02) while the model's own confidence score barely moved. Match
  the ColabFold composition (UniRef30 + environmental), not whichever protein database is
  conveniently to hand, and never treat pLDDT/ipTM as evidence that an MSA was adequate.

## Dependencies

- Prefer existing dependencies and standard-library functionality.
- Add or upgrade dependencies only when justified by the task.
- Before changing dependencies, inspect the repository's package-management and lockfile
  conventions.
- Use the project's established package manager.
- Update and preserve the appropriate lockfile when dependency changes require it.
- Avoid major-version upgrades or broad dependency refreshes unless requested.
- Avoid replacing one dependency ecosystem with another without explicit justification.
- Explain newly added runtime dependencies in the final summary.

## Editing files

- Make the smallest safe change that solves the issue.
- Preserve existing style, architecture, naming, and conventions.
- Prefer patch-style edits (small reviewable diffs) over full-file rewrites. Reserve
  full-file writes for genuinely new files or complete intentional replacement.
- Read a file before editing it.
- Modify only files necessary for the requested outcome.
- Do not perform opportunistic refactors, repository-wide formatting, dependency refreshes,
  or unrelated cleanup.
- Do not manually edit vendored, generated, minified, lock, migration, snapshot, or derived
  files unless the repository workflow requires it.
- Regenerate derived files using the authoritative project command where possible.
- Preserve file encoding, line-ending conventions, and executable permissions unless the
  task requires changing them.
- Do not add explanatory comments about the change itself; write comments that match the
  surrounding code's density and idiom.
- Do not create documentation files (`README`, summaries, reports) unless requested.

## Tool use

- Prefer the agent's dedicated file, search, and edit tools over shell equivalents where
  they exist; the overlay names them.
- Batch independent tool calls so they run in parallel where the agent supports it.
- Use absolute paths; avoid `cd` in shell commands.
- Use subagents only when the user asks for them or when a broad multi-file search would
  otherwise flood the conversation with output that is not needed in full.
- Use a session scratchpad directory for temporary files when the agent provides one;
  otherwise use a task-specific directory under `/scratch/<proj>/$USER/tmp`. Do not use `/tmp`
  or the user's project tree.
- **Never kill processes by pattern — kill by PID.** `pkill -f <pattern>` and
  `kill $(pgrep -f <pattern>)` match the shell that is running them, because the pattern
  appears in that command's own `/proc/*/cmdline`. The result is that the agent kills its own
  Bash tool call: the command dies partway (exit 144), later steps in the same invocation
  never run, and the intended target may still be alive. This has happened more than once.

  Resolve the PID first, exclude the matching process, then kill that PID:

  ```bash
  pid=$(ps -u "$USER" -o pid,args --no-headers | awk '/my_script\.py/ && !/awk/ {print $1}' | head -1)
  [ -n "$pid" ] && kill "$pid"
  ```

  The same trap applies to *checking* whether something runs: `pgrep -f foo >/dev/null &&
  echo running` reports "running" because of the grep itself. Use the `ps ... | awk '!/awk/'`
  form, or check for a real artifact (a PID file, an output file, `qstat`) instead.

## Git workflow

- Inspect `git status`, the current branch, and recent history before editing.
- Use the current non-default task branch when suitable. Create or switch branches when
  requested, required by repository guidance, or necessary to avoid committing substantial
  work directly to the default branch. Do not create or switch branches for read-only or
  trivial tasks.
- Never switch branches with a dirty working tree unless doing so is demonstrably safe.
- Commit or push only when the user asks.
- When committing, create focused commits with descriptive messages that follow the
  repository's conventions.
- Do not amend, squash, rebase, or rewrite existing commits unless explicitly requested.
- Do not stage or commit unrelated user changes.
- Do not fetch, switch branches, create branches, or otherwise mutate Git metadata for a
  read-only review unless current remote state is necessary.

## Version updates for pull requests

- Follow the repository's documented release and versioning policy.
- Increment a version when the user requests it, repository guidance requires it, or
  existing project practice clearly couples behavior-changing pull requests to version
  changes.
- Do not add a version bump when versions are release-managed, tag-derived, or automated
  unless the established workflow requires a source-file change.
- Determine the authoritative version source and affected package or workspace member before
  editing.
- Follow the project's existing scheme; do not assume semantic versioning when the
  repository uses another convention.
- Under semantic versioning, use patch for backward-compatible fixes, minor for
  backward-compatible functionality, and major for intentional breaking changes. Treat
  pre-1.0 conventions according to repository policy.
- Update lockfiles, generated metadata, changelogs, or documentation only when required by
  the established release workflow.
- Include any version change in the pull-request summary.
- If the authoritative version source or appropriate increment cannot be determined, do not
  guess; ask the user when the choice blocks the task or report that no version was changed.
- In a workspace or monorepo, change only the version of the affected publishable unit
  unless the repository's coordinated-release policy requires otherwise.

## Remote operations

- Non-destructive local repository operations may be performed when relevant to the
  requested task. Discarding changes, destructive cleanup, deleting branches, or rewriting
  history requires explicit authorization.
- Never force-push, merge, delete remote branches, publish releases, or modify production
  resources unless explicitly requested.
- Prefer non-destructive API operations.
- Use dry-run or preview modes when supported and materially useful.
- Report the exact remote write actions performed.
- Sending content to an external service publishes it. Confirm before publishing anything
  outward-facing, including artifacts, issues, comments, and gists.

## Standing approvals for routine commands

The lists below describe which commands the user considers routine, so that the agent runs
or proposes them without hesitation and does not propose anything outside them. They state
policy; how each agent's own approval mechanism treats them is described in its overlay.
These conventions do not override sandbox, filesystem, network, host, scheduler, or platform
permission requirements.

### Repository inspection and routine git

```text
git add <explicit-in-scope-paths>
git branch --show-current
git commit -m <descriptive-message>
git diff
git diff --cached --check
git diff --cached --stat
git diff --check
git fetch origin
git fetch origin <relevant-branch>
git grep
git log
git ls-files
git pull --ff-only
git push
git push -u origin <current-task-branch>
git remote -v
git show
git status
git switch -c <task-branch>
git switch main
```

Deleting a local task branch is routine only after the user states that its pull request has
been merged and identifies or clearly implies that branch. This does not authorize remote
branch deletion:

```text
git branch -d <merged-local-task-branch>
```

`git push` and `git push -u origin <current-task-branch>` are routine when the current user
request clearly implies publication, pull-request preparation, CI validation, or updating an
existing remote task branch. They are not routine for pushing unrelated local commits,
pushing directly to a protected/default branch, changing remotes, deleting remote branches,
or force-pushing.

### GitHub CLI

`gh` is not on the default `PATH`. It is installed in a Conda/Mamba environment named `gh`,
with the executable at:

```text
/g/data/ob80/re3494/conda/gh/bin/gh
```

Invoke it by absolute path, or activate the environment first
(`conda activate gh` / `mamba activate gh`). If `gh: command not found` appears, use the
absolute path rather than concluding that `gh` is unavailable.

Long-running monitoring commands must use bounded waits or provide periodic progress
updates, and should stop when the requested terminal condition is reached. Prefer running
them in the background rather than blocking the session.

When the user asks to create, update, monitor, or address feedback on a pull request, the
following authenticated GitHub CLI operations are routine:

```text
gh repo view
gh pr list
gh pr diff
gh issue list
gh issue view

gh --version
gh auth status
gh pr create ...
gh pr view <current-pr> ...
gh pr checks <current-pr> ...
gh pr comment <current-pr> --body "@<agent> review"
gh run list --repo <current-repo> ...
gh run view <relevant-run> ...
gh run watch <relevant-run> ...
gh api graphql ...
gh api repos/<current-repo>/actions/workflows
gh api repos/<current-repo>/actions/runs...
```

Treat `gh` failures caused by restricted sandbox networking separately from invalid,
missing, or expired GitHub credentials. When network access is unavailable, report that
authentication could not be verified from the sandbox; do not conclude that the user's
credentials are invalid. Retry outside the restricted sandbox or request network permission
rather than asking the user to reauthenticate immediately.

The GraphQL approval includes reading pull-request review threads and resolving a thread
only after its actionable feedback has actually been addressed and the user has asked for
outstanding review comments to be resolved. Do not resolve informational, disputed,
ambiguous, or unaddressed threads. Read-only Actions API calls must remain scoped to the
repository under discussion. Posting `@<agent> review` (the overlay names the agent) is routine only for requesting a
re-review of a pull request the user asked to monitor.

### Node, npm, and npx

When the repository already uses Node tooling, the following are routine for
repository-scoped work:

```text
node --version
npm --version
npx --version
npm test
npm run <repository-defined-script>
npm exec -- <repository-defined-tool> ...
npx --yes <repository-defined-tool> ...
```

`npx` and `npm exec` are routine only when the tool is already declared in the repository
configuration, lockfile, or documented project workflow, or when the user explicitly asks
for that tool. They may use network access only when required to install or run the
repository-declared tool, and only within the current task scope.

These approvals do not authorize global package installation, major dependency upgrades,
publishing packages, changing credentials, running unreviewed remote install scripts, or
executing arbitrary packages unrelated to the task.

### Read-only inspection

Routine repository-scoped inspection is fine, via the agent's dedicated read and search
tools or, where a shell is genuinely needed:

```text
rg ...
rg --files ...
sed -n ...
find <repository-or-established-environment-path> ...
ls ...
wc ...
column ...
gzip -cd ...
sha256sum ...
date -Is
```

Reads of the installed `~/.codex/AGENTS.md` or `~/.claude/CLAUDE.md`, project `AGENTS.md` or
`CLAUDE.md` files, and installed skill instructions
are routine when needed to follow current agent policy. These approvals do not permit broad
credential-directory reads, environment dumps, or output that exposes tokens or secrets.

### Local validation and inspection

- repository-defined formatting, linting, type-checking, testing, and build commands;
- commands that inspect files, dependencies, tool versions, processes, storage, scheduler
  state, or accelerator state;
- read-only package-manager commands such as listing, auditing, or showing dependency
  metadata.

These do not extend to commands that modify remote state, rewrite Git history, delete data,
install system-wide software, alter credentials, or modify production resources.

### File editing and publication boundaries

- Repository edits explicitly requested by the user are made through patch-style edits.
- Stage only named files that belong to the requested change.
- Temporary files belong in the scratch location described under "Tool use"; pull-request bodies and test
  outputs may be written there.
- Local planning or continuity files must remain untracked unless the user explicitly asks
  for them to be committed.
- Opening and updating a pull request is fine when explicitly requested.

## Restricted actions

Ask first unless the operation is clearly and explicitly authorized within the current
task's scope.

- force-pushing or rewriting published history;
- deleting remote branches, releases, repositories, cloud resources, or production data;
- merging pull requests;
- publishing packages or releases;
- applying live settings, secrets, access policies, DNS, deployment variables, database
  configuration, or repository settings. Editing a checked-in configuration file within an
  authorized code change is distinct from applying that configuration to a live environment;
- performing major dependency upgrades;
- changing access controls, credentials, secrets, billing, or repository settings;
- executing database migrations against shared or production systems;
- broad destructive filesystem operations;
- submitting large or long-running scheduler jobs that consume substantial allocation.

Never use `git reset --hard`, `git clean -fd`, force-push, rebase of published history, or
broad recursive deletion under any standing approval.

## Validation

- Discover the repository's validation workflow from its documentation, configuration files,
  CI definitions, Makefile, task runner, and local `AGENTS.md` or `CLAUDE.md`.
- Run the smallest relevant validation set first.
- For source changes, run applicable formatting, linting, type-checking, tests, and builds
  when feasible.
- Prefer targeted tests during development, followed by broader checks when warranted.
- Do not claim a check passed unless it was run successfully; quote the failing output when
  it fails.
- Report skipped checks and why they were skipped.
- Address errors and warnings introduced by the change.
- Distinguish pre-existing failures from failures caused by the change.
- Avoid running unusually expensive integration, benchmark, GPU, cluster, full-dataset, or
  external-service workflows unless requested or clearly necessary.
- Do not consume substantial cloud, HPC, accelerator, or paid resources without explicit
  justification.

## Reading documents and data

- Inspect enough of the source to understand its structure, scope, and relevance.
- Read the complete relevant section when the task depends on exact wording or complete
  coverage.
- For large files, use targeted search, indexing, sampling, streaming, or programmatic
  inspection rather than loading the entire file unnecessarily.
- Before finalising, verify important claims against the source.
- Distinguish direct quotations, close paraphrases, interpretations, and assumptions.
- Never invent content not present in the source.
- Preserve wording and style when requested.
- When transforming structured data, retain schema, identifiers, units, and missing-value
  semantics unless instructed otherwise.

## Scientific and data-processing work

- Preserve input data unless explicitly instructed otherwise.
- Write derived outputs to distinct, clearly named paths.
- Record relevant versions, parameters, database versions, and random seeds in the requested
  output, an existing project provenance mechanism, or the final report. Do not introduce a
  new tracked provenance file unless the task requires it.
- Validate file formats and representative records before processing a full dataset.
- For large datasets, test workflows on a small representative subset first when feasible.
- Avoid silently dropping malformed records; count and report them.
- Preserve sample identifiers and provenance.
- Do not commit large datasets, credentials, intermediate outputs, or generated binaries
  unless repository policy explicitly requires it.
- When parallelising, respect scheduler allocations and derive thread or process counts from
  the execution environment where appropriate.
- On shared systems, avoid uncontrolled parallelism, excessive temporary storage, or
  unnecessary duplicate data.
- Report assumptions affecting biological, statistical, or computational interpretation.

## Secrets and sensitive data

- Never print secrets, tokens, private keys, passwords, credentials, or confidential values
  to terminal output.
- Do not ask users to paste secrets into chat or source files.
- Avoid commands that may expose secrets, including broad environment dumps or
  indiscriminate reads of credential directories.
- Prefer existing authenticated CLIs, credential stores, environment injection, or secret
  managers.
- Redact sensitive strings in displayed output.
- Do not commit secrets or sensitive local configuration.
- Before committing, inspect the diff for accidental credentials, private data, or large
  generated files.
- Treat human, clinical, unpublished, embargoed, and identifiable research data as
  sensitive, and never send it to a third-party service — anything that processes,
  analyses, indexes or trains on what it receives. Remote compute is the case to watch,
  because it often looks local: `pybiolib` (DeepTMHMM) dispatches to biolib.com and
  Boltz's `--use_msa_server` to a remote MMseqs2, both from what reads as a local command.
- **The user's own storage is not a third-party service.** Backing sensitive data up to a
  destination the user controls — their Teams/SharePoint or OneDrive via an existing
  `rclone` remote, their institutional storage — is permitted, including unpublished
  genomes and sequence data. `RobsFiles:` is such a destination and is approved for this.
  Ask once if a backup target's ownership is genuinely unclear; do not refuse a backup to
  the user's own storage on the strength of the rule above, and do not re-ask each session.

## Task continuity

For substantial or multi-turn implementation tasks, use `.agent/CONTINUITY.md` in the
project as a concise handoff record.

- Read it before continuing an existing multi-turn task.
- Create it only when the task is sufficiently complex that state may otherwise be lost.
- Do not create or update it for trivial, read-only, or single-step tasks.
- Treat it as working state rather than user-facing project documentation.
- Do not commit it unless the repository already tracks it or the user requests it.
- Update it only when there is a meaningful change in goal, plan, decision, progress,
  discovery, or outcome.
- Create the parent `.agent/` directory when needed. Do not modify `.gitignore` solely for
  this file unless requested; use local exclusion where appropriate. A project instruction file
  may define another continuity location.
- This is distinct from the persistent memory directory: memory holds durable facts about
  the user and the project across sessions; `.agent/CONTINUITY.md` holds the working state
  of one substantial task.

### Recommended format

Use only the sections that are relevant:

- `[PLANS]`: intended steps and acceptance criteria;
- `[DECISIONS]`: material decisions and their rationale;
- `[PROGRESS]`: implementation progress or changes in direction;
- `[DISCOVERIES]`: important behaviour, performance findings, bugs, or trade-offs supported
  by concise evidence;
- `[OUTCOMES]`: completed work, remaining limitations, and lessons learned.

### Anti-drift and anti-bloat rules

- Record facts, not transcripts or raw logs.
- Include an ISO timestamp and provenance tag such as `[USER]`, `[CODE]`, `[TOOL]`, or
  `[ASSUMPTION]` for material entries.
- Mark unknown facts as `UNCONFIRMED`; never guess.
- When facts change, explicitly supersede the earlier entry.
- Keep the file short and high-signal.
- Compress older detail into milestone bullets when sections become long.
- Do not duplicate information already maintained authoritatively elsewhere in the
  repository.

## Definition of done

A task is complete when:

- the requested outcome and acceptance criteria are satisfied;
- the implementation is limited to the intended scope;
- relevant validation has been run, or skipped checks are identified with reasons;
- errors introduced by the change have been addressed;
- pre-existing failures are clearly distinguished;
- affected documentation is updated where necessary;
- sensitive data and unrelated user changes remain protected;
- `.agent/CONTINUITY.md` is updated when the task materially affects long-running state;
- the final response summarises:
  - what changed;
  - where it changed;
  - what validation was run;
  - any remaining limitations or follow-up work.
