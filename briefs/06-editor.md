# Brief 06 — Editor (Neovim + LazyVim)

## Goal

Install Neovim and the entire LazyVim configuration verbatim from the Linux dotfiles. LazyVim is fully cross-platform; no porting needed.

## Source of truth

Linux config: `nvim/.config/nvim/` in https://github.com/dangoodface/dotfiles. The same tree goes at `$env:LOCALAPPDATA\nvim\` on Windows (Neovim's standard config path on Windows).

A copy of the config is also in `reference-configs/nvim/` in this repo, kept in sync with the Linux version.

## Constraints

- Config destination: `%LOCALAPPDATA%\nvim\` (NOT `~/.config/nvim/` — that path doesn't apply on Windows even though Neovim prints it as the "default" in some docs).
- Shared data goes at `%LOCALAPPDATA%\nvim-data\` automatically — don't override.
- Idempotent. If `init.lua` already exists, diff before overwriting; surface to Daniel if there are local edits.

## Verification

```pwsh
nvim --version                            # >= 0.10
Test-Path "$env:LOCALAPPDATA\nvim\init.lua"
nvim --headless "+Lazy! sync" "+qa"       # should complete without errors
```

Then open `nvim` interactively and confirm the LazyVim dashboard appears, no error popups, all plugins listed in `:Lazy` show "loaded."

## Implementation hints

- Install Neovim: `winget install --id Neovim.Neovim`. This typically gets you the latest stable release; check with `nvim --version` that it's >= 0.10 (LazyVim's minimum).
- Copy the entire `reference-configs/nvim/` directory to `$env:LOCALAPPDATA\nvim\`. Preserve directory structure exactly.
- After copying, run `nvim --headless "+Lazy! sync" "+qa"` to install all plugins. This may take 1-3 minutes the first time. Surface progress to Daniel if it stalls.
- LazyVim auto-detects language LSPs via Mason. On Windows, Mason needs git, curl, and the language toolchains in PATH. Brief 04 (mise) handles node/python/rust; brief 07 handles git. If Mason installs fail for specific LSPs, surface — likely a missing toolchain.

## Gotchas

- **Treesitter compilation.** LazyVim uses nvim-treesitter, which compiles parsers using a C compiler. On Windows this requires either MSVC Build Tools or zig. If treesitter installs fail, surface to Daniel — the fix is usually `winget install --id zig.zig` or the same Build Tools install needed for Rust in brief 04.
- **Path separators in Lua.** The LazyVim config uses forward slashes throughout, which Neovim normalizes correctly on Windows. Don't "fix" this to backslashes.
- **Clipboard integration.** Neovim on Windows uses `win32yank.exe` or PowerShell-based clipboard by default. If `+y` / `+p` (system clipboard yank/paste) doesn't work, install `win32yank`: `winget install --id equalsraf.win32yank` or `scoop install win32yank`.
- **Existing `nvim` config.** If the user already has a `%LOCALAPPDATA%\nvim\` directory with non-trivial content, do NOT overwrite. Surface to Daniel and ask whether to back up + replace, merge, or skip this brief.
