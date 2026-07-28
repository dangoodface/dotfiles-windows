# Brief 01 — Fonts

## Goal

Install **JetBrainsMono Nerd Font** so the terminal (WezTerm, brief 10) and editor
render programming ligatures and the Nerd Font glyphs the starship prompt uses
heavily.

## Verified installed state (source machine, 2026-07-28)

This is what a working install actually looks like. Reproduce *this*, not an
approximation.

| Property | Value |
|---|---|
| Install scope | **Per-user** — `%LOCALAPPDATA%\Microsoft\Windows\Fonts\` |
| File count | **32 `.ttf` files** |
| Variants present | `JetBrainsMonoNerdFont-*.ttf` (16) + `JetBrainsMonoNLNerdFont-*.ttf` (16) |
| Styles per variant | Thin, ExtraLight, Light, Regular, Medium, SemiBold, Bold, ExtraBold — each with an Italic |
| Registry registration | `HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts`, entries named `JetBrainsMonoNerdFont <Style> (TrueType)` |
| GDI / font-picker family name | **`JetBrainsMono NF`** and `JetBrainsMonoNL NF` |
| Name WezTerm requests | `JetBrainsMono Nerd Font` — resolves via DirectWrite full-name matching |
| Machine-wide install | **None.** `C:\Windows\Fonts` has no JetBrains/Nerd files. |

**Only these two variants are installed.** The upstream `JetBrainsMono.zip`
release asset contains far more (`*NerdFontMono-*`, `*NerdFontPropo-*`), which are
*not* installed and *not* wanted:

- `JetBrainsMonoNerdFont-*` — the default variant. Ligatures on, glyphs at
  natural width. **This is the one the configs target.**
- `JetBrainsMonoNLNerdFont-*` — "NL" = No Ligatures. Installed as a companion so a
  no-ligature family is selectable without a second install. Nothing references it.
- `*NerdFontMono-*` — glyphs force-fitted to single cell width. Skip.
- `*NerdFontPropo-*` — proportional. Skip; breaks terminal alignment.

## The two silent-failure modes

Both produce the same symptom (`?` boxes / tofu in the prompt) from different causes:

1. **Registry registration missing.** Windows does *not* auto-discover fonts
   dropped into `%LOCALAPPDATA%\Microsoft\Windows\Fonts\` the way Linux does with
   `fc-cache`. Each file must have an `HKCU` Fonts entry pointing at its absolute
   path. This is the #1 cause of "I installed the font and it didn't work."
2. **Wrong variant installed.** Installing only `*NerdFontMono-*` and then asking
   for `JetBrainsMono Nerd Font` gives a fallback font, because the requested full
   name does not exist. Glyphs break even though "a JetBrains Nerd Font" is
   installed.

## Install

**Note: `scoop` is NOT installed on the source machine** (`Get-Command scoop` →
not found), so approach 2 below is untested here. The 32-file layout above is
consistent with a direct download + selective extraction.

1. **winget** — `winget install --id DEVCOM.JetBrainsMonoNerdFont`. Simplest if
   present in the registry. Installs machine-wide (needs admin) and pulls all
   variants, which is more than needed but harmless.
2. **scoop** — `scoop bucket add nerd-fonts; scoop install JetBrainsMono-NF`.
   Per-user, handles registry registration. Requires installing scoop first,
   which brief 00 defers.
3. **Direct download** (matches the source machine's layout):
   - Fetch `https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip`
   - Extract **only** `JetBrainsMonoNerdFont-*.ttf` and `JetBrainsMonoNLNerdFont-*.ttf`
     to `%LOCALAPPDATA%\Microsoft\Windows\Fonts\`
   - Register each in `HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts`
     as `JetBrainsMonoNerdFont <Style> (TrueType)` → absolute path
   - Version pin: **v3.4.0**, matching Daniel's Linux machine. If a newer version
     is needed, surface before changing the pin.

## Verification

```pwsh
# 1. File count and variants — expect 32, split 16/16
$uf = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
(Get-ChildItem $uf | Where-Object Name -match 'JetBrains').Count          # 32
Get-ChildItem $uf | Where-Object Name -match 'JetBrains' | Select Name

# 2. Registry registration present (the step everyone forgets)
(Get-ItemProperty 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts').PSObject.Properties |
  Where-Object Name -match 'JetBrains' | Select-Object Name

# 3. Family visible to the OS — expect 'JetBrainsMono NF'
Add-Type -AssemblyName System.Drawing
(New-Object System.Drawing.Text.InstalledFontCollection).Families.Name |
  Where-Object { $_ -match 'JetBrains' }

# 4. THE ONE THAT MATTERS — does the terminal resolve it to a real file?
wezterm ls-fonts --text "ab"
#   must print: ...\FONTS\JETBRAINSMONONERDFONT-REGULAR.TTF, DirectWrite

# 5. Nerd glyphs resolve from that same file (not a fallback font)
wezterm ls-fonts --text "$([char]0xF07C)$([char]0xE7A8)"
#   expect glyph=fa-folder_open and glyph=dev-rust
```

Check 4 is the real gate. Checks 1–3 can all pass while the terminal still falls
back to a different font.

## Gotchas

- **Don't rename the font in the configs.** The Windows font picker shows
  `JetBrainsMono NF`; WezTerm's config asks for `JetBrainsMono Nerd Font`. Both are
  correct — DirectWrite matches on the TTF's full/PostScript name, not the GDI
  family name. Changing the config to `JetBrainsMono NF` would make it
  Windows-only and break parity with the Linux dotfiles.
- **Per-user installs are invisible to elevated processes.** A tool running as
  Administrator or as another user will not see fonts in
  `%LOCALAPPDATA%\Microsoft\Windows\Fonts`. If an elevated terminal shows tofu
  while the normal one is fine, that is this, not a broken install.
- **Already-open terminals must be restarted** to pick up a newly installed font.
  New sessions are fine.
- **Don't install to `C:\Windows\Fonts`** unless machine-wide is explicitly wanted
  — it needs admin. Per-user is the default here and matches the source machine.
