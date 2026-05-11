# CLAUDE.md

## Project Overview

A comprehensive dotfiles repository providing a modular Zsh configuration, tmux integration, and various development tools.

## Tech Stack

- Shell: Zsh (modular configuration)
- Terminal Workspace: cmux (macOS) + tmux/tmux-powerline fallback
- Editor: Neovim
- Package Manager: Homebrew
- Tools: peco, ghq, direnv, mise, prek, actionlint, gitleaks, shellcheck, shfmt, tig, tree, colordiff, tldr, ag, roots, azure-cli

## Development Standards

- Coding: `@docs/standards/coding.md`
- Git: `@docs/standards/git.md`
- Security: `@docs/standards/security.md`

## Quick Start

```bash
# Clone and install
git clone git@github.com:papix/dotfiles.git ~/.ghq/github.com/papix/dotfiles
cd ~/.ghq/github.com/papix/dotfiles
bash setup.sh

# Disable Linux tmux auto-start
export DISABLE_AUTO_TMUX=1
```

## Key Features

- **Git hooks**: prek-based pre-commit hooks and gitleaks secret scanning
- **Fonts**: HackGen Nerd Font auto-installation
- **cmux/tmux**: cmux-native workspaces on macOS, tmux fallback session management, Git repository-aware tmux window names
- **Clipboard**: OSC52 fallback support (works in remote environments)

## Important Notes

### Language Conventions
- **Comments in code files**: Written in Japanese
- **Echo messages and logs**: Written in English

### Platform Support
- macOS: Package management via Homebrew
- Linux: apt/yum/pacman support, automatic Linuxbrew setup
- Codespaces: Special configuration support

### Module Structure
Zsh configuration managed by numbered modules in `config/zsh/`:
- 00-init.zsh: Initialization (COMMAND_CACHE, .zwc compilation)
- 10-env.zsh: Environment variables and tool initialization
- 15-platform-*.zsh: Platform-specific settings (macOS/Linux)
- 20-colors.zsh: Solarized Dark color definitions
- 30-options.zsh: Shell options
- 40-completion.zsh: Completion settings
- 50-prompt.zsh: Prompt and VCS information
- 60-aliases.zsh: Aliases
- 70-functions.zsh: Utility functions
- 80-*.zsh: External tool integrations (editor, peco, pnpm)
- 81-git.zsh: Git extensions
- 82-tmux.zsh: cmux-aware tmux integration and auto-start
- 90-external.zsh: Other external tools

See respective documentation for details.
