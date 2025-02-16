# shellcheck disable=SC2148

##############################
# Color Definitions
##############################
CYAN='\033[01;36m'
MAGENTA='\033[01;35m'
BLUE='\033[01;34m'
GREEN='\033[01;32m'
YELLOW='\033[01;33m'
RED='\033[01;31m'
RESET='\033[0m'

##############################
# Output Function
##############################
# Usage: color_out <emoji> <message> [optional-message-color]
color_out() {
    local emoji="$1"
    local message="$2"
    local msg_color="${3:-$CYAN}"
    printf "%b%s %s%b\n" "${msg_color}" "${emoji}" "${message}" "${RESET}" >&2
}

##############################
# Navigation Commands (prefix: n)
##############################
# Remove conflicting legacy aliases and define the ones used in the help menu.
alias nh='color_out "🏠" "Going home:" && cd ~'
alias n1='color_out "📂" "Moving up one level:" && cd ..'
alias n2='color_out "📂" "Moving up two levels:" && cd ../..'

##############################
# File Operations (prefix: l)
##############################
alias l='color_out "📋" "File listing:" && ls -lFh --color=auto --group-directories-first'
alias la='color_out "📋" "All files:" && ls -AlFh --color=auto --group-directories-first'
alias ld='color_out "📁" "Listing directories:" && ls -d */'
alias lf='color_out "📄" "Files only:" && ls -l --color=auto | grep -v "^d"'
alias ll='color_out "📋" "Detailed listing:" && ls -lAFh --color=auto --group-directories-first'
alias lt='color_out "⏲️" "Time-sorted:" && ls -ltrFh --color=auto'
alias lr='color_out "⏲️" "Reverse time-sorted:" && ls -ltFh --color=auto --reverse'

##############################
# System Management (no prefix)
##############################
alias a='color_out "📝" "Editing aliases..." && nvim ~/.bash_aliases && source ~/.bash_aliases && color_out "🔄" "Aliases updated"'
alias b='color_out "📝" "Editing bashrc..." && nvim ~/.bashrc && source ~/.bashrc && color_out "🔄" "Bashrc updated"'
alias c='color_out "🧹" "Clearing screen..." && clear && printf "\e[3J"'
alias d='color_out "🗑️" "Deleting file:" && rm'
alias e='color_out "📝" "Opening editor..." && nvim'
alias p='color_out "⚙️" "Process list:" && ps aux'
alias q='color_out "👋" "Exiting shell..." && exit'
alias r='color_out "🔄" "Reloading configuration..." && . ~/.bashrc'
alias v='color_out "📝" "Opening editor..." && nvim'
alias x='color_out "👋" "Exiting shell..." && exit'

##############################
# Git Commands (prefix: g)
##############################
if command -v git >/dev/null 2>&1; then
    alias g='git'
    alias ga='color_out "📦" "Staging changes..." && git add --all && color_out "✅" "Changes staged"'
    # Rename pull alias from "gpl" to "gq" as per help menu:
    alias gq='color_out "⬇️" "Pulling changes..." && git pull && color_out "✅" "Changes pulled"'
    # Rename status alias to "gs":
    alias gs='color_out "📊" "Repository status:" && git status'
    alias gp='color_out "⬆️" "Pushing changes..." && git push && color_out "✅" "Changes pushed"'
    alias gg='color_out "📊" "Git log graph:" && git log --oneline --graph --decorate --all --color'

    # Git functions—rename to match help menu:
    gc() {
        if [[ -z "$1" ]]; then
            color_out "❌" "Please provide a commit message" "$RED"
            return 1
        fi
        color_out "💾" "Committing changes..." "$YELLOW"
        if git commit -m "$*"; then
            color_out "✅" "Committed: $*" "$GREEN"
        else
            color_out "❌" "Commit failed" "$RED"
            return 1
        fi
    }
    # "gb": Create & checkout branch (was gcb)
    gb() {
        if [[ -z "$1" ]]; then
            color_out "❌" "Please provide a branch name" "$RED"
            return 1
        fi
        color_out "🌱" "Creating branch: $1" "$YELLOW"
        if git checkout -b "$1"; then
            color_out "✅" "Created and switched to: $1" "$GREEN"
        else
            color_out "❌" "Branch creation failed" "$RED"
            return 1
        fi
    }
    # "gk": Checkout branch (was gco)
    gk() {
        if [[ -z "$1" ]]; then
            color_out "❌" "Please specify a branch" "$RED"
            return 1
        fi
        color_out "🔄" "Switching to: $1" "$YELLOW"
        if git checkout "$1"; then
            color_out "✅" "Switched to: $1" "$GREEN"
        else
            color_out "❌" "Switch failed" "$RED"
            return 1
        fi
    }
    # "gd": Delete branch locally (was gbd)
    gd() {
        if [[ -z "$1" ]]; then
            color_out "❌" "Please specify a branch to delete" "$RED"
            return 1
        fi
        color_out "🗑️" "Deleting branch: $1" "$YELLOW"
        if git branch -d "$1"; then
            color_out "✅" "Deleted: $1" "$GREEN"
        else
            color_out "❌" "Deletion failed" "$RED"
            return 1
        fi
    }
    # "ge": Delete remote branch (was gbrd)
    ge() {
        if [[ -z "$1" ]]; then
            color_out "❌" "Please specify a remote branch to remove" "$RED"
            return 1
        fi
        color_out "🗑️" "Removing remote branch: $1" "$YELLOW"
        if git push origin --delete "$1"; then
            color_out "✅" "Removed remote: $1" "$GREEN"
        else
            color_out "❌" "Remote deletion failed" "$RED"
            return 1
        fi
    }
    # "gm": Merge main/master (was gcf)
    gm() {
        color_out "🔄" "Merging $(git symbolic-ref --short HEAD) with remote main/master..." "$YELLOW"
        if git checkout "$(git rev-parse --abbrev-ref HEAD)" && git pull && git merge origin/$(git rev-parse --abbrev-ref HEAD); then
            color_out "✅" "Merge complete" "$GREEN"
        else
            color_out "❌" "Merge failed" "$RED"
            return 1
        fi
    }
    # "gr": Rebase branch (was gcm)
    gr() {
        if [[ -z "$1" ]]; then
            color_out "❌" "Please specify a branch to rebase onto" "$RED"
            return 1
        fi
        color_out "🔄" "Rebasing on $1..." "$YELLOW"
        if git rebase "$1"; then
            color_out "✅" "Rebased on $1" "$GREEN"
        else
            color_out "❌" "Rebase failed" "$RED"
            return 1
        fi
    }

    # Additional Git functions (not in help menu but available)
    gpr() {
        local BRANCH
        BRANCH=$(git rev-parse --abbrev-ref HEAD)
        color_out "🔄" "Syncing ${BRANCH}..." "$YELLOW"
        if git pull --rebase origin "${BRANCH}" && git push; then
            color_out "✅" "Synced ${BRANCH}" "$GREEN"
        else
            color_out "❌" "Sync failed" "$RED"
            return 1
        fi
    }
    gpo() {
        if [[ -z "$1" ]]; then
            color_out "❌" "Please specify a branch for push" "$RED"
            return 1
        fi
        color_out "⬆️" "Pushing to $1..." "$YELLOW"
        if git push origin "$1"; then
            color_out "✅" "Pushed to $1" "$GREEN"
        else
            color_out "❌" "Push failed" "$RED"
            return 1
        fi
    }
fi

##############################
# Rust Development (Cargo) Commands (prefix: c)
##############################
if command -v cargo >/dev/null 2>&1; then
    # Remap Cargo commands to match help menu:
    alias ca='color_out "📦" "Adding dependency..." && cargo add && color_out "✅" "Dependency added"'
    alias cb='color_out "🔨" "Building project..." && cargo build && color_out "✅" "Build completed"'
    alias cr='color_out "🚀" "Building project (release)..." && cargo build --release && color_out "✅" "Release build completed"'
    alias cc='color_out "🔍" "Running Clippy..." && cargo clippy && color_out "✅" "Clippy check completed"'
    alias cd='color_out "🌳" "Showing dependency tree:" && cargo tree --all-features'
    alias cf='color_out "✨" "Formatting code..." && cargo fmt && color_out "✅" "Code formatted"'
    alias ci='color_out "🆕" "Initializing project..." && cargo init && color_out "✅" "Project initialized"'
    alias cn='color_out "🆕" "Creating new project..." && cargo new && color_out "✅" "Project created"'
    alias cx='color_out "▶️" "Running project..." && cargo run && color_out "✅" "Run complete"'
    alias cy='color_out "🚀" "Running project (release)..." && cargo run --release && color_out "✅" "Release run complete"'
    alias ct='color_out "🧪" "Running tests..." && cargo test && color_out "✅" "Tests completed"'
    alias cu='color_out "🔄" "Updating dependencies..." && cargo update && color_out "✅" "Dependencies updated"'
    alias cz='color_out "🔧" "Applying fixes..." && cargo fix && color_out "✅" "Fixes applied"'
fi

##############################
# Rustup Commands (prefix: r)
##############################
if command -v rustup >/dev/null 2>&1; then
    alias ra='color_out "📦" "Adding component..." && rustup component add && color_out "✅" "Component added"'
    alias rd='color_out "⚡" "Setting default toolchain..." && rustup default && color_out "✅" "Default toolchain set"'
    alias ro='color_out "📚" "Opening documentation..." && rustup doc --open'
fi
