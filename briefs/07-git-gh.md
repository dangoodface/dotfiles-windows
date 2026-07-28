# Brief 07 — Git and GitHub CLI

## Goal

Install Git and GitHub CLI, configure global git identity, and authenticate `gh` for the user's GitHub account.

## As-built `~/.gitconfig` (source machine, 2026-07-28)

The choices brief 07 originally said to "surface" have been made. Reproduce these:

```ini
[core]
	editor = "C:\\Users\\51372\\AppData\\Local\\Programs\\Microsoft VS Code\\bin\\code" --wait
	autocrlf = input
[user]
	name = Daniel Buenrostro
	email = buenrostrozd@outlook.com
[init]
	defaultBranch = main
[credential "https://github.com"]
	helper =
	helper = !'C:\\Program Files\\GitHub CLI\\gh.exe' auth git-credential
[credential "https://gist.github.com"]
	helper =
	helper = !'C:\\Program Files\\GitHub CLI\\gh.exe' auth git-credential
```

Resolved decisions:

| Question the brief raised | Decision taken |
|---|---|
| Editor | **VS Code** (`code --wait`), not Vim. Note this is a per-machine absolute path and needs rewriting on a new machine. |
| `core.autocrlf` | **`input`** — CRLF→LF on commit, leave LF alone on checkout. Correct for cross-platform repos shared with the Linux dotfiles. |
| Credential helper | `gh auth setup-git` was run; the empty `helper =` line first resets any inherited helper, then delegates to `gh`. Both github.com and gist.github.com. |
| GPG commit signing | **Not configured.** gpg4win is not installed — see brief 09, the `pass`→Bitwarden migration is still outstanding. |

Versions as-built: git **2.53.0.2** (2.55.0.3 available), gh **2.92.0** (2.96.0
available). Both machine-scope installs under `C:\Program Files\`.

## Constraints

- Per-machine state. The git identity (`user.name`, `user.email`) and `gh` auth are NOT in any dotfiles repo (deliberately — see Linux dotfiles README "Per-machine setup"). They must be set on each new machine.
- The VS Code editor path above is username-coupled. On a new machine either rewrite it
  or set `core.editor` to something path-independent (`nvim` is already installed).
- Don't commit credentials anywhere.
- Use HTTPS + GitHub-CLI-managed credentials (NOT stored plaintext PAT).

## Verification

```pwsh
git --version                                     # >= 2.40
gh --version                                      # >= 2.40
git config --global user.name                     # "Daniel Buenrostro"
git config --global user.email                    # "buenrostrozd@outlook.com"
gh auth status                                    # logged in to github.com as dangoodface
```

## Implementation hints

- Install: `winget install --id Git.Git --scope user` and `winget install --id GitHub.cli --scope user`.
- The Linux dotfiles README documents the global git config exactly:
  ```pwsh
  git config --global user.name  "Daniel Buenrostro"
  git config --global user.email "buenrostrozd@outlook.com"
  git config --global init.defaultBranch main
  ```
- For `gh` auth, run `gh auth login` interactively. The implementing Claude should NOT attempt to automate this — it requires browser interaction or device-code flow that's brittle to script. Surface the command to Daniel and let him complete it.
- Once `gh auth` is set, configure git to use it as the credential helper: `gh auth setup-git`. This avoids prompting for credentials on every push.

## Gotchas

- **Git for Windows installer options.** The `Git.Git` winget package runs the standard Git for Windows installer with default options. Defaults are sensible (Vim as editor, OpenSSH, MinTTY off if not requested). If the implementing Claude wants to override (e.g., "use VS Code as editor"), surface the trade-off to Daniel rather than silently changing defaults.
- **Line endings (autocrlf).** Git for Windows defaults to `core.autocrlf=true`, which mangles line endings on cross-platform repos. Daniel's Linux dotfiles use Unix line endings throughout. Recommend `git config --global core.autocrlf input` (convert CRLF→LF on commit, leave LF alone on checkout) or `false` if all repos are Unix-only. Surface the choice.
- **gh auth on a fresh machine** sometimes fails to bind to localhost for the OAuth callback. Falling back to device-code flow (`gh auth login --web` opens browser to a code-entry page) is the workaround.
- **GPG signing.** Daniel's Linux setup uses GPG (for `pass` — see brief 09). Git commit signing via GPG on Windows requires `gpg4win`; defer to brief 09 to install GPG before configuring `commit.gpgSign`.
