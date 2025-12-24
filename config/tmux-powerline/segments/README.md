# Custom tmux-powerline Segments

## git_repo.sh

Displays the Git repository name for repositories under ~/.ghq/.

### Features
- Shows repository name only for repos under ~/.ghq/
- GitHub repositories display with  icon (nf-cod-github)
- Format: `owner/repo` for GitHub repos under ~/.ghq/github.com/

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

- **Repository Name**: Shows the name of the current Git repository (only for repos under ~/.ghq/)
  - GitHub repositories display with  icon (nf-cod-github)
  - Format: `owner/repo` for GitHub repos under ~/.ghq/github.com/
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
- Repository name (from remote origin or directory name)
- Commit status (clean or uncommitted changes)
- Current branch name (with truncation for long names)

### Example Output

- ` papix/dotfiles  main ` - Clean GitHub repository on main branch
- ` owner/project  feature/new-feature ` - GitHub repository with uncommitted changes
- ` main ` - Repository outside ~/.ghq/ showing only branch and clean status
- ` :a1b2c3d ` - Detached HEAD state with uncommitted changes