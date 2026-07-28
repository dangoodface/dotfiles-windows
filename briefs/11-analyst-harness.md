# Brief 11 — Claude Code customisation layer (Analyst Harness)

> **Scope note — read first.** This brief documents the *shape* of the `~/.claude`
> customisation layer, not its contents. The skills, agents, output style and
> `CLAUDE.md` on the source machine are written for a specific employer's workflow
> and reference internal folder conventions, client-project names and document
> templates. **They are deliberately not committed to this public repo.** This brief
> tells a future session what exists, where it lives, and what has to be
> re-created or copied out-of-band.

## What exists on the source machine

`%USERPROFILE%\.claude\` beyond the settings file covered in brief 08:

| Path | Committed here? | What it is |
|---|---|---|
| `settings.json` | **yes** — `reference-configs/claude-settings.json` | Permissions, hooks wiring, theme, effort level |
| `settings.local.json` | no | Machine-local overrides |
| `CLAUDE.md` | **no** | Global instructions: voice-assistant persona, file locations, Office-file rules, communication standards. Employer-specific. |
| `HARNESS.md` | **no** | Documents the research/retrieval harness end to end |
| `hooks/audit_log.sh` | **no** | Appends every tool call to `~/Automation/logs/audit.jsonl` |
| `hooks/write_guard.sh` | **no** | Blocks `Write`/`Edit` against originals under the employer's work folders — forces a staged copy or a new file |
| `commands/` (5) | no | `/vdr`, `/research`, `/stage-workspace`, `/summarize-docs`, `/backup-folder` |
| `agents/` (5) | no | `vdr-retriever`, `web-researcher`, `citation-qc`, `research-assistant`, `doc-creator` |
| `skills/` (~25) | no | Office-document skills (docx/pptx/xlsx/pdf), Cloudflare skills, `vdr-search`, plus employer/client-specific deliverable skills |
| `output-styles/executive-analyst.md` | no | Default output style |
| `zscaler-ca.pem`, `zscaler.cer` | **never** | Corporate TLS interception certs. Machine-local, do not copy. |

## The hooks wiring (this part *is* reproducible)

`settings.json` — committed — declares seven hooks. Four are inline shell and work
anywhere; two call the uncommitted scripts.

| Event | Matcher | Action | Portable? |
|---|---|---|---|
| PreToolUse | *(all)* | `bash ~/.claude/hooks/audit_log.sh` | needs the script |
| PreToolUse | `Write\|Edit` | `bash ~/.claude/hooks/write_guard.sh` | needs the script |
| PreToolUse | `Bash` | inline: block `rm -rf ~/`, `del /s`, `rmdir /s`, `format <drive>`, `Remove-Item -Recurse -Force`, `rd /s` → `{"decision":"block"}`, exit 2 | **yes** |
| PreToolUse | `Write\|Edit` | inline: timestamped copy of the target into `~/Automation/backups/` before modification | **yes** |
| PostToolUse | `Write\|Edit` | inline: append tool + path to `~/Automation/logs/file-operations.log` | **yes** |
| Stop | *(all)* | inline: append to `~/Automation/logs/sessions.log` | **yes** |
| Stop | *(all)* | inline: Windows balloon notification via `System.Windows.Forms.NotifyIcon` | **yes** |

### Hard dependencies

1. **`jq`** — every inline hook parses the hook payload with `jq`. Installed via
   `winget install --id jqlang.jq` (brief 05). **If `jq` is missing, all of these fail
   silently** — no error surfaces in Claude Code, the safeguards are just absent. This
   has bitten before; verify explicitly.
2. **`bash`** — the hooks are `bash`, not PowerShell. Supplied by Git for Windows
   (brief 07), which puts `bash.exe` on PATH. No WSL involved; this does not violate
   the no-WSL rule.
3. **Directory tree** — hooks write to paths they do not create. Pre-create:
   ```pwsh
   New-Item -ItemType Directory -Force "$HOME\Automation\logs",
                                       "$HOME\Automation\logs\sessions",
                                       "$HOME\Automation\backups",
                                       "$HOME\Automation\templates"
   ```
4. **Restart Claude Code after editing `settings.json`.** Hook changes are read at
   startup; edits to a running session appear to do nothing.

## Reproducing on a new machine

1. Copy `reference-configs/claude-settings.json` → `%USERPROFILE%\.claude\settings.json`.
2. Install `jq`, confirm `bash` resolves, create the `~/Automation` tree above.
3. Either **write the two hook scripts fresh** (they are short — an audit-log appender
   and a path guard) or **copy them out-of-band** from the source machine. Do not
   expect them from this repo.
4. Copy `CLAUDE.md`, `skills/`, `agents/`, `commands/`, `output-styles/` out-of-band
   if the employer-specific workflow is wanted. A personal machine probably wants a
   trimmed subset.
5. Do **not** copy the Zscaler certs, `settings.local.json`, or anything under
   `projects/`, `sessions/`, `history.jsonl`, `file-history/` — per-machine state and
   transcripts.
6. Re-add MCP servers from scratch; paths differ per machine and tokens must not be
   committed:
   ```pwsh
   gh auth refresh
   claude mcp add --transport http github https://api.githubcopilot.com/mcp/ `
     --header "Authorization: Bearer $(gh auth token)"
   claude mcp add --transport http context7 https://mcp.context7.com/mcp
   ```
   Then `claude mcp list` to confirm they connect.

## Gotchas

- **`write_guard.sh` will block edits you expect to succeed.** It refuses `Write`/`Edit`
  against originals in the protected work folders by design — the workflow is to stage a
  copy first (`/stage-workspace`) or write a new file. If a session reports being unable
  to edit a document, this is usually why, not a permissions bug.
- **The audit log grows unbounded.** `~/Automation/logs/audit.jsonl` gets a line per tool
  call. No rotation is configured. Worth adding on a long-lived machine.
- **`Stop` hook notification spawns `powershell.exe` (5.1), not `pwsh`.** Deliberate —
  it is a one-shot `-NoProfile` call and 5.1 starts faster. Don't "fix" it to `pwsh`.
- **Do not commit the harness content into this public repo.** If a future session is
  tempted to "complete" the repo by adding the skills and `CLAUDE.md`, that publishes
  employer workflow detail. The split is intentional.
