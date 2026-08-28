-- ~/.config/wezterm/wezterm.lua
-- Native-Windows replica of Daniel's Linux ghostty + zellij setup.
-- See dotfiles-windows/TERMINAL_RESEARCH.md for the rationale.

local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- ─── Font (JetBrainsMono Nerd Font v3.4.0 — already installed) ─────────
config.font = wezterm.font('JetBrainsMono Nerd Font', { weight = 'Regular' })
config.font_size = 11.0
config.harfbuzz_features = { 'calt=1', 'clig=1', 'liga=1' }  -- programming ligatures
config.line_height = 1.0
config.cell_width = 1.0

-- ─── Theme: Catppuccin Mocha (matches Fedora setup) ─────────────────────
config.color_scheme = 'Catppuccin Mocha'

-- ─── Shell: PowerShell 7 as the default profile ─────────────────────────
-- NOTE: bare 'pwsh.exe' does NOT work when PowerShell 7 comes from the
-- Microsoft Store. The thing on PATH (%LOCALAPPDATA%\Microsoft\WindowsApps\
-- pwsh.exe) is a 0-byte "app execution alias" reparse stub; WezTerm spawns
-- processes directly and cannot execute it, so it silently falls back to
-- Windows PowerShell 5.1. Resolve the real binary instead.
-- Resolve the real pwsh binary. Ordered fastest-first: every branch except
-- the last is a plain file probe (~0ms). Only branch 4 spawns a process, and
-- only after a PowerShell upgrade moves the Store path out from under us.
local KNOWN_PWSH =
  'C:/Program Files/WindowsApps/Microsoft.PowerShell_7.6.5.0_x64__8wekyb3d8bbwe/pwsh.exe'
local PWSH_CACHE = wezterm.home_dir .. '/.config/wezterm/.pwsh-path'

local function readable(path)
  if not path or path == '' then return nil end
  local h = io.open(path, 'r')
  if h then h:close() return path end
  return nil
end

local function find_pwsh()
  -- 1. Stable MSI/winget install. Zero cost and immune to Store versioning.
  --    To get here permanently:
  --      winget install --id Microsoft.PowerShell --source winget
  local msi = readable('C:/Program Files/PowerShell/7/pwsh.exe')
  if msi then return msi end

  -- 2. Last known-good Store path, probed directly.
  local known = readable(KNOWN_PWSH)
  if known then return known end

  -- 3. Path discovered by a previous branch-4 run, after an upgrade.
  local cache = io.open(PWSH_CACHE, 'r')
  if cache then
    local cached = cache:read('*l')
    cache:close()
    local hit = readable(cached)
    if hit then return hit end
  end

  -- 4. Discover. NOTE: do NOT use wezterm.glob for this. The ACL on
  --    'C:\Program Files\WindowsApps' denies directory ENUMERATION to normal
  --    processes, so the glob silently returns zero hits even though the
  --    versioned path underneath is readable and executable. That silent
  --    zero-hit is what made this fall through to a stale hardcoded version
  --    and exit with code 1 on launch. Costs ~2s, so it is last and cached.
  local ok, success, stdout = pcall(wezterm.run_child_process, {
    'powershell.exe', '-NoProfile', '-NonInteractive', '-Command',
    '(Get-AppxPackage Microsoft.PowerShell).InstallLocation',
  })
  if ok and success and stdout then
    for line in stdout:gmatch('[^\r\n]+') do
      local dir = line:gsub('^%s+', ''):gsub('%s+$', '')
      if dir ~= '' then
        local exe = readable(dir .. '/pwsh.exe')
        if exe then
          local w = io.open(PWSH_CACHE, 'w')
          if w then w:write(exe) w:close() end
          return exe
        end
      end
    end
  end

  -- 5. Last resort. Deliberately NOT 'powershell.exe': falling back to 5.1 is
  --    what silently hid this bug before (5.1 reads a different profile, so
  --    none of the add-ons load). Refresh KNOWN_PWSH above with:
  --      (Get-AppxPackage Microsoft.PowerShell).InstallLocation
  return KNOWN_PWSH
end
config.default_prog = { find_pwsh(), '-NoLogo' }

-- ─── Window appearance ──────────────────────────────────────────────────
-- INTEGRATED_BUTTONS puts minimize/maximize/close into the tab bar (modern
-- look, like Windows Terminal). Alternatives:
--   'TITLE | RESIZE'  → classic Windows title bar with separate buttons
--   'RESIZE'          → no title bar, no buttons (use Alt+q to quit)
--   'NONE'            → no chrome at all
config.window_decorations = 'INTEGRATED_BUTTONS | RESIZE'
config.integrated_title_button_style = 'Windows'           -- match Win11 style
config.window_background_opacity = 1.0                     -- bump down (e.g. 0.95) for translucency
config.window_padding = { left = 8, right = 8, top = 6, bottom = 6 }
config.enable_tab_bar = true
config.use_fancy_tab_bar = false                           -- compact tab bar
config.tab_bar_at_bottom = false
config.show_new_tab_button_in_tab_bar = true               -- + button next to tabs
config.hide_tab_bar_if_only_one_tab = false                -- always show so window buttons stay visible

-- ─── Cursor + scrollback ────────────────────────────────────────────────
config.default_cursor_style = 'BlinkingBar'
config.cursor_blink_rate = 500
config.scrollback_lines = 10000

-- ─── Alt as a pure modifier on Windows ─────────────────────────────────
-- Without this, Alt+letter gets composed (dead keys on Spanish layouts) and
-- never reaches the keybind handler. Right Alt = AltGr (composition for @, €,
-- ~) is left intact so Spanish keyboard accents still work.
config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = true
config.use_dead_keys = true

-- ─── Keybindings (zellij-style, with a modal resize mode) ───────────────
-- Window:    Alt+q (quit), F11 (fullscreen)
-- Tabs:      Alt+n (new), Alt+x (close), Alt+1..9 (jump)
-- Panes:     Alt+d (h-split), Alt+r (v-split), Alt+w (close)
-- Navigate:  Alt+h/j/k/l (vim-style pane move)
-- Resize:    Alt+Shift+R then h/j/k/l (repeat), Escape to exit
-- Workspace: Alt+s (picker)
-- Copy:      Alt+[ (scrollback search)
config.keys = {
  -- Window
  { key = 'q',      mods = 'ALT',       action = wezterm.action.QuitApplication },
  { key = 'F11',    mods = 'NONE',      action = wezterm.action.ToggleFullScreen },

  -- Tabs
  { key = 'n', mods = 'ALT',       action = wezterm.action.SpawnTab 'CurrentPaneDomain' },
  { key = 'x', mods = 'ALT',       action = wezterm.action.CloseCurrentTab { confirm = true } },

  -- Panes: splits
  { key = 'd', mods = 'ALT',       action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = 'r', mods = 'ALT',       action = wezterm.action.SplitVertical   { domain = 'CurrentPaneDomain' } },
  { key = 'w', mods = 'ALT',       action = wezterm.action.CloseCurrentPane { confirm = true } },

  -- Panes: vim-style navigation
  { key = 'h', mods = 'ALT',       action = wezterm.action.ActivatePaneDirection 'Left'  },
  { key = 'j', mods = 'ALT',       action = wezterm.action.ActivatePaneDirection 'Down'  },
  { key = 'k', mods = 'ALT',       action = wezterm.action.ActivatePaneDirection 'Up'    },
  { key = 'l', mods = 'ALT',       action = wezterm.action.ActivatePaneDirection 'Right' },

  -- Panes: enter modal resize mode (zellij-style: press once, then h/j/k/l
  -- to resize repeatedly, Escape to exit). Much friendlier than holding
  -- Alt+Shift while hitting arrows over and over.
  { key = 'R', mods = 'ALT|SHIFT', action = wezterm.action.ActivateKeyTable {
      name = 'resize_pane', one_shot = false, until_unknown = true,
  } },

  -- Workspaces (zellij sessions equivalent)
  { key = 's', mods = 'ALT',       action = wezterm.action.ShowLauncherArgs { flags = 'FUZZY|WORKSPACES' } },

  -- Copy mode (vim-like scrollback search)
  { key = '[', mods = 'ALT',       action = wezterm.action.ActivateCopyMode },

  -- Ctrl+Shift fallbacks (instinctive for users coming from Windows Terminal)
  { key = 'w', mods = 'CTRL|SHIFT', action = wezterm.action.CloseCurrentPane { confirm = true } },
  { key = 't', mods = 'CTRL|SHIFT', action = wezterm.action.SpawnTab 'CurrentPaneDomain' },
  { key = 'c', mods = 'CTRL|SHIFT', action = wezterm.action.CopyTo 'Clipboard' },
  { key = 'v', mods = 'CTRL|SHIFT', action = wezterm.action.PasteFrom 'Clipboard' },
}

-- Alt+1..9 jump to tab N
for i = 1, 9 do
  table.insert(config.keys, {
    key = tostring(i),
    mods = 'ALT',
    action = wezterm.action.ActivateTab(i - 1),
  })
end

-- ─── Resize mode key table ──────────────────────────────────────────────
-- Triggered by Alt+Shift+R. While active: h/j/k/l resize, +/- adjust by 1,
-- Escape or Enter exits. Status line in tab bar shows you're in this mode.
config.key_tables = {
  resize_pane = {
    { key = 'h',      action = wezterm.action.AdjustPaneSize { 'Left',  5 } },
    { key = 'j',      action = wezterm.action.AdjustPaneSize { 'Down',  5 } },
    { key = 'k',      action = wezterm.action.AdjustPaneSize { 'Up',    5 } },
    { key = 'l',      action = wezterm.action.AdjustPaneSize { 'Right', 5 } },
    { key = 'LeftArrow',  action = wezterm.action.AdjustPaneSize { 'Left',  5 } },
    { key = 'DownArrow',  action = wezterm.action.AdjustPaneSize { 'Down',  5 } },
    { key = 'UpArrow',    action = wezterm.action.AdjustPaneSize { 'Up',    5 } },
    { key = 'RightArrow', action = wezterm.action.AdjustPaneSize { 'Right', 5 } },
    { key = 'Escape', action = 'PopKeyTable' },
    { key = 'Enter',  action = 'PopKeyTable' },
  },
}

-- ─── Misc ───────────────────────────────────────────────────────────────
config.adjust_window_size_when_changing_font_size = false
config.audible_bell = 'Disabled'
config.check_for_updates = false                           -- winget handles updates

return config
