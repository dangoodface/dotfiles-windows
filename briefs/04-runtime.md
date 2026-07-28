# Brief 04 — Runtime version manager (mise)

## Goal

Install mise and pin the global runtime versions: **node@lts**, **python@3.13**.
**`rust` is deliberately NOT pinned on Windows** — see below.

## As-built (source machine, 2026-07-28)

`%USERPROFILE%\.config\mise\config.toml`, mirrored to `reference-configs/mise-config.toml`:

```toml
[tools]
node = "lts"
python = "3.13"
```

Resolved by `mise ls`:

| Tool | Version | Notes |
|---|---|---|
| node | 24.15.0 | `lts`; also hosts the Claude Code npm install — see brief 08 |
| python | 3.13.13 | |
| rust | *absent* | `rustc` does not resolve |

**Why rust was dropped:** Rust on Windows links via MSVC, requiring Visual Studio
Build Tools 2022 (~6 GB), which is not installed here and was not worth the download
for the actual workload. `rustc`, `go` and `php` all report MISSING and that is
expected — starship's `[rust]`, `[golang]`, `[php]` modules only render when the
runtime is present, so the prompt just omits those segments.

To restore rust parity on a new machine: install Build Tools 2022 with the C++
workload **first**, then `mise use --global rust@stable`. Pinning rust without the
Build Tools gives you a `rustc` that fails at the linker on nearly every build.

## Source of truth

Linux config: `mise/.config/mise/config.toml` in https://github.com/dangoodface/dotfiles,
which pins node, python **and rust**. The Windows install intentionally diverges on rust.

```toml
[tools]
node = "lts"
python = "3.13"
rust = "stable"    # Linux only — omitted on Windows
```

## Constraints

- mise must be activated in the PowerShell profile (handled by brief 02). This brief just installs and configures.
- mise's Windows config path is `%USERPROFILE%\AppData\Local\mise\config\config.toml` OR `%USERPROFILE%\.config\mise\config.toml` (mise checks both). Prefer the second to match the Linux convention.
- Rust on Windows requires the MSVC build tools. mise will surface this requirement; the implementing Claude should verify the user has Visual Studio Build Tools 2022+ installed before pinning rust. If not, surface to Daniel.

## Verification

```pwsh
mise --version                    # as-built 2026.5.6
mise ls                           # node + python only; rust absent by design
node --version                    # v24.15.0
python --version                  # 3.13.13
# rustc --version                 # expected MISSING on Windows — see above
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
