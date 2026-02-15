# Setup Guide — New Linux Machine

Step-by-step instructions to set up the tmux workflow framework on a fresh Linux machine.

## 1. Install Dependencies

### Core packages

```bash
sudo apt install tmux fzf jq bat
```

> On Ubuntu, `bat` installs as `batcat`. You may need to alias it:
> ```bash
> mkdir -p ~/.local/bin
> ln -s /usr/bin/batcat ~/.local/bin/bat
> ```

### gum (Charm CLI)

Required for `tmux-worktree` and `day` interactive prompts.

```bash
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
sudo apt update && sudo apt install gum
```

### Nerd Font

Status bar icons require a [Nerd Font](https://www.nerdfonts.com/). Download one (e.g., JetBrainsMono Nerd Font) and install:

```bash
mkdir -p ~/.local/share/fonts
# Unzip your downloaded Nerd Font into that directory
fc-cache -fv
```

Then configure your terminal emulator to use the Nerd Font.

## 2. Clone the Repository

```bash
mkdir -p ~/Documents/code
cd ~/Documents/code
git clone <your-repo-url> tmux-personal-ai-config
```

> **Important:** `tmux-workflow.conf` hardcodes paths to `$HOME/Documents/code/tmux-personal-ai-config/bin/...`. If you clone to a different location, update the paths in `tmux-workflow.conf`.

## 3. Run the Installer

```bash
cd ~/Documents/code/tmux-personal-ai-config
chmod +x install.sh
./install.sh
```

This symlinks all `bin/*` scripts to `~/.local/bin/`.

Make sure `~/.local/bin` is in your `PATH`. Add this to `~/.bashrc` or `~/.zshrc` if needed:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

## 4. Set Up tmux

### Install TPM (Tmux Plugin Manager)

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

### Configure tmux.conf

Edit `~/.config/tmux/tmux.conf`:

```tmux
# --- Your base config here ---

# Rose Pine theme
set -g @plugin 'rose-pine/tmux'

# Source the workflow config BEFORE the TPM run line
source-file ~/Documents/code/tmux-personal-ai-config/tmux-workflow.conf

# TPM run line
run '~/.tmux/plugins/tpm/tpm'

# AFTER TPM — set status bar formats with Claude Code status icons
run-shell '~/.local/bin/tmux-cc-set-formats'
```

### Install TPM plugins

Open tmux and press `prefix + I` (capital I) to install plugins.

## 5. Set Up Claude Code Hooks

Configure Claude Code to report lifecycle events to `tmux-cc-notify`. Add to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "SessionStart": [{ "command": "tmux-cc-notify SessionStart" }],
    "UserPromptSubmit": [{ "command": "tmux-cc-notify UserPromptSubmit" }],
    "PreToolUse": [{ "command": "tmux-cc-notify PreToolUse" }],
    "Notification": [{ "command": "tmux-cc-notify Notification" }],
    "Stop": [{ "command": "tmux-cc-notify Stop" }],
    "SessionEnd": [{ "command": "tmux-cc-notify SessionEnd" }]
  }
}
```

## 6. Create the Sprint Directory

```bash
mkdir -p ~/Documents/work/ai-sprints
```

## Notes

### Terminal emulator

Everything runs inside tmux, so the window manager (i3, Hyprland, etc.) doesn't matter. Any terminal emulator with Nerd Font support works (Alacritty, Kitty, Ghostty, etc.).

### Ctrl+Tab window switching

The workflow conf maps `M-n` / `M-p` to next/previous tmux window. Kitty translates `Ctrl+Tab` → `M-n` and `Ctrl+Shift+Tab` → `M-p` automatically. Other terminals may need manual keybinding configuration to send those sequences, or you can use `Alt+n` / `Alt+p` directly.

### Keybindings reference

| Binding      | Action                  |
|--------------|-------------------------|
| `prefix + s` | Session switcher popup  |
| `prefix + d` | Dashboard popup         |
| `prefix + D` | Detach client           |
| `prefix + w` | Worktree manager popup  |
| `prefix + t` | Edit sprint popup       |
| `Alt + n`    | Next window             |
| `Alt + p`    | Previous window         |
