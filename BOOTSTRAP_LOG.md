# Bootstrap log

Append-only record of as-built state and failures, per `briefs/99-verify.md`.

---

## 2026-07-28 — Full audit of the source machine vs. this repo

Windows 11 Enterprise 10.0.22631. The repo had not been touched since its initial
commit (2026-05-12); the machine had been in daily use since. This entry records the
drift and folds it into the briefs.

### Verdict

The environment is **working and reproducible**. One live regression was found (fzf)
and **fixed the same day**; four machine-coupled absolute paths must be edited when
porting. The repo's biggest inaccuracy was structural: it claimed no terminal config
existed, when in fact the terminal stack had become the most customised part of the setup.

### Drift found

| Area | Repo said | Machine had | Action |
|---|---|---|---|
| Terminal | "deliberately no terminal emulator config" | WezTerm `20240203-110809-5046fc22` + 157-line `wezterm.lua` | New `briefs/10-terminal.md`; config committed; scope note reversed in README + TARGET |
| Multiplexer | not mentioned at all | Zellij `0.44.3` + `config.kdl` | Same brief; config committed |
| Windows Terminal | "user picks whatever terminal" | installed but **stock** — `defaultProfile` still PS 5.1, no font, no theme | Documented as unused; not committed |
| Secret backend | 3 options, "ask Daniel" | **Bitwarden CLI**, `secret` function live | Brief 09 marked DECIDED (Option B) |
| pwsh fragment | skeleton at `~/Documents/PowerShell/` | live at `~/.config/powershell/`, substantially extended | Skeleton deleted, live fragment committed as `pwsh-dotfiles-fragment.ps1`; brief 02 rewritten |
| mise | node, python, **rust** | node 24.15.0, python 3.13.13 — no rust | Brief 04: rust deliberately dropped (no MSVC Build Tools) |
| starship.toml | no `scan_timeout` | `scan_timeout = 1000` | Synced |
| claude settings | 53 lines, `model` pinned | 134 lines: hooks, PS-cmdlet allowlist, `effortLevel`, no model pin | Synced; brief 08 rewritten; new brief 11 for the harness layer |
| `~/.claude` harness | not mentioned | hooks, 5 agents, 5 commands, ~25 skills, output style, `CLAUDE.md` | New `briefs/11-analyst-harness.md` — **shape documented, content deliberately not committed** (employer-specific, public repo) |
| btop | "best-effort" | neither `btop` nor `ntop` | Recorded as a skipped, accepted gap |
| jq | not listed | installed, and **required** by the Claude hooks | Added to brief 05 as required |
| Font family | verify `"JetBrainsMono Nerd Font"` in the picker | picker shows `JetBrainsMono NF` | Brief 01 rewritten — both are correct, see below |

### Verified, not assumed

Things that looked like bugs and are not:

- **Font name mismatch is fine.** `wezterm.lua` requests `JetBrainsMono Nerd Font`;
  the GDI family name is `JetBrainsMono NF`. WezTerm matches on the TTF's full name via
  DirectWrite. Confirmed with `wezterm ls-fonts --text "ab"` →
  `...\JETBRAINSMONONERDFONT-REGULAR.TTF, DirectWrite`. Nerd glyphs resolve from the
  same file (`\uf07c` → `fa-folder_open`, `\ue7a8` → `dev-rust`), so no `font_rules`
  fallback is needed. **Do not "correct" the font name in the config** — it would break
  Linux/macOS parity.
- **`wezterm.lua` loads clean** on the pinned WezTerm version. `INTEGRATED_BUTTONS`,
  `integrated_title_button_style`, `wezterm.glob`, `key_tables` all supported.
- **PowerShell 7 resolution works** — but only because both terminal configs point at
  the versioned `WindowsApps` path. See below.

### Root cause: the PowerShell 7 workaround

PS7 on this machine is the **MSIX/Store package** (`Microsoft.PowerShell 7.6.4.0`),
with **no MSI** at `C:\Program Files\PowerShell\7\`. The `pwsh.exe` on PATH at
`%LOCALAPPDATA%\Microsoft\WindowsApps\pwsh.exe` is a **0-byte app-execution-alias
reparse point** (`size=0 attrs=Archive, ReparsePoint`). WezTerm and Zellij spawn via
`CreateProcess` and cannot execute it — they fall back to **Windows PowerShell 5.1**
silently, which reads a *different* profile path, so no dotfiles load and nothing errors.

The fix in place: both configs target the real binary under
`C:\Program Files\WindowsApps\Microsoft.PowerShell_7.6.4.0_x64__8wekyb3d8bbwe\`.
WezTerm auto-discovers it with `wezterm.glob` so it survives PS7 upgrades; Zellij's KDL
cannot script, so its `default_shell` is a literal and **will break on the next PS7
upgrade**.

Recommended permanent fix on a fresh machine:
`winget install --id Microsoft.PowerShell -e --scope machine --force`, then point both
configs at `C:/Program Files/PowerShell/7/pwsh.exe`. Full detail in brief 10.

### ~~OPEN~~ RESOLVED same day — fzf was broken

`winget list` reported `junegunn.fzf 0.72.0` installed and its PATH entry was present,
but the package directory contained **only** its 16 KB `.db` manifest — no `fzf.exe`.
`Get-Command fzf` → not found.

Because the PSFzf block in the fragment is guarded on `Get-Command fzf`, it skips
silently: **`Ctrl+R` fuzzy history, `Ctrl+T` file picker and `Alt+C` directory picker are
all dead**, with no startup error.

Repaired:

```pwsh
winget install --id junegunn.fzf --force --accept-package-agreements --accept-source-agreements
```

Verified after the fix: `fzf.exe` present (5,460,480 bytes), `fzf --version` →
`0.74.1 (eae8d9d2)`, and in a fresh PS7 session the three bindings are live —
`Ctrl+r` → *Fzf Reverse History Select*, `Ctrl+t` → *Fzf Provider Select*,
`Alt+c` → *CustomAction*, with `Get-Module PSFzf` confirming the module loaded.

Lesson folded into brief 05: **verify the binary, not `winget list`** — `winget list`
reported this package as healthy the entire time. Brief 05 also now carries an optional
noisy-guard variant of the PSFzf block, for anyone who would rather see a warning at
startup than silently lose three keybindings. Not applied here (deliberate trade-off:
the fragment stays quiet when a tool is legitimately absent).

### Machine-coupled values (the porting surface)

Four hardcoded values in the committed configs. Tabulated in brief 10's PORTING section.

1. `zellij/config.kdl` → `default_shell` — versioned PS7 path
2. `zellij/config.kdl` → `default_cwd` — `C:/Users/51372/Projects`
3. `wezterm/wezterm.lua` → `find_pwsh()` last-resort literal
4. `wezterm/wezterm.lua` → `font_size = 11.0` (DPI preference)

Plus, outside the terminal layer: the profile stub's absolute path to the fragment
(brief 02) and `core.editor`'s absolute VS Code path (brief 07).

### Deferred / accepted

- **`~/.password-store` → Bitwarden migration** not done; gpg4win not installed, so old
  `pass` entries are unreadable here and git commit signing stays unconfigured.
- **btop/ntop** skipped; `top` undefined.
- **rust/go/php** absent; starship omits those prompt segments, as designed.
- **Claude Code is installed under mise's node 24.15.0** — a node LTS bump will break
  `claude` resolution. The native installer would decouple it. Noted in brief 08.
- **Pending updates** across eza, fzf, lazygit, ripgrep, starship, zoxide, mise, neovim,
  git, gh. Nothing forced; versions recorded in brief 05 so drift is measurable next time.
- **`audit.jsonl` has no rotation** and grows per tool call.

## 2026-08-27  Drift resync

Checked every file in `reference-configs/` against the live machine. Four were already identical
(`starship.toml`, `mise-config.toml`, `zellij/config.kdl`, `nvim/**`). Two had drifted and are now
resynced. One difference is deliberate and was left alone.

**`wezterm/wezterm.lua`** now carries the live pwsh resolution. The committed version probed the
stable MSI path at `C:/Program Files/PowerShell/7/pwsh.exe` first. The live version pins the known
Store path for **7.6.5.0**, caches the resolved path in `~/.config/wezterm/.pwsh-path`, and orders
the branches fastest-first so only the last one spawns a process, and only after a PowerShell
upgrade moves the Store path. This is the wezterm half of the same work as commit `9bc6dfd`, which
repointed zellij at 7.6.5.0 but never committed the terminal side.

**`claude-settings.json`** gains the `model` preference and the **pixtuoid** hook wiring.
pixtuoid 0.16.0 (MIT, `IvanWng97/pixtuoid`) was installed globally via npm on 2026-07-29. It is a
terminal pixel-art session visualiser and it registers against seven lifecycle events with matcher
`.*`, being `PreToolUse`, `PostToolUse`, `SessionStart`, `Notification`, `SubagentStart`,
`SubagentStop` and `SessionEnd`. Worth knowing that a `PreToolUse` hook on `.*` receives the full
tool input on stdin, so this binary observes every tool call in a session.

The live command is an absolute path that embeds both the user id and the node version
(`...\mise\installs\node\24.15.0\node_modules\pixtuoid\...\pixtuoid-hook.exe`), which would
break on any node upgrade. Committed here as the bare `pixtuoid-hook` shim instead. Verified
resolvable on PATH from both bash and PowerShell, with `.cmd` and `.ps1` wrappers present in the
npm global bin directory.

### Deliberately not synced

**`permissions.additionalDirectories`** stays out. The live file grants three directories, two of
which name the employer's cloud drive. Per `README.md`, employer-specific `~/.claude` content does
not belong in a public repo. Consequence to accept: anyone rebuilding from this repo will not know
those grants exist and will hit permission prompts until they add their own.

**`pwsh-dotfiles-fragment.ps1`** stays as committed. Its five line difference from the live file is
the existing employer-name scrub and the file carries an inline note saying not to resync it.
