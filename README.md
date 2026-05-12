# dotfiles-windows

A specification repo for replicating Daniel Buenrostro's Linux dev environment on **native Windows** (no WSL, no Cygwin, no Linux emulator).

The repo is itself the instruction set — another Claude Code session reads the briefs in `briefs/`, uses the configs in `reference-configs/`, and implements the setup on a target Windows machine. Briefs are goal-and-constraint, not step-by-step — the implementing Claude is expected to make judgment calls (e.g., choose between equivalent tools, handle Windows version differences) and verify the result.

## Who this is for

A future Claude Code session running on a fresh Windows machine, tasked with bootstrapping the same dev environment Daniel has on Fedora 43. The implementing session should:

1. Read `TARGET.md` for the high-level goal and design constraints.
2. Read `briefs/` in numerical order — each is a single-component goal with constraints, gotchas, and verification.
3. Use `reference-configs/` for verbatim cross-platform configs (no porting needed).
4. Cross-reference Daniel's existing Linux dotfiles repo (https://github.com/dangoodface/dotfiles) when in doubt about intent.
5. Verify with the checklist in `briefs/99-verify.md` before declaring done.

## Repo structure

```
dotfiles-windows/
├── README.md                    # this file
├── TARGET.md                    # what we're building, in plain language
├── briefs/                      # implementation briefs, ordered
│   ├── 00-prerequisites.md
│   ├── 01-fonts.md
│   ├── 02-shell.md
│   ├── 03-prompt.md
│   ├── 04-runtime.md
│   ├── 05-cli-tools.md
│   ├── 06-editor.md
│   ├── 07-git-gh.md
│   ├── 08-claude-code.md
│   ├── 09-secrets.md
│   └── 99-verify.md
└── reference-configs/           # cross-platform configs, copy verbatim
    ├── starship.toml
    ├── nvim/                    # entire LazyVim config
    ├── claude-settings.json
    └── pwsh-profile-skeleton.ps1
```

## What this repo deliberately does NOT contain

- **A terminal emulator config.** Daniel works primarily on files (editors, file managers); a heavy terminal-GUI customization isn't in scope. Whatever terminal the user prefers (Windows Terminal, WezTerm, ghostty preview) should pick up the font + starship prompt automatically once those are installed.
- **An "install everything" mega-script.** Briefs are deliberately separable so the implementing Claude can skip components, swap equivalents, or stop and ask Daniel mid-bootstrap.
- **WSL or any Linux emulation layer.** Windows-native only. If a tool genuinely cannot be installed natively, the brief says so and offers a Windows-native alternative.
- **Secrets material or per-machine state.** Same exclusion list as the Linux dotfiles: GPG keys, password store, OAuth tokens, machine-local git identity. See `briefs/09-secrets.md` for the Windows-native secret strategy.

## Source of truth

The Linux dotfiles at https://github.com/dangoodface/dotfiles are the design reference. When this repo and the Linux repo disagree, the Linux repo is intent — this repo is the Windows translation. Configs that are platform-agnostic (starship, nvim) should be kept identical; the diff between the two repos should be the OS-coupled layer only.
