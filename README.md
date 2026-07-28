# dotfiles-windows

A specification repo for replicating Daniel Buenrostro's Linux dev environment on **native Windows** (no WSL, no Cygwin, no Linux emulator).

The repo is itself the instruction set — another Claude Code session reads the briefs in `briefs/`, uses the configs in `reference-configs/`, and implements the setup on a target Windows machine. Briefs are goal-and-constraint, not step-by-step — the implementing Claude is expected to make judgment calls (e.g., choose between equivalent tools, handle Windows version differences) and verify the result.

## Who this is for

A future Claude Code session running on a fresh Windows machine, tasked with bootstrapping the same dev environment Daniel has on Fedora 43. The implementing session should:

1. Read `TARGET.md` for the high-level goal and design constraints.
2. Read `BOOTSTRAP_LOG.md` for the as-built state of the source machine — versions,
   decisions taken, and any known breakage. Do not re-derive it.
3. Read `briefs/` in numerical order — each is a single-component goal with constraints, gotchas, and verification.
4. Use `reference-configs/` for the live configs. Most copy verbatim; the ones with
   machine-specific paths have an explicit PORTING table in their brief.
5. Cross-reference Daniel's existing Linux dotfiles repo (https://github.com/dangoodface/dotfiles) when in doubt about intent.
6. Verify with the checklist in `briefs/99-verify.md` before declaring done.

**If the goal is only "give me my terminal on this new machine,"** the short path is
briefs 00 → 01 (fonts) → 02 (shell) → 03 (prompt) → 05 (CLI tools) → 10 (terminal).
Brief 10 is the one that matters and it names the four values to change.

## Repo structure

```
dotfiles-windows/
├── README.md                    # this file
├── TARGET.md                    # what we're building, in plain language
├── TERMINAL_RESEARCH.md         # why WezTerm + Zellij (May 2026 option survey)
├── BOOTSTRAP_LOG.md             # as-built audit + known breakage
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
│   ├── 10-terminal.md           # WezTerm + Zellij — plug-and-play reproduction
│   ├── 11-analyst-harness.md    # ~/.claude customisation layer (shape only)
│   └── 99-verify.md
└── reference-configs/           # live configs, copied verbatim from the machine
    ├── starship.toml
    ├── mise-config.toml
    ├── nvim/                    # entire LazyVim config
    ├── wezterm/wezterm.lua      # terminal emulator
    ├── zellij/config.kdl        # multiplexer
    ├── claude-settings.json
    └── pwsh-dotfiles-fragment.ps1
```

`reference-configs/` holds **the live files as they run on the source machine**, not
idealised templates. Where a file contains a machine-specific absolute path, the
relevant brief lists exactly which lines to change — see the PORTING table in
`briefs/10-terminal.md`.

## What this repo deliberately does NOT contain

- **An "install everything" mega-script.** Briefs are deliberately separable so the implementing Claude can skip components, swap equivalents, or stop and ask Daniel mid-bootstrap.
- **WSL or any Linux emulation layer.** Windows-native only. If a tool genuinely cannot be installed natively, the brief says so and offers a Windows-native alternative.
- **Secrets material or per-machine state.** Same exclusion list as the Linux dotfiles: GPG keys, password store, OAuth tokens, machine-local git identity. See `briefs/09-secrets.md` — the backend is now decided (Bitwarden CLI).
- **The `~/.claude` customisation content** — skills, agents, commands, output styles and the global `CLAUDE.md`. These are written for a specific employer's workflow and reference internal conventions, so they stay out of a public repo. `briefs/11-analyst-harness.md` documents their shape and dependencies; `reference-configs/claude-settings.json` (the wiring) *is* committed.
- **A Windows Terminal config.** Not because terminal config is out of scope — see
  below — but because Windows Terminal is stock on the source machine and unused.

## Correction to the original scope (2026-07-28)

The first version of this repo stated that a terminal emulator config was
"deliberately not in scope," on the reasoning that Daniel works on files and the
terminal is just a means. **That is no longer true.** The machine now runs a
deliberately configured **WezTerm + Zellij** stack — 157 lines of Lua and a Zellij
KDL config, both load-bearing (Spanish-keyboard Alt handling, PowerShell 7
resolution, zellij-style keybindings). Both are now committed and documented in
`briefs/10-terminal.md`, which is the brief to read if the goal is to stand up the
same terminal on another Windows machine.

## Source of truth

The Linux dotfiles at https://github.com/dangoodface/dotfiles are the design reference. When this repo and the Linux repo disagree, the Linux repo is intent — this repo is the Windows translation. Configs that are platform-agnostic (starship, nvim) should be kept identical; the diff between the two repos should be the OS-coupled layer only.
