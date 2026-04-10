# Custom tmux-powerline Segments

## git_repo.sh

Displays the Git repository name for repositories under `~/.ghq/` and supported worktree paths.

### Features
- Shows repository name for repos under `~/.ghq/` and supported worktrees
- GitHub repositories display with  icon (nf-cod-github)
- Format: `owner/repo` for GitHub repos under `~/.ghq/github.com/`
- Format: `worktree-icon + repo` for `${WORKTREE_BASE_DIR}/github.com/...` and `/var/tmp/vibe-kanban/worktrees/...`

### Configuration
```bash
# Repository symbol (GitHub repos will show nf-cod-github automatically)
# export TMUX_POWERLINE_SEG_GIT_REPO_SYMBOL=""
```

## git_branch_status.sh

Displays the current Git branch name and commit status.

### Features
- Shows current branch name with  icon (nf-pl-branch)
- Commit status displayed at the end of branch name:
  -  (nf-fa-ok_sign) for clean repository
  -  (nf-fa-remove_sign) for uncommitted changes
- Branch name truncation for long names

### Configuration
```bash
# Max branch name length
TMUX_POWERLINE_SEG_GIT_BRANCH_MAX_LEN="24"
# Branch truncate symbol
TMUX_POWERLINE_SEG_GIT_BRANCH_TRUNCATE_SYMBOL="…"
```

## git_status.sh (Combined segment)

A comprehensive Git status segment that displays repository name, commit status, and branch information in one segment.

### Features

- **Repository Name**: Shows the name of the current Git repository for `~/.ghq/` and supported worktrees
  - GitHub repositories display with  icon (nf-cod-github)
  - Format: `owner/repo` for GitHub repos under `~/.ghq/github.com/`
  - Format: `worktree-icon + repo` for `${WORKTREE_BASE_DIR}/github.com/...` and `/var/tmp/vibe-kanban/worktrees/...`
- **Branch Name**: Shows the current branch name with  icon (nf-pl-branch)
  - Truncation support for long branch names
- **Commit Status**: Displayed at the end of branch name
  -  (nf-fa-ok_sign) for clean repository
  -  (nf-fa-remove_sign) for uncommitted changes

### Configuration

You can customize the segment by setting these environment variables:

```bash
# Show/hide components (0 or 1)
TMUX_POWERLINE_SEG_GIT_STATUS_SHOW_REPO_NAME="1"
TMUX_POWERLINE_SEG_GIT_STATUS_SHOW_COMMIT_STATUS="1"
TMUX_POWERLINE_SEG_GIT_STATUS_SHOW_BRANCH="1"

# Symbols (most are set automatically)
TMUX_POWERLINE_SEG_GIT_STATUS_REPO_SYMBOL=""      # Repository icon (GitHub shows  automatically)
TMUX_POWERLINE_SEG_GIT_STATUS_BRANCH_SYMBOL=""     # Branch icon ( is shown automatically)

# Formatting
TMUX_POWERLINE_SEG_GIT_STATUS_SEPARATOR=" "           # Separator between components
TMUX_POWERLINE_SEG_GIT_STATUS_MAX_BRANCH_LEN="24"     # Max branch name length
TMUX_POWERLINE_SEG_GIT_STATUS_TRUNCATE_SYMBOL="…"     # Truncation symbol
```

### Usage for Separated Segments

Add both segments to your tmux-powerline theme configuration with different colors:

```bash
TMUX_POWERLINE_RIGHT_STATUS_SEGMENTS=(
    # ... other segments ...
    "git_repo 33 235"          # Blue text on dark background
    "git_branch_status 64 235"  # Green text on dark background
    # ... other segments ...
)
```

### Usage for Combined Segment

Add the single segment to your tmux-powerline theme configuration:

```bash
TMUX_POWERLINE_RIGHT_STATUS_SEGMENTS=(
    # ... other segments ...
    "git_status 64 235"
    # ... other segments ...
)
```

The segment will automatically detect Git repositories and display:
- Repository name (from supported path conventions)
- Commit status (clean or uncommitted changes)
- Current branch name (with truncation for long names)

### Example Output

- ` papix/dotfiles  main ` - Clean GitHub repository on main branch
- ` dotfiles  main ` - Supported worktree repository on main branch
- ` owner/project  feature/new-feature ` - GitHub repository with uncommitted changes
- ` main ` - Repository outside ~/.ghq/ showing only branch and clean status
- ` :a1b2c3d ` - Detached HEAD state with uncommitted changes

## claude_usage.sh

Displays Claude Code API rate limit usage for the 5-hour and 7-day windows.

### Features

- Shows 5-hour and 7-day rate limit utilization as percentages
- Shows next reset time in local time
  - 5-hour window: `〜HH:MM`
  - 7-day window: `〜MM/DD HH:MM`
- Color coding based on projected pace at reset time once at least 5 minutes have elapsed in the current window: green (projected < 80%), yellow (projected 80-99%), red (projected >= 100%)
- Falls back to raw utilization thresholds when reset time is unavailable or the current window is younger than 5 minutes
- Results cached every 15 minutes (at :00, :15, :30, :45) to avoid excessive API calls
- Falls back to stale cache (up to 24 hours) when API is unreachable
- Appends `rate limited` when latest data cannot be fetched due to API rate limits
- Honors `Retry-After` to suppress retries until the next allowed time
- Hidden when credentials are not configured

### How It Works

Reads `~/.claude/.credentials.json` to obtain the OAuth access token, then calls
`https://api.anthropic.com/api/oauth/usage` with the required `anthropic-beta: oauth-2025-04-20` header.
No API key is stored directly in this repository.

### Configuration

```bash
# Segment label shown before usage stats
export TMUX_POWERLINE_SEG_CLAUDE_USAGE_LABEL="CC"
```

### Usage

This segment is displayed on the lower-right side of the second status line.
No additional right-segment configuration is required.

### Example Output

```
CC 5h:14%（〜16:00） 7d:80%（〜03/06 11:59）
CC 5h:14%（〜16:00） 7d:80%（〜03/06 11:59） rate limited
```

The color reflects projected usage at reset time once the current window has at least 5 minutes of history.
If reset metadata is unavailable, or the current window is younger than 5 minutes, it falls back to the raw utilization thresholds.
When rate-limited, stale cache is shown with a `rate limited` suffix.
