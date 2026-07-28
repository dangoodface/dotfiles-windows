# Target setup — what we're building

A native-Windows replica of Daniel Buenrostro's Fedora 43 dev environment. Same look, same tools, same workflow muscle memory — without WSL, without Cygwin, without any Linux emulation layer. Pure native Win32 binaries managed via `winget` and `scoop`.

## The aesthetic

| Surface | Look / behavior |
|---|---|
| **Font** | JetBrainsMono Nerd Font v3.4.0 — programming ligatures, full Nerd icon glyphs. Per-user install; `*NerdFont-*` + `*NerdFontNL-*` variants only |
| **Theme** | Catppuccin Mocha (dark, low-contrast, slightly warm) — set in both WezTerm and Zellij |
| **Prompt** | Starship custom format — Tokyo Night palette, segmented bar with directory + git status + runtime versions (Node/Rust/Go/PHP) + clock |
| **Terminal** | **WezTerm** `20240203-110809-5046fc22`, Lua config, integrated title buttons, zellij-style Alt keybindings |
| **Multiplexer** | **Zellij** `0.44.3`, default modal keybindings, pane frames + status bar on |
| **Editor** | Neovim with LazyVim starter — same plugin set, same keymaps |

**The terminal stack is decided, not left to preference** (this reverses the original
scope note). WezTerm is the emulator, Zellij the multiplexer, both launching
PowerShell 7. Windows Terminal remains installed but stock and unused. See
`briefs/10-terminal.md` and `TERMINAL_RESEARCH.md`.

## The toolchain

Every tool below has a Windows-native install. None require WSL.

| Category | Tool | Windows install path |
|---|---|---|
| Terminal emulator | **WezTerm** | winget — `wez.wezterm` |
| Multiplexer | **Zellij** | winget — `Zellij.Zellij` |
| Shell | **PowerShell 7** | winget — `Microsoft.PowerShell`. **Prefer `--scope machine`** so it lands at `C:\Program Files\PowerShell\7\`; the Store/MSIX package puts a 0-byte alias stub on PATH that terminals cannot spawn — see brief 10 |
| Prompt | **starship** | winget — `Starship.Starship` |
| Runtime version manager | **mise** | winget or scoop |
| Editor | **neovim** | winget — `Neovim.Neovim` |
| Git CLI | **git** + **gh** | winget — `Git.Git`, `GitHub.cli` |
| AI assistant | **Claude Code** | npm — `@anthropic-ai/claude-code` |
| File listing | **eza** | winget |
| Pager / cat | **bat** | winget |
| Fuzzy finder | **fzf** | winget |
| Smart cd | **zoxide** | winget |
| Recursive grep | **ripgrep** | winget |
| Find replacement | **fd** | winget |
| Disk usage | **dust** | winget |
| Git TUI | **lazygit** | winget |
| JSON processor | **jq** | winget — required by the Claude Code hooks, not optional |
| Secret store | **Bitwarden CLI** | winget — `Bitwarden.CLI` (brief 09, Option B, decided) |
| Process viewer | ~~btop / ntop~~ | **skipped** — neither installed; the `top` alias is guarded and simply undefined |

## The workflow contract

Once bootstrapped, Daniel should be able to:

1. **Open a terminal**, see the same Tokyo Night starship prompt with directory, git status, and runtime versions.
2. **Run the same aliases** he uses on Linux (`ls` → eza, `cat` → bat, `lg` → lazygit, `cd <dir>` → zoxide-aware).
3. **Open neovim**, get the same LazyVim experience — same plugins, same keymaps, same colorscheme.
4. **Run `claude`** and have Claude Code work with the same permissions allowlist (Bash subset adapted for PowerShell where syntax differs).
5. **Switch between projects** and have `mise` auto-switch Node/Python/Rust versions per `mise.toml`.
6. **Use `git` + `gh`** with the same global identity and authentication.

## What's deliberately scoped out

- **The `pass` + `gpg` secret store.** Replaced by **Bitwarden CLI** (`briefs/09-secrets.md`, Option B — decided). The `~/.password-store` → Bitwarden migration is still outstanding, and gpg4win is not installed, so git commit signing is unconfigured.
- **The `secret()` zsh function.** ~~Deferred~~ — **ported**, Bitwarden-backed, live in the PowerShell fragment.
- ~~**Heavy terminal-emulator GUI customization.**~~ **Reversed.** The WezTerm + Zellij configs are in scope and committed; see `briefs/10-terminal.md`.
- **MCP server reconfiguration on Windows.** Mostly path-different from Linux; the implementing Claude should re-add MCPs from scratch using the credentials at hand on the target machine.
- **The `~/.claude` customisation content** (skills, agents, commands, `CLAUDE.md`). Employer-specific; see `briefs/11-analyst-harness.md` for shape and dependencies.

## Design constraints (load-bearing)

1. **No WSL.** Hard rule. Every tool must be Win32-native.
2. **No `sudo`-equivalent privilege escalation in scripts.** Use user-scope installs (winget `--scope user`, scoop default) wherever possible.
3. **Idempotent.** Re-running any brief on an already-bootstrapped machine should be a no-op, not a re-install.
4. **Pin versions where it matters.** Font pinned (v3.4.0); WezTerm pinned (`20240203-110809-5046fc22` — the version the Lua config is verified against); runtimes are node@lts + python@3.13. **rust is not pinned on Windows** — it needs ~6 GB of MSVC Build Tools that aren't installed. See brief 04.
5. **Reversible.** Nothing should overwrite existing user data. PowerShell profile additions go into a sourced fragment, not into `Microsoft.PowerShell_profile.ps1` directly, so the user can opt out cleanly.
6. **Fail loudly, not silently.** A missing tool is an error, not a fallback to a different tool.

## Verification: the "feels like Daniel's Linux box" test

The implementing Claude should not declare done until:

- `starship --version` succeeds.
- The prompt renders with all glyphs visible (no `?` boxes).
- `eza`, `bat`, `fzf`, `rg`, `fd`, `lazygit`, `zoxide`, `mise`, `jq`, `bw` all resolve in `$PATH`.
- `nvim` opens, LazyVim sync completes without errors, no missing plugins.
- `claude` launches and recognizes the settings.json permissions allowlist.
- A new PowerShell session starts in <1s and shows the customized prompt without errors.
- **WezTerm launches, `$PSVersionTable.PSVersion` inside it reports 7.x — not 5.1.**
  This is the check that catches the PowerShell-alias-stub trap; everything can look
  right while the shell is silently 5.1 with no dotfiles loaded.
- `zellij` launches inside WezTerm, status bar visible, new tabs open in `default_cwd`.

See `briefs/99-verify.md` for the full checklist.
