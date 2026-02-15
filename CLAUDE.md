# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A tmux workflow framework for managing multiple Claude Code sessions across projects. It provides session switching with real-time CC status indicators, a TUI dashboard, git worktree lifecycle management, and sprint planning tools — all integrated via tmux keybindings and status bar.

## Installation

```bash
./install.sh          # Symlinks bin/* to ~/.local/bin/
```

Then add to `~/.config/tmux/tmux.conf` (before the TPM run line):
```
source-file ~/Documents/code/tmux-personal-ai-config/tmux-workflow.conf
```

The `tmux-cc-set-formats` script must run **after** TPM/rose-pine loads (placed after the TPM run line in tmux.conf).

## Architecture

### Claude Code Status Detection

The system tracks CC state per tmux pane using the `@claude_status` pane option:

1. **`tmux-cc-notify`** — CC hook handler. Called by Claude Code on lifecycle events (`SessionStart`, `UserPromptSubmit`, `PreToolUse`, `Notification`, `Stop`, `SessionEnd`). Sets `@claude_status` on `$TMUX_PANE` and triggers `refresh-client -S`.
2. **`cc-hook-state`** — Alternative hook handler that writes state to `/tmp/cc-state/<session_id>.json` (file-based, not tmux options).
3. **`tmux-cc-status`** — Shared library (sourced, not executed). Provides `cc_status_for_session`, `cc_instance_count`, `cc_best_pane`, `cc_status_icon`, `cc_cleanup_stale`. Aggregates per-pane status to session level with priority: WAITING > WORKING > IDLE > SHELL.

### Status Flow

```
CC hook event → tmux-cc-notify → sets @claude_status on pane → refresh-client -S
                                                                      ↓
tmux-cc-set-formats reads @claude_status in format strings → icons in window names
tmux-switcher / tmux-dashboard / tmux-pending-count → reads via tmux-cc-status lib
```

### Key Event Mappings in `tmux-cc-notify`

- `SessionStart` → IDLE (skips compaction restarts)
- `UserPromptSubmit` → WORKING
- `PreToolUse` → WORKING (only if current state is WAITING, to avoid overriding IDLE after Stop)
- `Notification` → WAITING
- `Stop` → IDLE
- `SessionEnd` → unsets `@claude_status`

### UI Components

- **`tmux-switcher`** — fzf popup (prefix-s) with status icons, pane preview, ctrl-d to kill sessions. Switches to the "best pane" (highest-priority CC status) in the selected session.
- **`tmux-dashboard`** — Full TUI (prefix-d) with Rose Pine colors, auto-refresh, j/k navigation, w to jump to next WAITING, preview panel. Sorts sessions by status priority.
- **`tmux-cc-set-formats`** — Sets window-status-format with conditional Nerd Font icons based on `@claude_status`. Uses Rose Pine palette (#c4a7e7 inactive, #f6c177 active).
- **`tmux-worktree`** — fzf popup (prefix-w) for worktree lifecycle management. Lists worktrees with CC status icons, preview panel (pane capture or git log), ctrl-n to create (gum filter/input), ctrl-d to remove (gum confirm). Calls `wt` as subprocess.
- **`tmux-pending-count`** — Status bar widget showing count of sessions in WAITING state.

### Worktree/Session Management

- **`wt`** — Creates git worktrees alongside the source repo (`<project>-worktrees/<branch>/`) and matching tmux sessions named `project/branch`. Searches `~/Documents/work` and `~/Documents/code`. Subcommands: `wt <proj> <branch>`, `wt rm <proj> <branch>`, `wt ls`.
- **`tmux-sessionizer`** — fzf project picker that also discovers `*-worktrees/` subdirectories. Uses `project/branch` naming for worktree sessions.

### Daily Workflow

- **`day start`** — Morning bootstrap: shows sprint, lists sessions/worktrees, offers to edit sprint.
- **`day end`** — Cleanup: lists sessions, offers to kill all except current.
- **`edit-sprint`** — Opens latest `~/Documents/work/ai-sprints/sprint-N.md` in neovim.
- **`current-sprint`** — Prints path to latest sprint file.

## Tmux Keybindings (from tmux-workflow.conf)

- `prefix-s` → session switcher popup
- `prefix-t` → edit sprint popup
- `prefix-d` → dashboard popup (detach moved to `prefix-D`)
- `prefix-w` → worktree manager popup (replaces default `choose-tree`)
- `M-n` / `M-p` → next/previous window (Kitty maps Ctrl+Tab to these)

## Key Gotchas

- `bin/` scripts are NOT in PATH from tmux context. Always use full paths (`$HOME/Documents/code/tmux-personal-ai-config/bin/...`) in tmux config.
- `$(...)` inside double-quoted tmux config strings is interpreted by tmux as variable expansion, NOT by the shell. Use wrapper scripts instead of inline command substitution.
- Shell aliases don't work in non-interactive scripts. Use actual commands (e.g., `NVIM_APPNAME="nvim-personal" nvim` instead of `vi`).
- `tmux-cc-status` is a library meant to be sourced (`source "$SCRIPT_DIR/tmux-cc-status"`), not executed directly.
- The `PreToolUse` handler in `tmux-cc-notify` intentionally only transitions from WAITING→WORKING to prevent subagent tool use (like brain-log) from overriding IDLE state after Stop.

## Dependencies

- `fzf` — used by tmux-switcher and tmux-sessionizer
- `jq` — used by cc-hook-state and tmux-cc-notify
- `gum` — required for `tmux-worktree`, also used by `day` for interactive prompts
- `bat` — optional, used by `day sprint` for pretty-printing
- Nerd Fonts — status icons (bell, cog, check, terminal)
- Rose Pine theme — color values hardcoded in dashboard and format scripts
