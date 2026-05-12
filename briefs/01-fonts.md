# Brief 01 — Fonts

## Goal

Install **JetBrainsMono Nerd Font v3.4.0** so that any terminal emulator and editor on the machine can render programming ligatures and Nerd Font glyphs (which the starship prompt uses heavily).

## Constraints

- Pin to **v3.4.0** to match what's installed on Daniel's Linux machine. If the implementing Claude deems a newer version required, surface to Daniel before changing the pin.
- Per-user install (`%LOCALAPPDATA%\Microsoft\Windows\Fonts\`), not system-wide. No admin needed.
- Idempotent.

## Source

The font is published as a release asset on the Nerd Fonts GitHub repo:
`https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip`

## Verification

After install:

```pwsh
# Should list at least 30+ TTF files
Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Windows\Fonts\JetBrainsMono*" -Filter *.ttf
```

Open any application that lets you pick a font (Notepad, Windows Terminal settings) and confirm "JetBrainsMono Nerd Font" appears in the list.

## Implementation hints

- Three viable approaches (the implementing Claude picks based on what's available on the target):
  1. **winget** — `winget install --id DEVCOM.JetBrainsMonoNerdFont` if the font is in the registry. Simplest if available.
  2. **scoop** — `scoop bucket add nerd-fonts; scoop install JetBrainsMono-NF` (requires scoop).
  3. **Direct download** — mirror the bash installer. Download the v3.4.0 zip, extract `.ttf` files to `%LOCALAPPDATA%\Microsoft\Windows\Fonts\JetBrainsMono\`, and register each font in the registry under `HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts` with value `<basename>.ttf` pointing to the absolute path.
- For approach 3, **registry registration is required** — Windows does NOT auto-discover fonts in `%LOCALAPPDATA%\Microsoft\Windows\Fonts\` the way Linux does with `fc-cache`. Forgetting this is the #1 silent-failure mode.
- After installation, no terminal restart is needed for new sessions, but already-open terminal sessions must be closed and reopened to pick up the new font.

## Gotchas

- Don't install to `C:\Windows\Fonts\` unless the user is admin and explicitly wants system-wide. Per-user is the safe default.
- Some terminals (notably very old Windows Terminal versions) don't render certain Nerd Font glyphs even when the font is correctly installed — this is a terminal-rendering bug, not a font install bug. If verification fails despite correct install, ask Daniel which terminal he's using before debugging further.
