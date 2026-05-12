# Brief 00 — Prerequisites

## Goal

Confirm the target machine can host the rest of this bootstrap. Install the two foundation tools (PowerShell 7 and the winget package manager) if missing.

## Constraints

- Native Windows 10 22H2+ or Windows 11.
- User must have Administrator access for the initial install of PowerShell 7. After that, no brief should require admin.
- All subsequent installs use `winget --scope user` where the package supports it.

## Verification

```pwsh
$PSVersionTable.PSVersion          # >= 7.4
winget --version                    # >= 1.6
[System.Environment]::OSVersion     # Windows 10 build 19045+ or Windows 11
```

## Implementation hints (the implementing Claude can override)

- PowerShell 7 (`pwsh`) is separate from the legacy `powershell` (5.1) shipped with Windows. Install via `winget install --id Microsoft.PowerShell --scope user` or via the MSI from GitHub releases. Set it as the default profile in whatever terminal emulator the user has.
- `winget` ships with Windows 11 and modern Windows 10. If absent, install "App Installer" from the Microsoft Store.
- Do NOT install `scoop` yet — defer until a brief actually needs a scoop-only tool. Some tools (like `btop`) may end up coming via scoop instead of winget if winget doesn't have them.

## Gotchas

- Execution policy: Windows blocks unsigned PowerShell scripts by default. The user-side fix is `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`. Brief 02 covers this in the shell setup; flag it here only if it blocks bootstrap.
- Some corporate Windows installs disable winget. If so, surface to Daniel before proceeding — there's no automated workaround.
