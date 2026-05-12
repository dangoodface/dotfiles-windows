# Brief 99 — Verification checklist

## Goal

End-to-end smoke test confirming the Windows machine matches Daniel's Linux dev environment in observable behavior. Run this *after* all other briefs complete.

## The "feels like Daniel's Linux box" test

Open a fresh PowerShell 7 session — NOT a session that had partial dotfiles loaded during bootstrap. Cleanly close all terminals first, then open one new one.

### Visual checks

- [ ] Prompt shows the segmented Tokyo Night starship bar (purple → blue gradient).
- [ ] All glyphs render (no `?` boxes, no missing icons in directory or git status segments).
- [ ] Directory icons render for `Documents/`, `Downloads/`, `Music/`, `Pictures/`.
- [ ] `cd` into a git repo: branch name + status flags appear in the prompt.
- [ ] `cd` into a Node project (one with package.json): Node version appears in the prompt.

### Tool resolution

```pwsh
foreach ($t in 'pwsh','starship','mise','node','python','rustc','git','gh','claude',
               'eza','bat','fzf','rg','fd','zoxide','lazygit','dust','nvim') {
  $c = Get-Command $t -ErrorAction SilentlyContinue
  '{0,-12} {1}' -f $t, $(if ($c) { 'OK ' + $c.Source } else { 'MISSING' })
}
```

All entries should report `OK <path>`. `dust` and `btop` are best-effort; one missing is acceptable, two or more should trigger investigation.

### Behavior checks

- [ ] Type a partial command from history → autosuggestion appears as ghost-text.
- [ ] Press Tab on a partial command → menu completion appears (not just first match).
- [ ] Press `Ctrl+R` → fzf history search opens.
- [ ] `ls`, `ll`, `la`, `tree` all run eza variants without error.
- [ ] `cat <somefile>` runs bat with syntax highlighting.
- [ ] `lg` opens lazygit if cwd is a git repo.
- [ ] `cd <partial-name>` works via zoxide once the dir has been visited at least once.
- [ ] `git init` in `$env:USERPROFILE` is refused with the safety message.
- [ ] `git init` in any subdirectory works normally.

### Editor checks

- [ ] `nvim` opens the LazyVim dashboard.
- [ ] `:Lazy` shows all plugins as "loaded," none failing.
- [ ] `:Mason` shows expected LSPs available.
- [ ] System clipboard yank/paste works (`"+y` / `"+p`).
- [ ] Treesitter highlighting active in a sample file (open a `.lua` or `.ts` file).

### Claude Code checks

- [ ] `claude --version` reports a version.
- [ ] `claude` opens an interactive session with the expected theme (dark) and model (`claude-opus-4-7`).
- [ ] Running a benign Bash-allowlisted command (`ls` equivalent) does NOT prompt for permission.
- [ ] MCP servers (if Daniel uses them on Linux) respond — `claude mcp list` shows them as connected.

### Secret store checks (depends on brief 09 outcome)

- [ ] `secret TEST_VAR test/sample` (or whichever path Daniel has stored) populates `$env:TEST_VAR`.
- [ ] The secret value does NOT appear in PowerShell history (`Get-History`).

### Performance checks

- [ ] `Measure-Command { pwsh -NoLogo -Command 'exit' }` reports < 1.5s.
- [ ] Startup of an interactive `pwsh` session (with profile loaded) feels instantaneous (no visible pause before prompt appears).

## Failure handling

If any check fails:

1. **Don't try to fix silently.** Surface the failure to Daniel with the specific check that failed and the brief that's most likely responsible.
2. **Don't declare "done with caveats."** Either the bootstrap matches the Linux feel, or it doesn't. Partial pass is a fail.
3. **Document the failure** in a one-paragraph note appended to a `BOOTSTRAP_LOG.md` at the repo root, so future Claude sessions can learn from it.
