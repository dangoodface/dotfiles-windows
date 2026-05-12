# Brief 02 — Shell (PowerShell 7 profile)

## Goal

Set up a PowerShell 7 profile that gives Daniel the same shell behaviors he has on Linux zsh: history search, autosuggestions, syntax highlighting, modern aliases, fzf-Ctrl-R, mise activation, zoxide cd, and the safety net that refuses `git init` in `$HOME`.

## Source of truth

The Linux zshrc lives at https://github.com/dangoodface/dotfiles in `zsh/.zshrc`. The implementing Claude should read it end-to-end and translate behavior-for-behavior, not line-for-line. PowerShell idioms differ; preserve the *intent*.

## Constraints

- Use `$PROFILE.CurrentUserAllHosts` (not `$PROFILE` which is host-specific).
- Source a separate fragment file (e.g. `~/Documents/PowerShell/dotfiles-fragment.ps1`) from `$PROFILE` rather than putting everything in the main profile, so the user can opt out cleanly by removing the source line.
- Keep startup time under 1 second on a modern machine. PSReadLine + zoxide + starship together should not exceed ~500ms.
- Idempotent profile install — re-running the brief must not duplicate the source line in `$PROFILE`.

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
| `secret()` zsh function | Defer until brief 09 picks the secret backend |
| `git()` wrapper refusing `git init` in `$HOME` | function `git { if ($PWD.Path -eq $HOME -and $args[0] -eq 'init') { Write-Error 'Refusing to git init in $HOME'; return }; & git.exe @args }` |

## Verification

Open a fresh PowerShell 7 session:

- Prompt is the starship prompt with all glyphs visible.
- Typing a partial command shows ghost-text autosuggestion from history.
- Tab triggers a menu completion (not just first match).
- `Ctrl+R` opens fzf history search.
- `ls`, `cat`, `lg`, `cd <partial>` all work as expected.
- `git init` in `$HOME` is refused; `git init` in any subdirectory works.
- Startup time: `Measure-Command { pwsh -NoLogo -Command 'exit' }` should report < 1.5s.

## Implementation hints

- Install PSReadLine if not already present: `Install-Module PSReadLine -Force -Scope CurrentUser`. PowerShell 7 ships with PSReadLine 2.x preinstalled, but check the version — features like `PredictionViewStyle ListView` need PSReadLine 2.2+.
- Install PSFzf: `Install-Module -Name PSFzf -Scope CurrentUser`.
- The `reference-configs/pwsh-profile-skeleton.ps1` in this repo is a starting point; the implementing Claude is expected to extend and customize it, not just copy verbatim.
- Sourcing the fragment from `$PROFILE`: append `. "$HOME\Documents\PowerShell\dotfiles-fragment.ps1"` once. Check first that the line isn't already there.

## Gotchas

- `Set-Alias` cannot pass arguments. For aliases that need flags (most of them), use a function wrapper: `function ll { eza -la --icons --git --header @args }`.
- `cat` and `ls` are built-in PowerShell aliases for `Get-Content` and `Get-ChildItem`. Overriding them via `Set-Alias` requires `-Force`. Some users want to keep the PowerShell defaults — surface this trade-off to Daniel before committing to the override.
- Execution policy must permit script execution. `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` if needed.
- PSFzf requires `fzf.exe` to be in PATH (brief 05 installs it).
- mise's PowerShell activation requires mise 2024.x or newer. If older, surface and update.
