# Brief 99 — Verification checklist

## Goal

End-to-end smoke test confirming the Windows machine matches Daniel's Linux dev environment in observable behavior. Run this *after* all other briefs complete.

## The "feels like Daniel's Linux box" test

Open a fresh PowerShell 7 session — NOT a session that had partial dotfiles loaded during bootstrap. Cleanly close all terminals first, then open one new one. **Open it in WezTerm**, since that is the daily driver (brief 10).

### Check zero — are you even in PowerShell 7?

Do this first. Every other check can appear to fail for this one reason.

```pwsh
$PSVersionTable.PSVersion      # must be 7.x
```

If it reports **5.1**, stop. The terminal's `default_prog` / `default_shell` is pointing
at the 0-byte PowerShell app-execution-alias stub and you are in Windows PowerShell,
which reads a different profile path — so *no* dotfiles are loaded and nearly every
check below will fail for that single reason. Fix per brief 10 before continuing.

Repeat the same check **inside `zellij`**, which resolves its shell independently of
WezTerm.

### Visual checks

- [ ] Prompt shows the segmented Tokyo Night starship bar (purple → blue gradient).
- [ ] All glyphs render (no `?` boxes, no missing icons in directory or git status segments).
- [ ] Directory icons render for `Documents/`, `Downloads/`, `Music/`, `Pictures/`.
- [ ] `cd` into a git repo: branch name + status flags appear in the prompt.
- [ ] `cd` into a Node project (one with package.json): Node version appears in the prompt.

### Tool resolution

```pwsh
foreach ($t in 'pwsh','wezterm','zellij','starship','mise','node','python','git','gh','claude',
               'eza','bat','fzf','rg','fd','zoxide','lazygit','dust','nvim','jq','bw') {
  $c = Get-Command $t -ErrorAction SilentlyContinue
  '{0,-12} {1}' -f $t, $(if ($c) { 'OK ' + $c.Source } else { 'MISSING' })
}
```

Expected results, calibrated against the source machine (2026-07-28):

| Result | Tools | Meaning |
|---|---|---|
| **Must be OK** | `pwsh`, `wezterm`, `zellij`, `starship`, `mise`, `node`, `python`, `git`, `gh`, `claude`, `eza`, `bat`, `rg`, `fd`, `zoxide`, `lazygit`, `dust`, `nvim`, `jq`, `bw` | Any MISSING here is a real failure |
| **Known-broken** | `fzf` | Currently MISSING on the source machine — corrupted winget install. Fix with `winget install --id junegunn.fzf --force`. See `BOOTSTRAP_LOG.md`. |
| **Expected MISSING** | `rustc`, `go`, `php`, `btop`, `ntop` | Deliberately not installed. Starship omits those prompt segments; `top` is undefined. Not failures. |

`jq` deserves emphasis: it is **not** optional. The Claude Code safeguard hooks parse
their payloads with it, and if it is absent they fail *silently* — no error in Claude
Code, the safeguards simply are not running.

Do **not** substitute `winget list` for this loop. It reports fzf as installed on the
source machine even though the binary does not exist.

### Behavior checks

- [ ] Type a partial command from history → autosuggestion appears as ghost-text.
- [ ] Press Tab on a partial command → menu completion appears (not just first match).
- [ ] Press `Ctrl+R` → fzf history search opens. **(Known-failing: see fzf above.)**
- [ ] Press `Ctrl+T` → fzf file picker; `Alt+C` → directory picker. Same dependency.
- [ ] `ls`, `ll`, `la`, `tree` all run eza variants without error.
- [ ] `cat <somefile>` runs bat with syntax highlighting.
- [ ] `lg` opens lazygit if cwd is a git repo.
- [ ] `cd <partial-name>` works via zoxide once the dir has been visited at least once.
- [ ] `git init` in `$env:USERPROFILE` is refused with the safety message.
- [ ] `git init` in any subdirectory works normally.

### Terminal stack checks (brief 10)

```pwsh
wezterm --version                                  # 20240203-110809-5046fc22
zellij --version                                   # 0.44.3
Test-Path "$env:USERPROFILE\.config\wezterm\wezterm.lua"
Test-Path "$env:APPDATA\Zellij\config\config.kdl"  # note: Roaming, NOT .config
zellij setup --check                               # prints the path it really reads
wezterm ls-fonts --text "ab"                       # must print a JETBRAINSMONONERDFONT-*.TTF
```

- [ ] Catppuccin Mocha background in WezTerm (warm dark, not WezTerm's default).
- [ ] Ligatures render — `->`, `!=`, `=>` become single glyphs.
- [ ] Window buttons integrated into the tab bar, Windows-style.
- [ ] `Alt+d` / `Alt+r` split; `Alt+h/j/k/l` navigates; `Alt+1..9` jumps tabs.
- [ ] `Alt+Shift+R` enters resize mode; `h/j/k/l` repeat-resizes; `Esc` exits.
- [ ] **On a Spanish keyboard layout:** `Alt+<letter>` bindings actually fire (this is
      what `send_composed_key_when_left_alt_is_pressed = false` buys), *and* AltGr still
      composes `@`, `€`, `~`.
- [ ] `zellij` launches: status bar visible, pane frames on, `Ctrl+p` enters pane mode.
- [ ] New Zellij tabs open in `default_cwd`, not `$HOME`.
- [ ] `$PSVersionTable.PSVersion` is 7.x inside both WezTerm and Zellij.

### Font checks (brief 01)

```pwsh
(Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Windows\Fonts" |
   Where-Object Name -match 'JetBrains').Count                       # 32
(Get-ItemProperty 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts').PSObject.Properties |
   Where-Object Name -match 'JetBrains' | Measure-Object              # registry entries present
```

- [ ] 32 files: 16 `JetBrainsMonoNerdFont-*` + 16 `JetBrainsMonoNLNerdFont-*`.
- [ ] Registry entries exist (fonts dropped in the folder without registration are
      invisible to Windows — the #1 silent font failure).
- [ ] Font picker shows `JetBrainsMono NF`. This is the *expected* name and does not
      contradict the config asking for `JetBrainsMono Nerd Font`.

### Editor checks

- [ ] `nvim` opens the LazyVim dashboard.
- [ ] `:Lazy` shows all plugins as "loaded," none failing.
- [ ] `:Mason` shows expected LSPs available.
- [ ] System clipboard yank/paste works (`"+y` / `"+p`).
- [ ] Treesitter highlighting active in a sample file (open a `.lua` or `.ts` file).

### Claude Code checks

- [ ] `claude --version` reports a version (as-built 2.1.220).
- [ ] `claude` opens an interactive session, dark theme, fullscreen TUI. **No model pin** —
      the `"model"` key was removed, so it follows the CLI default. Don't flag that as drift.
- [ ] Running a benign Bash-allowlisted command (`ls` equivalent) does NOT prompt for permission.
- [ ] MCP servers respond — `claude mcp list` shows them as connected.
- [ ] `jq` resolves, `bash` resolves, and `~/Automation/{logs,backups}` exist — the hooks
      write to those paths and do not create them.
- [ ] Trigger a `Write`/`Edit` and confirm a timestamped copy lands in
      `~/Automation/backups/` and a line lands in `~/Automation/logs/file-operations.log`.
      **If nothing appears, `jq` is missing** — the hooks fail silently. See brief 11.
- [ ] Claude Code was restarted after any `settings.json` change; hooks load at startup.

### Secret store checks (depends on brief 09 outcome)

- [ ] `secret TEST_VAR test/sample` (or whichever path Daniel has stored) populates `$env:TEST_VAR`.
- [ ] The secret value does NOT appear in PowerShell history (`Get-History`).

### Performance checks

- [ ] `Measure-Command { pwsh -NoLogo -Command 'exit' }` reports < 1.5s.
- [ ] Startup of an interactive `pwsh` session (with profile loaded) feels instantaneous (no visible pause before prompt appears).

## Failure handling

If any check fails:

1. **Check zero first.** If `$PSVersionTable.PSVersion` says 5.1, fix that before
   diagnosing anything else — it produces a cascade of unrelated-looking failures.
2. **Don't try to fix silently.** Surface the failure to Daniel with the specific check that failed and the brief that's most likely responsible.
3. **Don't declare "done with caveats."** Either the bootstrap matches the Linux feel, or it doesn't. Partial pass is a fail — with the exception of the items listed as "Expected MISSING" above, which are decisions, not failures.
4. **Document the failure** in `BOOTSTRAP_LOG.md` at the repo root (append a dated
   entry; it already exists), so future sessions can learn from it.
