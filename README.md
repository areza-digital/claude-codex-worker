# claude-codex-worker

Let Claude Code hand light work to OpenAI's Codex CLI: image generation, second-opinion code reviews and small questions about a repo. The work runs on your ChatGPT plan instead of your Claude quota, and Claude checks that Codex is signed in with ChatGPT (an API-key login would bill the API) and how much usage you have left before every job.

Made for people who pay for Claude for the real work and have a small ChatGPT plan (Plus, Go) they barely use.

## What's inside

| Path | What it does |
| --- | --- |
| `bin/codex-usage` | Shows the 5-hour and weekly Codex usage left, from Codex's own session logs. It reads no credentials, makes no network call and runs no model. `--min-left 20` exits 3 when either window is under 20 %, so a script or Claude can skip Codex. `--json` for scripts. Unknown options exit 2. |
| `skills/codex-worker/` | A Claude Code skill: when to use Codex, the usage check, the sandbox rules, how to brief it, and how to check its output before trusting it. |
| `agents/codex-worker.md` | A small Claude Code agent (Haiku) that runs one Codex job and reports back, so a Codex run shows as an agent in Claude Code's status bar and its output stays out of the main conversation. |
| `bin/codex-sync` | Shares Claude Code's setup with Codex from one source: links the skills in `~/.claude/skills` into Codex's skill folder, writes Codex's `AGENTS.md` from your `CLAUDE.md`, and gives Codex your `Bash` guard hooks. Replaces only files it wrote itself (plus an old `AGENTS.md` link into your Claude folder). `--dry-run` shows the changes first. |
| `bin/codex` | Only needed if Codex is installed just as an editor extension (VS Code, Cursor, Windsurf, Antigravity): finds the CLI inside the newest ChatGPT/Codex extension and runs it, with the same login. If a real `codex` is on your PATH, it uses that. |

## Install

Needs Python 3 (3.11 or newer for the config check in `codex-sync`), Claude Code, and Codex signed in with ChatGPT (run `codex` once, or sign in through the editor extension).

```bash
git clone https://github.com/areza-digital/claude-codex-worker.git
cd claude-codex-worker
./install.sh
```

It runs the self-tests from the checkout, then links the commands into `~/.local/bin`, the skill into `codex-worker` in your Claude skills folder (`$CLAUDE_CONFIG_DIR/skills`, default `~/.claude/skills`) and the agent into the `agents` folder next to it. If `~/.local/bin` is not on your PATH, add `export PATH="$HOME/.local/bin:$PATH"` to your shell profile (`~/.zshrc` on macOS). It never overwrites a file that isn't one of its own links, and lists what it skipped at the end. `./install.sh --help` shows the usage; it takes no other options.

## Use

Ask Claude in plain words: "ask Codex to review this diff", "generate an image of …", "get a second opinion from Codex". The skill does the rest.

```bash
$ codex-usage
Codex (plus), as of Mon 01 Jan 12:00
  5h: 58% left, resets Mon 01 Jan 15:00
  7d: 93% left, resets Mon 08 Jan 10:00
```

## Keep Codex in step with Claude

```bash
codex-sync --dry-run   # see what would change
codex-sync             # apply
```

Your Claude files stay the only copy you edit. `codex-sync --help` shows the options; an unknown option exits 2 and changes nothing. An existing `AGENTS.md` in Codex's folder that is a link into your Claude folder is replaced by the generated file (the old link target is printed). To re-run it at the start of every Claude Code session, add this entry to the `SessionStart` list under `hooks` in `~/.claude/settings.json` (create the list if it isn't there; don't paste a second `hooks` key):

```json
{ "hooks": [ { "type": "command", "command": "codex-sync --quiet" } ] }
```

Only command hooks in PreToolUse and PostToolUse groups whose matcher is exactly `Bash` are shared, because Codex sends Bash the same `tool_input.command` payload as Claude; groups for Edit, Write or other tools are skipped, and each skipped group is listed when you run `codex-sync` (not with `--quiet`). Prompt, Stop and SessionStart hooks are not shared either, because they usually depend on Claude's own files. Codex runs a new or changed hook only after you trust it once: open `codex`, type `/hooks`, and approve the list.

Not linked as skills: names starting with `_` or `.`, `codex` and `codex-worker` (they would make Codex call Codex), names Codex already has (in `~/.agents/skills` or `$CODEX_HOME/skills`), and folders without a `SKILL.md`. If you delete `CLAUDE.md` or your shareable hooks, `codex-sync` removes the `AGENTS.md` or `hooks.json` it wrote. It also says so when `project_doc_fallback_filenames` in Codex's `config.toml` does not list `CLAUDE.md` (checked on Python 3.11+) and when a non-empty `AGENTS.override.md` hides the generated rules.

## Good to know

- The usage figures are as of the last Codex turn on this machine, which is when they change. Usage from another device appears after your next local turn. A window whose reset has passed shows as "reset since the last reading (assumed unused)" and counts as full for `--min-left`, though another device may have used it since; a window without a numeric `used_percent` is ignored.
- Codex runs with its sandbox on: `read-only` for questions and reviews, `workspace-write` (the job's folder plus temp folders such as `/tmp`) for images and small edits. The answer file (`-o`) is written by the CLI itself, so the skill gives it a fresh path. The skill never turns the sandbox off.
- The CLI inside an editor extension runs jobs (`codex exec`) but not the interactive screen: `codex` alone stops with "this CLI has no complete local package". `codex --no-daemon` opens it; to trust hooks with `/hooks` comfortably, install the full CLI (`brew install --cask codex`). It uses the same login.
- Codex's CLI has no video generation.
- The log format was read from Codex CLI 0.171 (November 2026). If a later version changes it, `codex-usage` reports "no usage reading" instead of guessing.
- Several Claude accounts? [claude-swap](https://github.com/realiti4/claude-swap) switches between them and shows their usage in the macOS menu bar.

## License

MIT
