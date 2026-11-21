---
name: codex-worker
description: Hand light work to OpenAI's Codex CLI from Claude Code, on the user's ChatGPT plan instead of Claude's quota - image generation, second-opinion code reviews, small read-only questions about a repo, small contained edits. Checks how much Codex usage is left before every job. Use when the user says "ask Codex", "codex review", "second opinion", "generate an image", "make a picture", or when Claude usage is running low and a light task can move.
---

# Codex as a worker

Codex runs as a separate agent on the user's ChatGPT plan. If the `codex-worker` agent is installed, start the job through it (Agent tool, `subagent_type: codex-worker`) with the brief, folder, mode and what to return: the run then shows as an agent in the status bar and its output stays out of your context. Otherwise run the commands below yourself. Claude stays in charge: it writes the brief, runs Codex, checks what comes back and reports to the user. Codex never talks to the user directly.

## 1. Check the login and the usage first, every time

```bash
codex login status
codex-usage --min-left 20; echo "codex-usage exit code: $?"
```

- `codex login status` must say the login is ChatGPT, and `CODEX_API_KEY` / `OPENAI_API_KEY` must not be set in the environment (`codex exec` would use the key and bill the API). If it says an API key, or that nobody is logged in, stop and tell the user: a run would bill their API account (or fail). Run it with the same `codex` and environment the worker will use.
- `codex-usage` exit 0: go ahead. Exit 3: a window has under 20 % left, so do the task yourself or tell the user, naming the window and when it resets. Exit 1: no reading yet; one small task is fine and creates one. Exit 2: wrong arguments.
- A window shown as "reset since the last reading (assumed unused)" counts as full; usage from another device may have used it since, so treat it as a hint.
- Lower plans (Plus, Go) have small windows. Prefer one well-briefed run over several small ones.
- Run `codex-usage` again after the job and mention what is left when it is under 50 %.

## 2. Pick the mode

| Job | Command |
| --- | --- |
| Question about code, review, second opinion | `codex exec -s read-only -C <repo> -o <answer.md> "<brief>"` |
| Image | `codex exec --skip-git-repo-check -s workspace-write -C <out-dir> -o <answer.md> "Generate an image with your image generation tool: <what>. Save it as <name>.png in the current folder. Reply with the file path only."` |
| Small contained edit | `codex exec -s workspace-write -C <git worktree> -o <answer.md> "<brief>"` |
| Follow-up in the same Codex session | `cd <same folder as the first run> && codex exec resume <session-id> -c 'sandbox_mode="read-only"' -o <new-answer.md> "<follow-up>"`, with the id from the `session id:` line of the first run's output |

- `<answer.md>` is always a new absolute path that does not exist yet (for example under the system temp folder). The CLI writes it itself, outside the sandbox, and overwrites whatever is there.
- `-s read-only`: Codex can read files and change none; the only write is that answer file. `-s workspace-write`: Codex can also write inside `-C <dir>` **and the temp folders** (`/tmp`, `$TMPDIR`), nowhere else.
- `codex exec resume` has no `-s` and no `-C`, and needs `--skip-git-repo-check` again when the folder is not a git repo (image jobs): set the mode with `-c 'sandbox_mode="..."'` (`"workspace-write"` for edits and images), and run it from the same folder as the first job. `--last` would pick the newest session recorded for the current folder (`--all`: any folder), maybe one the user runs in an editor, so pass the id.
- **Never** pass `--dangerously-bypass-approvals-and-sandbox` or `--sandbox danger-full-access`: a trusted-projects entry in `~/.codex/config.toml` may trust far more than the task needs, and the sandbox flag is the only fence.
- Edits go in a separate git worktree or branch, never straight into the user's working tree.
- Long jobs: run in the background and wait for completion; do not poll in a loop.
- Model and effort come from `~/.codex/config.toml`; pass `-m <model>` only when the user asks for one.
- Codex has no video generation in the CLI. Say so instead of trying.

## 3. Write a brief Codex can act on alone

Codex sees only the brief and the files. Include:

1. The goal in one or two sentences, and the folder.
2. What is in scope and what must not be touched.
3. What to return (a file path, a findings list with file:line, a yes/no) and where to write it.
4. "Do not push, deploy, send messages or change anything outside this folder."
5. For reviews: what changed (a diff range or files) and what to look for. Ask for findings with evidence, no style nits.

## 4. Check the result before using it

- Read the answer file. For a review, verify each finding against the code before passing it on; drop what does not hold and say so.
- For an image, open the file and look at it before showing it to the user: subject, no unwanted text, no artefacts.
- For an edit, read the diff and run the project's tests.
- Report to the user what Codex did, what you checked, and the usage left.
