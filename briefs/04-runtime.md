# Brief 04 — Runtime version manager (mise)

## Goal

Install mise (formerly rtx) and pin the same global runtime versions Daniel uses on Linux: **node@lts**, **python@3.13**, **rust@stable**.

## Source of truth

Linux config: `mise/.config/mise/config.toml` in https://github.com/dangoodface/dotfiles. Identical content goes in the Windows install.

```toml
[tools]
node = "lts"
python = "3.13"
rust = "stable"
```

## Constraints

- mise must be activated in the PowerShell profile (handled by brief 02). This brief just installs and configures.
- mise's Windows config path is `%USERPROFILE%\AppData\Local\mise\config\config.toml` OR `%USERPROFILE%\.config\mise\config.toml` (mise checks both). Prefer the second to match the Linux convention.
- Rust on Windows requires the MSVC build tools. mise will surface this requirement; the implementing Claude should verify the user has Visual Studio Build Tools 2022+ installed before pinning rust. If not, surface to Daniel.

## Verification

```pwsh
mise --version                    # >= 2024.x
mise list                         # should show node, python, rust
node --version                    # should match LTS major version
python --version                  # should be 3.13.x
rustc --version                   # should be stable
```

## Implementation hints

- Install: `winget install --id jdx.mise` OR `scoop install mise`. Winget is preferred.
- Drop the config at `$env:USERPROFILE\.config\mise\config.toml`. Create directory if needed.
- After install, run `mise install` (or `mise install --yes`) to actually fetch the runtimes. This downloads several hundred MB; surface progress to Daniel if it takes more than a minute.
- The Linux dotfiles README documents pinning with `mise use --global node@lts python@3.13 rust@stable`. On Windows the equivalent works identically; alternatively the `config.toml` is sufficient on its own.

## Gotchas

- **Rust + MSVC dependency.** Rust on Windows compiles via MSVC by default. Without Visual Studio Build Tools 2022 (or full VS 2022 with C++ workload), `rustc` installs but most builds fail with linker errors. Surface this to Daniel — installing Build Tools is a separate ~6GB download.
- **Python on Windows path nuance.** mise-installed Python doesn't auto-add itself to `$env:PATH` for Microsoft Store; mise's activation handles this in-shell, but external apps won't see it. If Daniel uses a Windows IDE that needs to find Python independently, the IDE config has to point at mise's shim path.
- **Node on Windows + native modules.** Some npm packages with native compilation steps (node-gyp) require windows-build-tools. mise doesn't install these; surface only if a downstream brief (e.g., Claude Code installation) hits this.
