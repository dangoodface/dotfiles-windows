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
| **btop** | btop | **SKIPPED** — not installed on the source machine | Neither `btop` nor `ntop` resolve. The `top` function in the fragment is guarded, so it simply never gets defined. Accepted gap. |
| **jq** | jq | `winget install --id jqlang.jq` | **Required, not optional** — the Claude Code safeguard hooks in brief 08 parse JSON with `jq`. Without it they fail silently. |
| **Bitwarden CLI** | (n/a) | `winget install --id Bitwarden.CLI` | Backs the `secret` function; see brief 09. |
| **uv** | uv | direct install into `%USERPROFILE%\.local\bin` | Present as-built (`uv`, `uvw`, `uvx`). Not referenced by the profile; noted so the `.local\bin` PATH prepend has a known purpose. |

## As-built versions (source machine, 2026-07-28)

All installed **per-user via winget**, each package getting its own PATH entry under
`%LOCALAPPDATA%\Microsoft\WinGet\Packages\`. No scoop on this machine.

| Tool | Installed | Update available |
|---|---|---|
| bat | 0.26.1 | — |
| dust | 1.2.4 | — |
| eza | 0.23.4 | 0.23.5 |
| fd | 10.4.2 | — |
| **fzf** | **0.72.0 — BROKEN, see below** | 0.74.1 |
| jq | 1.8.2 | — |
| lazygit | 0.61.1 | 0.63.1 |
| ripgrep (MSVC) | 15.1.0 | 15.2.0 |
| starship | 1.25.1 | 1.26.0 |
| zoxide | 0.9.9 | 0.10.0 |
| mise | 2026.5.6 | 2026.7.12 |
| neovim | 0.12.2 | 0.12.4 |
| Bitwarden CLI | present | — |

## KNOWN BREAKAGE — fzf

`winget list` reports fzf 0.72.0 installed and its PATH entry exists, but **the
binary is gone**. The package directory contains only its manifest database:

```
%LOCALAPPDATA%\Microsoft\WinGet\Packages\junegunn.fzf_Microsoft.Winget.Source_8wekyb3d8bbwe\
  junegunn.fzf_Microsoft.Winget.Source_8wekyb3d8bbwe.db      <- 16 KB, and nothing else
```

`Get-Command fzf` → not found. Because the PSFzf block in the fragment is guarded on
`Get-Command fzf`, it **silently skips**: `Ctrl+R` fuzzy history, `Ctrl+T` file
picker and `Alt+C` directory picker are all dead, with no error at shell startup.

Fix:

```pwsh
winget install --id junegunn.fzf --force   # reinstall, also moves to 0.74.1
# restart the shell so the fragment's PATH rebuild picks it up
```

A fresh machine following this brief normally should not hit this — it is a
corrupted install on the source machine, not a design flaw. But **verify the binary,
not `winget list`**, because `winget list` lies here.

## Constraints

- All installs must be `--scope user` if winget supports it, to avoid admin prompts.
- Idempotent. Skip tools that are already installed (check with `Get-Command <tool> -ErrorAction SilentlyContinue`).
- Don't install tools that aren't actually used by Daniel's profile or alias set. The list above is the full Linux set; if a tool's only purpose is an alias that won't get translated to Windows, skip it.

## Verification

```pwsh
foreach ($tool in 'eza','bat','fzf','rg','fd','zoxide','lazygit','dust','jq','bw') {
  $cmd = Get-Command $tool -ErrorAction SilentlyContinue
  "$tool : $(if ($cmd) { 'OK ' + $cmd.Source } else { 'MISSING' })"
}
```

All entries should report `OK <path>`. Do **not** substitute `winget list` for this —
see the fzf breakage above, where `winget list` reports a package that has no binary.

Known-acceptable `MISSING` on the source machine: `btop`/`ntop` (skipped by design).
Known-unacceptable: `fzf` (regression, fix it).

## Implementation hints

- Batch the installs into one or two `winget install` calls if winget supports multi-package install in the version present, otherwise loop.
- After installing fzf, restart the PowerShell session before running brief 02's verification — PSFzf needs `fzf.exe` discoverable in PATH.
- For `btop` specifically: winget may not have a current build. Acceptable fallbacks (in order): scoop's btop bucket, ntop (Windows-native process viewer), or skip entirely with a note that the `top` alias in the PowerShell profile won't have a backing tool.

## Gotchas

- **ripgrep package ID.** Use `BurntSushi.ripgrep.MSVC` not `BurntSushi.ripgrep.GNU` on Windows. The MSVC build is the canonical Windows binary.
- **eza on Windows is recent.** The `eza-community.eza` winget package was added around v0.18; older winget caches may not have it. If install fails, fall back to scoop: `scoop install eza`.
- **Some tools install but don't auto-add to PATH.** Specifically older fzf and lazygit installers. After a winget install loop, refresh the session's PATH (`$env:Path = [System.Environment]::GetEnvironmentVariable('Path','User') + ';' + [System.Environment]::GetEnvironmentVariable('Path','Machine')`) before running verification.
