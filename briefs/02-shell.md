# Brief 02 — Shell (PowerShell 7 profile)

## Goal

Set up a PowerShell 7 profile that gives Daniel the same shell behaviors he has on Linux zsh: history search, autosuggestions, syntax highlighting, modern aliases, fzf-Ctrl-R, mise activation, zoxide cd, and the safety net that refuses `git init` in `$HOME`.

## Source of truth

The Linux zshrc lives at https://github.com/dangoodface/dotfiles in `zsh/.zshrc`. The implementing Claude should read it end-to-end and translate behavior-for-behavior, not line-for-line. PowerShell idioms differ; preserve the *intent*.

## As-built layout (source machine, 2026-07-28)

The fragment does **not** live next to the profile. Reproduce this split:

| Piece | Path |
|---|---|
| Profile (2-line stub) | `C:\Users\51372\OneDrive - <Org>\Documents\PowerShell\profile.ps1` — i.e. `$PROFILE.CurrentUserAllHosts` |
| Fragment (all the logic) | `%USERPROFILE%\.config\powershell\dotfiles-fragment.ps1` |
| Repo copy of the fragment | `reference-configs/pwsh-dotfiles-fragment.ps1` |

The entire stub is:

```pwsh
# dotfiles-windows fragment
if (Test-Path "C:\Users\51372\.config\powershell\dotfiles-fragment.ps1") { . "C:\Users\51372\.config\powershell\dotfiles-fragment.ps1" }
```

`$PROFILE.CurrentUserCurrentHost` (`Microsoft.PowerShell_profile.ps1`) does not
exist, and should stay that way — one profile, all hosts.

**Why the fragment is not under `Documents\PowerShell\`:** on this machine
`Documents` is **redirected into a corporate `OneDrive - <Org>` folder**. Anything placed there syncs to
the corporate cloud tenant. The stub has to live there (PowerShell decides that
path, not us), but it is content-free — a guard and a dot-source. All actual
dev-tooling config lives outside OneDrive at `~/.config/powershell\`.

On a new machine, resolve the stub path dynamically rather than assuming:

```pwsh
$PROFILE.CurrentUserAllHosts    # may or may not be OneDrive-redirected
```

Also note: **PowerShell 7 here is the MSIX/Store package, not an MSI.** That has
no effect on the profile, but it is the reason brief 10's terminal configs point at
a versioned `WindowsApps` path. If a terminal ever launches 5.1 by mistake it reads
`Documents\WindowsPowerShell\` instead and *none* of this loads — see brief 10.

## Constraints

- Use `$PROFILE.CurrentUserAllHosts` (not `$PROFILE` which is host-specific).
- Keep the fragment **outside** any cloud-synced folder (see above). Source it from
  the profile so the user can opt out cleanly by deleting one line.
- Keep startup time under 1 second on a modern machine. PSReadLine + zoxide + starship together should not exceed ~500ms.
- Idempotent profile install — re-running the brief must not duplicate the source line in `$PROFILE`.
- Execution policy as-built: `LocalMachine = RemoteSigned`, `CurrentUser = Undefined`.
  Run `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` on the new machine if the
  profile is blocked.

## What to translate from `zsh/.zshrc`

| Linux behavior | Windows equivalent |
|---|---|
| HISTFILE, HISTSIZE, SHARE_HISTORY | PSReadLine has built-in history (`~/AppData/Roaming/Microsoft/Windows/PowerShell/PSReadLine/ConsoleHost_history.txt`); set `Set-PSReadLineOption -HistorySaveStyle SaveIncrementally -MaximumHistoryCount 50000` |
| compinit + menu select | `Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete` |
| zsh-autosuggestions | `Set-PSReadLineOption -PredictionSource HistoryAndPlugin -PredictionViewStyle ListView` |
| zsh-syntax-highlighting | PSReadLine's `Set-PSReadLineOption -Colors @{...}` covers most of this |
| Aloxaf/fzf-tab | Install `PSFzf` module, bind `Ctrl+R` to `Invoke-FzfHistory` and `Ctrl+T` to file picker |
| `eval "$(starship init zsh)"` | `Invoke-Expression (&starship init powershell)` |
| `eval "$(mise activate zsh)"` | `mise activate pwsh \| Out-String \| Invoke-Expression` |
| `eval "$(zoxide init zsh --cmd cd)"` | `Invoke-Expression (& { (zoxide init powershell --cmd cd \| Out-String) })` |
| `alias ls='eza --icons --git'` | `Set-Alias -Name ls -Value eza` (or function wrapper for flag passthrough) |
| `alias cat='bat --paging=never'` | function wrapper, since PowerShell `cat` is a built-in alias for `Get-Content` and aliases can't easily inject flags |
| `secret()` zsh function | **Ported — Bitwarden CLI backend.** Brief 09 chose Option B; the function is live in the fragment |
| `git()` wrapper refusing `git init` in `$HOME` | function `git { if ($PWD.Path -eq $HOME -and $args[0] -eq 'init') { Write-Error 'Refusing to git init in $HOME'; return }; & git.exe @args }` |

## Verification

Open a fresh PowerShell 7 session:

- Prompt is the starship prompt with all glyphs visible.
- Typing a partial command shows ghost-text autosuggestion from history.
- Tab triggers a menu completion (not just first match).
- `Ctrl+R` opens fzf history search; `Ctrl+T` the file picker; `Alt+C` the directory
  picker. If any silently does nothing, `fzf.exe` is missing and the fragment's guard
  skipped the PSFzf block without error — see brief 05.
- `ls`, `cat`, `lg`, `cd <partial>` all work as expected.
- `git init` in `$HOME` is refused; `git init` in any subdirectory works.
- Startup time: `Measure-Command { pwsh -NoLogo -Command 'exit' }` should report < 1.5s.
- `$PSVersionTable.PSVersion` reports 7.x, not 5.1.

## Implementation hints

- Module versions as-built: **PSReadLine 2.4.5** (PS7's bundled copy) and
  **PSFzf 2.7.10**. Note PSReadLine **2.0.0** is also present — that is Windows
  PowerShell 5.1's copy, visible from `Get-Module -ListAvailable`. The fragment
  therefore selects the highest version explicitly rather than trusting the first
  hit; see the `$psrl` guard.
- Install PSFzf: `Install-Module -Name PSFzf -Scope CurrentUser`.
- Copy `reference-configs/pwsh-dotfiles-fragment.ps1` to
  `%USERPROFILE%\.config\powershell\dotfiles-fragment.ps1`. This is the **live
  fragment verbatim**, not a skeleton — it is the source of truth. Extend it rather
  than rewriting.
- Sourcing the fragment from `$PROFILE`: append the 2-line guard shown above once,
  with the path rewritten for the new machine's username. Check first that it isn't
  already there.

## Gotchas — all of these are load-bearing, learned the hard way

- **Stale `$env:Path`.** Windows does not propagate User/Machine PATH changes to
  already-running parent processes. A `pwsh` launched from a shell whose parent
  predates a `winget install` sees a stale PATH and newly-installed binaries do not
  resolve. The fragment rebuilds `$env:Path` from the registry-persistent
  Machine+User values on every load. Keep that block first.
- **`mise activate pwsh` throws 4× on a fresh shell.** Its command-not-found hook
  calls `[PSConsoleReadLine]::GetHistoryItems()[-1]`, which raises
  `NullReferenceException` when history is empty. The fragment pre-sets
  `$Global:__mise_pwsh_command_not_found = $true` to skip registering that hook.
  Cost: mise no longer auto-installs runtimes on an unknown command. Per-project
  runtime switching via `.mise.toml` is unaffected.
- **PSReadLine 2.0 co-installed.** `PredictionSource`/`PredictionViewStyle` need
  2.2+. The fragment version-guards them *and* wraps them in try/catch, because
  non-VT hosts (CI subshells) reject `ListView` at runtime even on 2.4.5.
- **`$env:_ZO_DOCTOR = 0`** before zoxide init, or zoxide nags on every shell.
- **zoxide must init near the end** of the fragment so it wraps the already-defined
  hooks rather than being wrapped.
- `Set-Alias` cannot pass arguments. For aliases that need flags (most of them), use a function wrapper: `function ll { eza -la --icons --git --header @args }`.
- `cat` and `ls` are built-in PowerShell aliases for `Get-Content` and `Get-ChildItem`. The fragment overrides both with `Remove-Item Alias:... -Force` then a function. This is a deliberate, confirmed choice — `Get-ChildItem` is still reachable by its real name.
- **PSFzf requires `fzf.exe` on PATH** (brief 05 installs it). If `fzf.exe` is absent
  the fragment's guard silently skips the whole block — you lose `Ctrl+R`/`Ctrl+T`/`Alt+C`
  with no error message. This actually happened on the source machine (a winget install
  that left a manifest but no binary); see brief 05's RESOLVED section, which includes an
  optional noisy-guard variant if silent degradation isn't acceptable.
- mise's PowerShell activation requires mise 2024.x or newer. As-built: **2026.5.6**.
