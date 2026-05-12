# dotfiles-fragment.ps1 — sourced from $PROFILE.CurrentUserAllHosts
# Equivalent to ~/.zshrc on Linux. See brief 02 for the porting contract.
# Reload after editing with: . $PROFILE
#
# This is a SKELETON. The implementing Claude is expected to extend it based
# on what's actually installed on the target machine. Anything depending on a
# tool that's not yet installed should fail gracefully (silent skip) rather
# than raise on profile load.

# ─── PSReadLine: history + autosuggestions + syntax highlighting ─────────
if (Get-Module -ListAvailable -Name PSReadLine) {
    Set-PSReadLineOption -HistorySaveStyle SaveIncrementally
    Set-PSReadLineOption -MaximumHistoryCount 50000
    Set-PSReadLineOption -PredictionSource HistoryAndPlugin
    Set-PSReadLineOption -PredictionViewStyle ListView
    Set-PSReadLineOption -EditMode Emacs
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
}

# ─── PSFzf: Ctrl+R history, Ctrl+T file picker ───────────────────────────
if (Get-Module -ListAvailable -Name PSFzf) {
    Import-Module PSFzf
    Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
}

# ─── PATH additions ──────────────────────────────────────────────────────
$userBin = Join-Path $HOME '.local\bin'
$cargoBin = Join-Path $HOME '.cargo\bin'
foreach ($p in @($userBin, $cargoBin)) {
    if ((Test-Path $p) -and ($env:Path -notlike "*$p*")) {
        $env:Path = "$p;$env:Path"
    }
}

# ─── Starship prompt ─────────────────────────────────────────────────────
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}

# ─── mise: runtime version manager ───────────────────────────────────────
if (Get-Command mise -ErrorAction SilentlyContinue) {
    mise activate pwsh | Out-String | Invoke-Expression
}

# ─── zoxide: smart cd ────────────────────────────────────────────────────
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell --cmd cd | Out-String) })
}

# ─── Aliases / function wrappers ─────────────────────────────────────────
# PowerShell built-ins ls/cat are aliases for Get-ChildItem/Get-Content.
# We override with eza/bat. Use functions (not Set-Alias) to pass flags.
if (Get-Command eza -ErrorAction SilentlyContinue) {
    Remove-Item Alias:ls -ErrorAction SilentlyContinue
    function ls   { eza --icons --git @args }
    function ll   { eza -la --icons --git --header @args }
    function la   { eza -la --icons --git @args }
    function tree { eza --tree --icons @args }
}

if (Get-Command bat -ErrorAction SilentlyContinue) {
    Remove-Item Alias:cat -ErrorAction SilentlyContinue
    function cat { bat --paging=never @args }
}

if (Get-Command lazygit -ErrorAction SilentlyContinue) {
    function lg { lazygit @args }
}

# btop / ntop — best effort
if (Get-Command btop -ErrorAction SilentlyContinue) {
    function top { btop @args }
} elseif (Get-Command ntop -ErrorAction SilentlyContinue) {
    function top { ntop @args }
}

# ─── Safety: refuse `git init` in $HOME ──────────────────────────────────
# Mirrors the zsh wrapper. Prevents accidental tracking of every dotfile.
function git {
    if ($PWD.Path -eq $HOME -and $args.Count -gt 0 -and $args[0] -eq 'init') {
        Write-Host "Refusing to 'git init' in `$HOME. cd into a project dir first." `
                   -ForegroundColor Yellow
        return
    }
    & git.exe @args
}

# ─── secret() — fill in once brief 09 chooses a backend ──────────────────
# function secret { param($name, $path) Set-Item "env:$name" (<backend-cmd> $path) }
