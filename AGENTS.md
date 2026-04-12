# Repository Guidelines

## Project Structure & Module Organization
- `config/`: Main Zsh configuration. Numbered modules control load order (00-09 init, 10-19 platform, 20-59 core, 60-79 alias/functions, 80-89 tools, 90-99 misc).
- `bin/`: Auxiliary scripts. Maintain execution permissions and shebangs, follow existing patterns when adding.
- `docs/standards/`: Detailed coding, Git, and security standards. Always review before making changes.
- `setup.sh`: Entry point for initial setup. Follow the steps in `README.md`.

## Build, Test, and Development Commands
- `bash setup.sh --doctor`: Check package files and required tools.
- `bash setup.sh --dry-run`: Preview the setup plan.
- `bash setup.sh`: Run initial setup.
- `export DISABLE_AUTO_TMUX=1`: Disable tmux auto-start (when needed).
- `brew update && brew upgrade`: Update dependency tools (optional maintenance).

## Coding Style & Naming Conventions
- Shell: Indent with 4 spaces. Use `set -euo pipefail` as the base for bash scripts.
- Naming: Functions use `snake_case`, environment variables use `UPPER_SNAKE_CASE`.
- Comments in Japanese, `echo`/log output in English.
- Config files: YAML/TOML use 2 spaces, JSON uses 2 spaces with no trailing commas.

## Testing Guidelines
- Run `bash test/run.sh` before completing changes.
- After shell/config changes, manually verify affected areas (e.g., `zsh` startup, `tmux` startup, key aliases).
- If adding tests, place them in `test/` or similar with a single entry point.

## Commit & Pull Request Guidelines
- Commits in Japanese using Conventional Commits format (e.g., `feat:`, `fix:`, `docs:`, `refactor:`, `chore:`).
- Branch names: `main`, `feature/*`, `fix/*`, `refactor/*`.
- PRs target `main`. Include: change description, rationale, manual verification results, and impact scope (especially `setup.sh` or `config/`).

## Security & Configuration Tips
- Store secrets in 1Password when possible. The default lookup is `op://dotfiles/shared-env/NPM_TOKEN`, and shell-side autoload is opt-in via `DOTFILES_1PASSWORD_AUTOLOAD=1`.
- Keep `~/.zshrc.local` / `~/.zshenv.local` for machine-specific non-secret settings and last-resort local overrides.
- Set permissions to `600` for important files, never output secrets in logs.
