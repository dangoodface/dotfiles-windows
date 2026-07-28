# dotfiles-fragment.ps1 — sourced from $PROFILE.CurrentUserAllHosts
# Windows-native translation of dangoodface/dotfiles zsh/.zshrc.
# Reload after editing with: . $PROFILE
#
# Lives outside OneDrive at $HOME\.config\powershell\ so dev-tooling state
# doesn't sync to the corporate OneDrive tenant.
#
# NOTE: this is the live fragment verbatim except for the line above, which names the
# employer on the source machine. Only cosmetic difference; do not "resync" it back.

# --- Refresh $env:Path from registry ---
# Windows doesn't propagate User/Machine PATH changes to already-running
# parent processes. If pwsh was launched from a shell whose parent (Explorer,
# Terminal host) predates a `winget install`, $env:Path will be stale and
# newly-installed binaries won't resolve. Rebuilding from the registry-persistent
# Machine+User PATHs here ensures the fragment always sees the freshest PATH.
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
            [System.Environment]::GetEnvironmentVariable("Path", "User")

# --- PSReadLine: history + autosuggestions + syntax highlighting ---
# Guarded: prediction features need PSReadLine 2.2+ (PS7 ships 2.4.5).
# Windows PowerShell 5.1 ships PSReadLine 2.0 — skip unsupported options there.
$psrl = Get-Module -ListAvailable -Name PSReadLine | Sort-Object Version -Descending | Select-Object -First 1
if ($psrl) {
    Set-PSReadLineOption -HistorySaveStyle SaveIncrementally
    Set-PSReadLineOption -MaximumHistoryCount 50000
    Set-PSReadLineOption -EditMode Emacs
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
    if ($psrl.Version -ge [version]'2.2.0') {
        try {
            Set-PSReadLineOption -PredictionSource HistoryAndPlugin
            Set-PSReadLineOption -PredictionViewStyle ListView
        } catch {
            # Non-VT terminals (CI subshells) reject ListView — silently skip
        }
    }
}

# --- PSFzf: Ctrl+R history search, Ctrl+T file picker, Alt+C dir picker ---
if ((Get-Module -ListAvailable -Name PSFzf) -and (Get-Command fzf -ErrorAction SilentlyContinue)) {
    Import-Module PSFzf
    Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
    Set-PSReadLineKeyHandler -Chord 'Alt+c' -ScriptBlock { Invoke-FuzzySetLocation }
}

# --- PATH additions: mirror Linux ~/.local/bin and ~/.cargo/bin prepends ---
$userBin = Join-Path $HOME '.local\bin'
$cargoBin = Join-Path $HOME '.cargo\bin'
foreach ($p in @($userBin, $cargoBin)) {
    if ((Test-Path $p) -and ($env:Path -notlike "*$p*")) {
        $env:Path = "$p;$env:Path"
    }
}

# --- Starship prompt ---
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}

# --- mise: runtime version manager (auto-switches per .mise.toml) ---
# Pre-set $__mise_pwsh_command_not_found = $true so `mise activate pwsh` skips
# registering its command-not-found hook. That hook calls
# [PSConsoleReadLine]::GetHistoryItems()[-1] which throws NullReferenceException
# when history is empty (fresh shell, no commands yet), producing 4x noise at
# profile load. Disabling the hook means mise won't auto-install runtimes on
# unknown-command attempts — minor UX loss; runtime switching per .mise.toml
# still works normally.
if (Get-Command mise -ErrorAction SilentlyContinue) {
    $Global:__mise_pwsh_command_not_found = $true
    mise activate pwsh | Out-String | Invoke-Expression
}

# --- Aliases: override PowerShell built-ins ls/cat with eza/bat ---
if (Get-Command eza -ErrorAction SilentlyContinue) {
    Remove-Item Alias:ls -ErrorAction SilentlyContinue -Force
    function ls   { eza --icons --git @args }
    function ll   { eza -la --icons --git --header @args }
    function la   { eza -la --icons --git @args }
    function tree { eza --tree --icons @args }
}

if (Get-Command bat -ErrorAction SilentlyContinue) {
    Remove-Item Alias:cat -ErrorAction SilentlyContinue -Force
    function cat { bat --paging=never @args }
}

if (Get-Command lazygit -ErrorAction SilentlyContinue) {
    function lg { lazygit @args }
}

# btop / ntop — best effort, falls through silently if neither installed
if (Get-Command btop -ErrorAction SilentlyContinue) {
    function top { btop @args }
} elseif (Get-Command ntop -ErrorAction SilentlyContinue) {
    function top { ntop @args }
}

# --- Safety: refuse `git init` in $HOME (mirrors Linux zsh wrapper) ---
function git {
    if ($PWD.Path -eq $HOME -and $args.Count -gt 0 -and $args[0] -eq 'init') {
        Write-Host "Refusing to 'git init' in `$HOME. cd into a project dir first." -ForegroundColor Yellow
        return
    }
    & git.exe @args
}

# --- secret() — Bitwarden CLI backend ---
# Usage:  secret BRAVE_API_KEY brave-search
#         (equivalent to: $env:BRAVE_API_KEY = bw get password brave-search --raw)
# Requires `bw login` and `$env:BW_SESSION` set. Keeps the secret name out of
# command history that would otherwise show `$env:BRAVE_API_KEY = "..."`.
function secret {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$BwItem
    )
    if (-not (Get-Command bw -ErrorAction SilentlyContinue)) {
        Write-Error "bw (Bitwarden CLI) not found in PATH"
        return
    }
    if (-not $env:BW_SESSION) {
        Write-Error "BW_SESSION not set. Run: `$env:BW_SESSION = (bw unlock --raw)"
        return
    }
    Set-Item "env:$Name" (bw get password $BwItem --raw)
}

# --- zoxide: smart cd (must load near end so it wraps existing hooks) ---
$env:_ZO_DOCTOR = 0
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell --cmd cd | Out-String) })
}
