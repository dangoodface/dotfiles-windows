# Brief 05 — CLI tools

## Goal

Install the modern Unix-replacement CLI tools Daniel uses on Linux. All have native Windows builds.

## Tools and Windows install identifiers

| Tool | Linux package | Windows install | Notes |
|---|---|---|---|
| **eza** | eza | `winget install --id eza-community.eza` | Modern `ls` replacement |
| **bat** | bat | `winget install --id sharkdp.bat` | `cat` with syntax highlighting |
| **fzf** | fzf | `winget install --id junegunn.fzf` | Fuzzy finder; required by PSFzf in brief 02 |
| **ripgrep** | ripgrep | `winget install --id BurntSushi.ripgrep.MSVC` | Fast `grep` |
| **fd** | fd-find | `winget install --id sharkdp.fd` | Fast `find` |
| **zoxide** | zoxide | `winget install --id ajeetdsouza.zoxide` | Smart `cd`; activated by brief 02 |
| **lazygit** | lazygit | `winget install --id JesseDuffield.lazygit` | Git TUI; aliased to `lg` in profile |
| **dust** | dust | `winget install --id bootandy.dust` | Disk-usage tree view |
| **btop** | btop | best-effort — `scoop install btop` if available, else fall back to `ntop` or skip | Process viewer; on Windows the closest equivalent may be `ntop` (`scoop install ntop`) |

## Constraints

- All installs must be `--scope user` if winget supports it, to avoid admin prompts.
- Idempotent. Skip tools that are already installed (check with `Get-Command <tool> -ErrorAction SilentlyContinue`).
- Don't install tools that aren't actually used by Daniel's profile or alias set. The list above is the full Linux set; if a tool's only purpose is an alias that won't get translated to Windows, skip it.

## Verification

```pwsh
foreach ($tool in 'eza','bat','fzf','rg','fd','zoxide','lazygit','dust') {
  $cmd = Get-Command $tool -ErrorAction SilentlyContinue
  "$tool : $(if ($cmd) { 'OK ' + $cmd.Source } else { 'MISSING' })"
}
```

All entries should report `OK <path>`.

## Implementation hints

- Batch the installs into one or two `winget install` calls if winget supports multi-package install in the version present, otherwise loop.
- After installing fzf, restart the PowerShell session before running brief 02's verification — PSFzf needs `fzf.exe` discoverable in PATH.
- For `btop` specifically: winget may not have a current build. Acceptable fallbacks (in order): scoop's btop bucket, ntop (Windows-native process viewer), or skip entirely with a note that the `top` alias in the PowerShell profile won't have a backing tool.

## Gotchas

- **ripgrep package ID.** Use `BurntSushi.ripgrep.MSVC` not `BurntSushi.ripgrep.GNU` on Windows. The MSVC build is the canonical Windows binary.
- **eza on Windows is recent.** The `eza-community.eza` winget package was added around v0.18; older winget caches may not have it. If install fails, fall back to scoop: `scoop install eza`.
- **Some tools install but don't auto-add to PATH.** Specifically older fzf and lazygit installers. After a winget install loop, refresh the session's PATH (`$env:Path = [System.Environment]::GetEnvironmentVariable('Path','User') + ';' + [System.Environment]::GetEnvironmentVariable('Path','Machine')`) before running verification.
