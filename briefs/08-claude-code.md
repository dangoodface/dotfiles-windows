# Brief 08 — Claude Code

## Goal

Install Claude Code (Anthropic's CLI coding assistant) and apply Daniel's settings — permissions allowlist, model pin, theme.

## Source of truth

Linux config: `claude/.claude/settings.json` in https://github.com/dangoodface/dotfiles. A copy is in `reference-configs/claude-settings.json` in this repo. The settings are mostly cross-platform; the only thing that may need adjustment is the Bash command allowlist (some commands have different syntax or names on Windows).

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
