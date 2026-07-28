# Brief 08 — Claude Code

## Goal

Install Claude Code and apply Daniel's settings — permissions allowlist, safeguard
hooks, theme, effort level.

## As-built (source machine, 2026-07-28)

| Property | Value |
|---|---|
| Version | `2.1.220` |
| Install method | **npm, under the mise-managed node** — `@anthropic-ai/claude-code@2.1.220` |
| Resolved binary | `%LOCALAPPDATA%\mise\installs\node\24.15.0\claude.ps1` |
| Settings | `%USERPROFILE%\.claude\settings.json` (134 lines) |

**The install is coupled to mise's node 24.15.0.** When mise bumps the node LTS, the
old install directory goes away and `claude` stops resolving. Either reinstall after a
node bump (`npm install -g @anthropic-ai/claude-code`) or switch to the native
installer (`irm https://claude.ai/install.ps1 | iex`), which decouples it from node
entirely. The native installer is the better choice on a fresh machine; it was not used
here.

`reference-configs/claude-settings.json` is the **live settings file verbatim**. It has
diverged substantially from the original 53-line Linux copy:

| Change | Detail |
|---|---|
| Model pin **removed** | Originally `"model": "claude-opus-4-7"`. Now unpinned — follows the CLI default rather than being frozen. |
| PowerShell allowlist added | Option (b) from the gotcha below was taken: additive. `Get-ChildItem`, `Get-Content`, `Select-String`, `Test-Path`, `Get-Command`, `Write-Output`, `Measure-Object`, `Format-Table`, `Where-Object`, `Sort-Object`. |
| `WebSearch`, `WebFetch` allowed | Needed by the Analyst Harness research agents (brief 11). |
| Windows privilege-escalation deny added | `"Bash(Start-Process*-Verb*RunAs*)"` alongside `Bash(sudo:*)`. |
| Hooks layer added | 4 × `PreToolUse`, 1 × `PostToolUse`, 2 × `Stop`. See brief 11. |
| `"effortLevel": "high"` | |
| `"tui": "fullscreen"` | |
| `"agentPushNotifEnabled": true` | |

**The hooks require `jq`** (`winget install --id jqlang.jq`, brief 05) and two shell
scripts at `~/.claude/hooks/` that are **not** in this repo — see brief 11 for why and
what they do. If `jq` is missing the hooks fail silently and the safeguards are simply
not there.

## Source of truth

Linux config: `claude/.claude/settings.json` in https://github.com/dangoodface/dotfiles.
The Windows copy is now the more evolved of the two; treat
`reference-configs/claude-settings.json` here as authoritative for Windows.

## Constraints

- Install destination for settings: `%USERPROFILE%\.claude\settings.json` (Claude Code reads `$HOME/.claude/settings.json` on all platforms; on Windows `$HOME` resolves to `%USERPROFILE%`).
- Don't commit credentials. The auth token lives in `%USERPROFILE%\.claude\credentials.json` and is excluded from any dotfiles tracking (matches the Linux exclusion rule).
- Idempotent.

## Verification

```pwsh
claude --version                              # latest stable
Test-Path "$env:USERPROFILE\.claude\settings.json"
# Open `claude` interactively, run a benign command (e.g., `ls`), confirm
# permission prompt either auto-approves (allowlist hit) or asks once.
```

## Implementation hints

- Install path: native installer (recommended) — `irm https://claude.ai/install.ps1 | iex` or via the official Windows MSI when published. npm fallback if needed: `npm install -g @anthropic-ai/claude-code`. Native install avoids needing Node + nvm/mise on the path. Confirm the current canonical installer at https://docs.claude.com/en/docs/claude-code/setup before scripting.
- Copy `reference-configs/claude-settings.json` to `$env:USERPROFILE\.claude\settings.json`. If a settings file already exists, diff before overwriting; surface to Daniel if there are local edits.
- After install, run `claude` once interactively to trigger first-run auth (browser-based OAuth). The implementing Claude should NOT try to automate this — surface the step to Daniel.
- Re-add MCP servers if Daniel uses them on Linux (the Linux README lists `github` and `context7`):
  ```pwsh
  gh auth refresh
  claude mcp add --transport http github https://api.githubcopilot.com/mcp/ `
    --header "Authorization: Bearer $(gh auth token)"
  claude mcp add --transport http context7 https://mcp.context7.com/mcp
  ```

## Gotchas

- **Bash allowlist on Windows.** The settings.json contains entries like `"Bash(ls:*)"`. Claude Code on Windows runs `Bash(...)` rules against whatever shell it's invoking — by default this is `cmd` or `pwsh`, not Linux bash. Some allowlist patterns may not match the equivalent PowerShell command. The implementing Claude should review the allowlist with Daniel and decide whether to:
  - (a) keep the current allowlist verbatim (will result in more permission prompts on Windows),
  - (b) extend with PowerShell equivalents (`Bash(Get-ChildItem:*)`, `Bash(Get-Content:*)`),
  - (c) replace with PowerShell-native rules.
  Recommended: (b) — additive, preserves Linux behavior if Daniel ever runs on a mixed environment.
- **Sudo deny rule.** `"Bash(sudo:*)"` in the deny list is a Linux concept. Windows equivalent privilege escalation is `Start-Process -Verb RunAs ...`. Add an analogous deny: `"Bash(Start-Process*-Verb*RunAs*)"`. Cosmetic but consistent with intent.
- **`enabledPlugins` paths.** `frontend-design@claude-plugins-official` should resolve cross-platform without changes — plugins are managed by Claude Code itself, not OS-coupled.
- **Theme.** `"theme": "dark"` is cross-platform.
- **Model pin.** `"model": "claude-opus-4-7"` works the same on Windows.
