# Brief 09 — Secrets management

## Goal

Provide a Windows-native equivalent to Daniel's Linux `pass` + `gpg` setup: a way to store secrets locally, retrieve them in the shell without leaking to history, and integrate with `gh` and `git` signing.

## What this replaces

On Linux Daniel uses:
- **`pass`** — Unix password manager, stores secrets as GPG-encrypted files in `~/.password-store/` (a private GitHub repo).
- **`gpg`** — GnuPG keypair stored at `~/.gnupg/`.
- **`secret()` zsh function** — `secret BRAVE_API_KEY api/brave-search` injects a secret into an env var without putting the secret name in shell history.

## Constraints

- **No emulation.** Pure Windows-native or Windows-port.
- The chosen backend must support: storing arbitrary string secrets, retrieving by name in a script, and ideally syncing across machines.
- Daniel's `~/.password-store` repo on GitHub is the source of truth for existing secrets. Whatever backend gets chosen must either (a) ingest from the existing repo, (b) coexist with a port of `pass`, or (c) trigger a one-time secret migration with Daniel's involvement.

## Decision required from Daniel

The implementing Claude should NOT silently choose. Surface these three options:

| Option | Backend | Trade-off |
|---|---|---|
| **A** | Port `pass` + GPG via `gpg4win` | Highest fidelity, reuses existing `~/.password-store` repo verbatim. `pass` for Windows is via `gopass` (a Go-based pass-compatible CLI) — works but is a third-party port. |
| **B** | **Bitwarden CLI** (`bw`) + Bitwarden vault | Cross-platform, mature, well-supported on Windows. Requires migrating secrets from `pass` to Bitwarden once. |
| **C** | **Windows Credential Manager** + `Microsoft.PowerShell.SecretManagement` module | Native to Windows, no external service. PowerShell-first. Requires migrating secrets and using PowerShell-only retrieval (less portable to other shells later). |

Recommendation if Daniel doesn't have a strong preference: **B (Bitwarden CLI)**. Reasoning: cross-platform parity if Daniel ever uses a Mac, mature Windows binary, doesn't depend on the GPG ecosystem (which is fragile on Windows), and the CLI is well-documented for scripting.

## Implementation hints (per option)

### Option A — gopass + gpg4win

- Install: `winget install --id GnuPG.Gpg4win`, `winget install --id gopass.gopass`.
- Import GPG private key: same flow as Linux README — export from old machine, transfer securely, `gpg --import key.asc`, edit-key trust.
- Clone password-store: `git clone https://github.com/dangoodface/password-store $env:USERPROFILE\.password-store`.
- Initialize gopass to point at it: `gopass init` and select the existing repo.
- PowerShell `secret` function port:
  ```pwsh
  function secret { param($name, $path) Set-Item "env:$name" (gopass show -o $path) }
  ```

### Option B — Bitwarden CLI

- Install: `winget install --id Bitwarden.CLI`.
- `bw login` (interactive — surface to Daniel).
- `bw unlock` returns a session token; export to `$env:BW_SESSION`.
- PowerShell `secret` function port:
  ```pwsh
  function secret { param($name, $bwName) Set-Item "env:$name" (bw get password $bwName --raw) }
  ```
- Migration: write a one-shot PowerShell script that walks `~/.password-store` (cloned via gpg first), decrypts each entry with gpg, and creates a Bitwarden item via `bw create item`. Surface the migration script to Daniel before running.

### Option C — Windows Credential Manager + SecretManagement

- Install: `Install-Module Microsoft.PowerShell.SecretManagement -Scope CurrentUser`, `Install-Module Microsoft.PowerShell.SecretStore -Scope CurrentUser`.
- Register vault: `Register-SecretVault -Name MyVault -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault`.
- Set master password on first use.
- PowerShell `secret` function port:
  ```pwsh
  function secret { param($name, $vaultName) Set-Item "env:$name" (Get-Secret -Name $vaultName -AsPlainText) }
  ```
- Migration: same approach as Option B, but writing to SecretStore via `Set-Secret`.

## Verification

```pwsh
# Whichever option, verify by storing and retrieving a test secret without
# the secret value appearing in command history.
secret TEST_VAR test/sample
$env:TEST_VAR        # should print the test value
# Then check shell history does NOT contain the secret value:
Get-History | Select-String "test-secret-value-string"   # should return nothing
```

## Gotchas

- **GPG key transport.** Whichever option, the existing GPG private key must be transferred from the Linux machine via secure channel (USB, encrypted upload). Never via cloud sync or chat. The Linux README documents this; preserve the same discipline.
- **`gh auth` does not need to integrate with the secret store.** `gh` manages its own token via Windows Credential Manager automatically. Don't try to wire `gh` through `pass`/`bw` — it's already secure.
- **Migration is irreversible-ish.** Once secrets are in Bitwarden or SecretStore, the `~/.password-store` repo becomes a backup, not the source of truth. Surface this to Daniel and confirm before migrating.
