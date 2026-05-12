# Brief 03 — Prompt (Starship)

## Goal

Install Starship and copy the Linux `starship.toml` verbatim. Starship is fully cross-platform; no porting is needed.

## Constraints

- Use the exact same `starship.toml` Daniel runs on Linux. The config is in `reference-configs/starship.toml` in this repo (mirrored from his Linux dotfiles).
- Starship config goes at `$env:USERPROFILE\.config\starship.toml` (Starship reads this path on Windows by default).
- Idempotent — don't overwrite an existing `starship.toml` without diffing first; if it already matches, leave it alone.

## Verification

```pwsh
starship --version              # >= 1.20
Test-Path "$env:USERPROFILE\.config\starship.toml"
# Open a new PowerShell session — prompt should render the segmented Tokyo Night bar
# with directory + git + runtime versions + clock, all glyphs visible.
```

## Implementation hints

- Install: `winget install --id Starship.Starship`.
- The shell init line (`Invoke-Expression (&starship init powershell)`) is added by brief 02 in the PowerShell profile fragment. This brief just installs the binary and drops the config.
- Copy `reference-configs/starship.toml` to `$env:USERPROFILE\.config\starship.toml`. Create the `.config` directory if absent.
- The starship.toml uses Nerd Font glyphs (e.g. ` `, ` `, `󰈙 `). These will render as `?` boxes if the terminal isn't using a Nerd Font. If verification shows boxes, the issue is in brief 01 (font install) or in the terminal emulator's font setting, not in this brief.

## Gotchas

- The Linux config's `[directory.substitutions]` table maps "Documents", "Downloads", "Music", "Pictures" to icon glyphs. On Windows these are valid folder names too — the substitution will work identically. No change needed.
- The runtime modules (`[nodejs]`, `[rust]`, `[golang]`, `[php]`) only display when their respective runtimes are present. If the user doesn't have all four installed, the prompt simply skips them — not an error.
- Starship looks for config at `$STARSHIP_CONFIG` first, then `~/.config/starship.toml`. On Windows `~` resolves to `$env:USERPROFILE`. Don't set `$STARSHIP_CONFIG` unless you have a specific reason — it adds a per-machine config-path divergence.
