# Brief 10 — Terminal stack (WezTerm + Zellij)

> **Status: DECIDED and in production.** This brief supersedes the earlier
> "no terminal emulator config" scope note in `README.md` / `TARGET.md`.
> Rationale for the choice is in `TERMINAL_RESEARCH.md` at the repo root.

## Goal

Reproduce Daniel's working terminal environment on another Windows machine
**plug-and-play**: WezTerm as the emulator, Zellij as the multiplexer, both
driving PowerShell 7, rendering JetBrainsMono Nerd Font with Catppuccin Mocha.

The decision that TERMINAL_RESEARCH.md left open ("WezTerm only" vs "Zellij +
Windows Terminal") was resolved by taking **both**: WezTerm for the emulator
layer (GPU rendering, font/ligature quality, Lua config) and Zellij for the
multiplexer layer (session persistence, layouts, the discoverable modal status
bar). Windows Terminal is left installed but untouched — it is *not* the daily
driver and its `settings.json` is deliberately stock.

## The install

```pwsh
winget install -e --id wez.wezterm      # emulator
winget install -e --id Zellij.Zellij    # multiplexer
```

Verified installed state on the source machine (2026-07-28):

| Component | Version | Binary location | On PATH via |
|---|---|---|---|
| WezTerm | `20240203-110809-5046fc22` | `C:\Program Files\WezTerm\wezterm.exe` (+ `wezterm-gui.exe`) | Machine PATH (installer-added) |
| Zellij | `0.44.3` | `%LOCALAPPDATA%\Zellij\zellij.exe` | User PATH |

**Pin WezTerm to `20240203-110809-5046fc22`.** That is the version the config in
`reference-configs/wezterm/wezterm.lua` is verified against. It is an old stable
(Feb 2024) but every directive in the config loads without error on it. Newer
nightlies are untested here.

## Config file destinations

| Config | Destination on target machine | Source in this repo |
|---|---|---|
| WezTerm | `%USERPROFILE%\.config\wezterm\wezterm.lua` | `reference-configs/wezterm/wezterm.lua` |
| Zellij | `%APPDATA%\Zellij\config\config.kdl` | `reference-configs/zellij/config.kdl` |

Note the asymmetry — it is not a mistake:

- WezTerm reads `$XDG_CONFIG_HOME/wezterm/wezterm.lua`, then
  `%USERPROFILE%\.config\wezterm\wezterm.lua`, then `%USERPROFILE%\.wezterm.lua`.
  We use `.config\wezterm\` to match the Linux layout.
- Zellij on Windows uses the **`%APPDATA%` (Roaming)** dir, i.e.
  `C:\Users\<user>\AppData\Roaming\Zellij\config\config.kdl` — *not* `.config\`.
  Zellij's own `--help` prints XDG-style paths that do not apply on Windows.
  Confirm with `zellij setup --check`, which prints the path it actually reads.

## PORTING — the four values that are machine-specific

Both reference configs are committed **verbatim from the working machine**, which
means they contain hardcoded absolute paths. Fix these four before declaring the
new machine done. Everything else copies unchanged.

| # | File | Line | Hardcoded value | What to do on the new machine |
|---|---|---|---|---|
| 1 | `zellij/config.kdl` | `default_shell` | `C:/Program Files/WindowsApps/Microsoft.PowerShell_7.6.4.0_x64__8wekyb3d8bbwe/pwsh.exe` | Re-resolve — the version is baked into the path. See "PowerShell 7 resolution" below. Zellij KDL has no scripting, so this **must** be edited by hand. |
| 2 | `zellij/config.kdl` | `default_cwd` | `C:/Users/51372/Projects` | Point at the new machine's project hub. Deliberately not OneDrive. |
| 3 | `wezterm/wezterm.lua` | `find_pwsh()` fallback (last `return`) | same versioned WindowsApps path | Usually needs no edit — the `wezterm.glob` branch above it auto-discovers. Refresh the literal anyway so the last-resort branch isn't stale. |
| 4 | `wezterm/wezterm.lua` | `config.font_size = 11.0` | `11.0` | Per-display preference; adjust for the new machine's DPI/panel. |

## PowerShell 7 resolution — the load-bearing gotcha

**This is the single thing most likely to silently break on a new machine.**

On the source machine PowerShell 7 is installed as an **MSIX / Microsoft Store
package**, not as an MSI:

```
Get-AppxPackage -Name Microsoft.PowerShell
  Name            : Microsoft.PowerShell
  Version         : 7.6.4.0
  InstallLocation : C:\Program Files\WindowsApps\Microsoft.PowerShell_7.6.4.0_x64__8wekyb3d8bbwe

Test-Path 'C:\Program Files\PowerShell\7\pwsh.exe'   # -> False  (no MSI install)
```

The `pwsh.exe` that sits on `PATH` at
`%LOCALAPPDATA%\Microsoft\WindowsApps\pwsh.exe` is a **0-byte app-execution-alias
reparse point**:

```
size=0  attrs=Archive, ReparsePoint
```

The shell resolves it fine (`Get-Command pwsh` finds both entries), but WezTerm
and Zellij **spawn processes directly via `CreateProcess`** and cannot execute a
reparse stub. The failure is silent and nasty: you land in **Windows PowerShell
5.1** instead, and none of the dotfiles load — because 5.1 reads
`Documents\WindowsPowerShell\` while 7 reads `Documents\PowerShell\`. The prompt
looks vaguely wrong, no starship, no aliases, and nothing errors.

Hence both configs point at the **real versioned binary** under
`C:\Program Files\WindowsApps\`.

### How each config handles it

- **WezTerm** (`find_pwsh()`) degrades gracefully, in order:
  1. `C:/Program Files/PowerShell/7/pwsh.exe` — the MSI path, preferred if present
     (stable across upgrades). Tested with `io.open`.
  2. `wezterm.glob` over
     `C:/Program Files/WindowsApps/Microsoft.PowerShell_*_x64__8wekyb3d8bbwe/pwsh.exe`,
     sorted, newest wins. **This is what makes the config survive PS7 upgrades.**
  3. A hardcoded known-good path as last resort.

  It deliberately never falls back to `powershell.exe` — silently landing in 5.1
  is the bug being defended against.

- **Zellij** cannot script, so `default_shell` is a literal. It will break on the
  next PowerShell 7 upgrade (the version is in the path). Re-resolve with:

  ```pwsh
  (Get-AppxPackage -Name Microsoft.PowerShell).InstallLocation + '\pwsh.exe'
  ```

### The permanent fix (recommended for a fresh machine)

Install PowerShell 7 **machine-wide via MSI** instead of the Store package:

```pwsh
winget install --id Microsoft.PowerShell -e --scope machine --force
```

Then set both configs to the stable, version-free path and the whole class of
problem disappears:

```
C:/Program Files/PowerShell/7/pwsh.exe
```

WezTerm's branch 1 picks this up with no edit. For Zellij, change `default_shell`
to that literal.

## Font dependency

The WezTerm config requests `wezterm.font('JetBrainsMono Nerd Font')`. Note that
the GDI/`InstalledFontCollection` family name of the installed font is
**`JetBrainsMono NF`**, not `JetBrainsMono Nerd Font` — but WezTerm matches on the
font's full/PostScript name via DirectWrite, so the request resolves correctly.

Verified, not assumed:

```pwsh
wezterm ls-fonts --text "ab"
# -> C:\USERS\...\FONTS\JETBRAINSMONONERDFONT-REGULAR.TTF, DirectWrite
```

Nerd glyphs resolve from the same file (`\uf07c` → `fa-folder_open`,
`\ue7a8` → `dev-rust`), so no `font_rules` fallback entry is needed.

**Do not "fix" the font name to `JetBrainsMono NF`** to match what the Windows
font picker shows. That would break the config on Linux/macOS, where the same
family is exposed under its full name. See `briefs/01-fonts.md` for which font
variant must be installed — the `*NerdFont-*.ttf` files specifically, not
`*NerdFontMono-*` or `*NerdFontPropo-*`.

## Keybindings (WezTerm layer)

Zellij-flavoured, so muscle memory carries over from the Linux ghostty+zellij
setup. Full source of truth is the config; summary:

| Action | Binding |
|---|---|
| Quit / fullscreen | `Alt+q` / `F11` |
| New tab / close tab | `Alt+n` / `Alt+x` |
| Jump to tab N | `Alt+1`..`Alt+9` |
| Split horizontal / vertical | `Alt+d` / `Alt+r` |
| Close pane | `Alt+w` |
| Navigate panes | `Alt+h/j/k/l` |
| Resize mode (modal, repeatable) | `Alt+Shift+R`, then `h/j/k/l` or arrows, `Esc`/`Enter` to exit |
| Workspace picker | `Alt+s` |
| Copy mode / scrollback search | `Alt+[` |
| Windows Terminal muscle-memory fallbacks | `Ctrl+Shift+T/W/C/V` |

Zellij keeps its **default** modal bindings untouched (`Ctrl+p` pane, `Ctrl+t`
tab, `Ctrl+n` resize, `Ctrl+o` session) for the same reason.

### Spanish-keyboard Alt handling (do not remove)

```lua
config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = true
config.use_dead_keys = true
```

Without the first line, `Alt+<letter>` gets composed on a Spanish layout and
never reaches the keybind handler — every `Alt+` binding above silently dies.
Right Alt is left as AltGr so `@`, `€`, `~` and accents still compose.

## Verification

```pwsh
# 1. Binaries
wezterm --version        # 20240203-110809-5046fc22
zellij --version         # 0.44.3

# 2. Configs land where the tools actually read them
Test-Path "$env:USERPROFILE\.config\wezterm\wezterm.lua"
Test-Path "$env:APPDATA\Zellij\config\config.kdl"
zellij setup --check     # confirms the config path + no parse errors

# 3. Config parses and the font resolves to a real file
wezterm ls-fonts --text "ab"        # must print a JETBRAINSMONONERDFONT-*.TTF path

# 4. THE CRITICAL ONE — are we actually in PowerShell 7, not 5.1?
#    Run this INSIDE a fresh WezTerm window, and again inside `zellij`:
$PSVersionTable.PSVersion           # must be 7.x — if it says 5.1, the
                                    # default_shell/default_prog path is wrong
```

Then, by eye, in a fresh WezTerm window:

- [ ] Starship segmented Tokyo Night bar renders, **all glyphs, no `?` boxes**.
- [ ] Ligatures render (`->`, `!=`, `=>` become single glyphs).
- [ ] Catppuccin Mocha background (dark, warm) — not the default WezTerm dark.
- [ ] Window buttons are integrated into the tab bar (`INTEGRATED_BUTTONS`).
- [ ] `Alt+d` splits, `Alt+h/l` moves between panes, `Alt+Shift+R` then `h` resizes.
- [ ] `zellij` launches, status bar visible, pane frames on, `Ctrl+p` enters pane mode.
- [ ] New Zellij tabs open in the `default_cwd`, not in `$HOME`.

## Gotchas

- **`copy_on_select` is set in Zellij but WezTerm's default also copies on
  select.** Selecting text inside a Zellij pane inside WezTerm goes through
  Zellij's handler. Harmless, but if a paste ever contains pane-frame characters,
  it is because the WezTerm layer grabbed the selection instead — hold `Shift` to
  force the terminal-level selection.
- **`check_for_updates = false`** in the WezTerm config on purpose — winget owns
  updates. If WezTerm is pinned as instructed, do not re-enable it.
- **Zellij inside WezTerm doubles the tab bar.** Both draw one. Not a bug; if it
  bothers you on the new machine, either set `config.enable_tab_bar = false` in
  WezTerm when you live in Zellij, or `pane_frames false` in Zellij. The source
  machine keeps both, deliberately — the Zellij status bar is the whole reason
  Zellij is in the stack (per TERMINAL_RESEARCH.md).
- **`C:\Program Files\WindowsApps` is ACL-restricted.** Directory listing is
  denied to normal users for *other* users' packages, but traversal to your own
  installed package works — which is why `wezterm.glob` succeeds. Don't be
  alarmed that `ls` on that directory fails in Explorer or a plain shell.
- **Windows Terminal is stock on the source machine** — `defaultProfile` is still
  Windows PowerShell 5.1, no font override, no Catppuccin. If you open Windows
  Terminal on the new machine and it looks nothing like WezTerm, that is expected
  and correct. Don't chase it.
