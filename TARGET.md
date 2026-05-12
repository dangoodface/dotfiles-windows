# Target setup — what we're building

A native-Windows replica of Daniel Buenrostro's Fedora 43 dev environment. Same look, same tools, same workflow muscle memory — without WSL, without Cygwin, without any Linux emulation layer. Pure native Win32 binaries managed via `winget` and `scoop`.

## The aesthetic

| Surface | Look / behavior |
|---|---|
| **Font** | JetBrainsMono Nerd Font v3.4.0 — programming ligatures, full Nerd icon glyphs |
| **Theme** | Catppuccin Mocha (dark, low-contrast, slightly warm) |
| **Prompt** | Starship custom format — Tokyo Night palette, segmented bar with directory + git status + runtime versions (Node/Rust/Go/PHP) + clock |
| **Editor** | Neovim with LazyVim starter — same plugin set, same keymaps |

Daniel will pick whatever terminal emulator he's already comfortable with on Windows (Windows Terminal, WezTerm, or others); this repo doesn't impose one. The terminal just needs to be configured to use **JetBrainsMono Nerd Font** and to launch **PowerShell 7** as the default profile.

## The toolchain

Every tool below has a Windows-native install. None require WSL.

| Category | Tool | Windows install path |
|---|---|---|
| Shell | **PowerShell 7** | winget — `Microsoft.PowerShell` |
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
| Process viewer | **btop** (or `ntop` Windows port) | winget — best-effort |

## The workflow contract

Once bootstrapped, Daniel should be able to:

1. **Open a terminal**, see the same Tokyo Night starship prompt with directory, git status, and runtime versions.
2. **Run the same aliases** he uses on Linux (`ls` → eza, `cat` → bat, `lg` → lazygit, `cd <dir>` → zoxide-aware).
3. **Open neovim**, get the same LazyVim experience — same plugins, same keymaps, same colorscheme.
4. **Run `claude`** and have Claude Code work with the same permissions allowlist (Bash subset adapted for PowerShell where syntax differs).
5. **Switch between projects** and have `mise` auto-switch Node/Python/Rust versions per `mise.toml`.
6. **Use `git` + `gh`** with the same global identity and authentication.

## What's deliberately scoped out

- **The `pass` + `gpg` secret store.** Windows-native equivalent (Bitwarden CLI or Windows Credential Manager) is in `briefs/09-secrets.md` — different tool, same role.
- **The `secret()` zsh function.** Will get a PowerShell port if/when the secret store is decided.
- **Heavy terminal-emulator GUI customization.** Out of scope per Daniel: he works on files, terminal is a means.
- **MCP server reconfiguration on Windows.** Mostly path-different from Linux; the implementing Claude should re-add MCPs from scratch using the credentials at hand on the target machine.

## Design constraints (load-bearing)

1. **No WSL.** Hard rule. Every tool must be Win32-native.
2. **No `sudo`-equivalent privilege escalation in scripts.** Use user-scope installs (winget `--scope user`, scoop default) wherever possible.
3. **Idempotent.** Re-running any brief on an already-bootstrapped machine should be a no-op, not a re-install.
4. **Pin versions where it matters.** Font is pinned (v3.4.0); runtime versions inherit from `mise/.config/mise/config.toml` in the Linux repo (node@lts, python@3.13, rust@stable).
5. **Reversible.** Nothing should overwrite existing user data. PowerShell profile additions go into a sourced fragment, not into `Microsoft.PowerShell_profile.ps1` directly, so the user can opt out cleanly.
6. **Fail loudly, not silently.** A missing tool is an error, not a fallback to a different tool.

## Verification: the "feels like Daniel's Linux box" test

The implementing Claude should not declare done until:

- `starship --version` succeeds.
- The prompt renders with all glyphs visible (no `?` boxes).
- `eza`, `bat`, `fzf`, `rg`, `fd`, `lazygit`, `zoxide`, `mise` all resolve in `$PATH`.
- `nvim` opens, LazyVim sync completes without errors, no missing plugins.
- `claude` launches and recognizes the settings.json permissions allowlist.
- A new PowerShell session starts in <1s and shows the customized prompt without errors.

See `briefs/99-verify.md` for the full checklist.
