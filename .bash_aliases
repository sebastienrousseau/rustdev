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
# Navigation Commands 🧭
##############################
alias -- -='color_out "🔄" "Previous directory:" && cd -'
alias ..='color_out "📂" "Moving up:" && cd ..'
alias ...='color_out "📂" "Moving up two levels:" && cd ../..'
alias cd..='color_out "📂" "Moving up:" && cd ..'
alias '~'='color_out "🏠" "Going home:" && cd ~'
alias d='color_out "📚" "Directory stack:" && dirs -v'

# Exit shell with farewell
x() {
    color_out "👋" "Goodbye! Have a great day!"
    exit
}

##############################
# File Operations 📁
##############################
# Modern ls alternatives with icons and colors
alias l='color_out "📋" "File listing:" && ls -lFh --color=auto --group-directories-first'
alias la='color_out "📋" "All files:" && ls -AlFh --color=auto --group-directories-first'
alias lf='color_out "📄" "Files only:" && ls -l --color=auto | grep -v "^d"'
alias ll='color_out "📋" "Detailed listing:" && ls -lAFh --color=auto --group-directories-first'
alias lt='color_out "⏲️" "Time-sorted:" && ls -ltrFh --color=auto'
alias ltr='color_out "⏲️" "Reverse time-sorted:" && ls -ltFh --color=auto --reverse'

##############################
# System Management 🖥️
##############################
# Clear and process management
alias c='color_out "🧹" "Clearing screen..." && clear && printf "\e[3J"'
alias h='color_out "📜" "Command history:" && history'
alias p='color_out "⚙️" "Process list:" && ps aux'

# System monitoring
alias t='color_out "📊" "Opening system monitor..." && btop'

# Process management
kkill() {
    if [[ -z "$1" ]]; then
        color_out "❌" "Please specify a process name" "${RED}"
        return 1
    fi
    color_out "🎯" "Attempting to terminate: $1" "${YELLOW}"
    if pkill "$1"; then
        color_out "✅" "Successfully terminated: $1" "${GREEN}"
    else
        color_out "❌" "No process found: $1" "${RED}"
        return 1
    fi
}

##############################
# Editor Commands ✏️
##############################
alias e='color_out "📝" "Opening editor..." && vim'
alias v='color_out "📝" "Opening editor..." && vim'
alias ea='color_out "📝" "Editing aliases..." && vim ~/.bash_aliases && source ~/.bash_aliases && color_out "🔄" "Aliases updated"'
alias eb='color_out "📝" "Editing bashrc..." && vim ~/.bashrc && source ~/.bashrc && color_out "🔄" "Bashrc updated"'
alias r='color_out "🔄" "Reloading configuration..." && . ~/.bashrc'

##############################
# Git Commands 🌿
##############################
if command -v git >/dev/null 2>&1; then
    # Basic git commands
    alias g='git'
    alias ga='color_out "📦" "Staging changes..." && git add --all && color_out "✅" "Changes staged"'
    alias gp='color_out "⬆️" "Pushing changes..." && git push && color_out "✅" "Changes pushed"'
    alias gpl='color_out "⬇️" "Pulling changes..." && git pull && color_out "✅" "Changes pulled"'
    alias gst='color_out "📊" "Repository status:" && git status'

    # Commit with message validation
    gc() {
        if [[ -z "$1" ]]; then
            color_out "❌" "Please provide a commit message" "${RED}"
            return 1
        fi
        color_out "💾" "Committing changes..." "${YELLOW}"
        if git commit -m "$*"; then
            color_out "✅" "Committed: $*" "${GREEN}"
        else
            color_out "❌" "Commit failed" "${RED}"
            return 1
        fi
    }

    # Branch operations
    gco() {
        color_out "🔄" "Switching to: $1" "${YELLOW}"
        if git checkout "$1"; then
            color_out "✅" "Switched to: $1" "${GREEN}"
        else
            color_out "❌" "Switch failed" "${RED}"
            return 1
        fi
    }

    gcb() {
        color_out "🌱" "Creating branch: $1" "${YELLOW}"
        if git checkout -b "$1"; then
            color_out "✅" "Created and switched to: $1" "${GREEN}"
        else
            color_out "❌" "Branch creation failed" "${RED}"
            return 1
        fi
    }

    gbd() {
        color_out "🗑️" "Deleting branch: $1" "${YELLOW}"
        if git branch -d "$1"; then
            color_out "✅" "Deleted: $1" "${GREEN}"
        else
            color_out "❌" "Deletion failed" "${RED}"
            return 1
        fi
    }

    gbrd() {
        color_out "🗑️" "Removing remote branch: $1" "${YELLOW}"
        if git push origin --delete "$1"; then
            color_out "✅" "Removed remote: $1" "${GREEN}"
        else
            color_out "❌" "Remote deletion failed" "${RED}"
            return 1
        fi
    }

    # Enhanced git prompt
    git_prompt() {
        if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            echo -e "${MAGENTA}❯${RESET} ${CYAN}\w${RESET} "
            return
        fi

        local branch status symbols=""
        branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD)
        status=$(git status --porcelain 2>/dev/null)

        # Status indicators
        [[ $(echo "$status" | grep -E "^.M") ]] && symbols+="📝"           # Modified
        [[ $(echo "$status" | grep -E "^\?\?") ]] && symbols+="❓"         # Untracked
        [[ $(echo "$status" | grep -E "^[MADRC]") ]] && symbols+="📦"      # Staged
        git rev-parse --verify refs/stash >/dev/null 2>&1 && symbols+="📌" # Stashed

        # Sync status
        local ahead behind
        ahead=$(git rev-list --count @{upstream}..HEAD 2>/dev/null)
        behind=$(git rev-list --count HEAD..@{upstream} 2>/dev/null)
        [[ -n "$ahead" && "$ahead" -gt 0 ]] && symbols+="⬆️"
        [[ -n "$behind" && "$behind" -gt 0 ]] && symbols+="⬇️"

        echo -e "${MAGENTA}❯${RESET} ${CYAN}\w${RESET} ${BLUE}[${branch}${symbols}]${RESET} "
    }

    # Branch management
    MAIN_BRANCH=$(git branch -r 2>/dev/null | grep -E 'origin/(main|master)' | sed 's/origin\///' | head -n 1 || echo "main")

    # Advanced git operations
    gcm() {
        color_out "🔄" "Rebasing on ${MAIN_BRANCH}..." "${YELLOW}"
        if git checkout "${MAIN_BRANCH}" && git pull && git checkout "$1" && git rebase "${MAIN_BRANCH}"; then
            color_out "✅" "Rebased $1 on ${MAIN_BRANCH}" "${GREEN}"
        else
            color_out "❌" "Rebase failed" "${RED}"
            return 1
        fi
    }

    gcf() {
        color_out "🔄" "Merging ${MAIN_BRANCH}..." "${YELLOW}"
        if git checkout "${MAIN_BRANCH}" && git pull && git checkout "$1" && git merge "${MAIN_BRANCH}"; then
            color_out "✅" "Merged ${MAIN_BRANCH} into $1" "${GREEN}"
        else
            color_out "❌" "Merge failed" "${RED}"
            return 1
        fi
    }

    grb() {
        color_out "🔄" "Rebasing on $1..." "${YELLOW}"
        if git rebase "$1"; then
            color_out "✅" "Rebased on $1" "${GREEN}"
        else
            color_out "❌" "Rebase failed" "${RED}"
            return 1
        fi
    }

    # Repository operations
    gcl() {
        color_out "📥" "Cloning repository..." "${YELLOW}"
        if git clone "$1" && cd "$(basename "$1" .git)"; then
            color_out "✅" "Repository cloned" "${GREEN}"
        else
            color_out "❌" "Clone failed" "${RED}"
            return 1
        fi
    }

    gpr() {
        local BRANCH
        BRANCH=$(git rev-parse --abbrev-ref HEAD)
        color_out "🔄" "Syncing ${BRANCH}..." "${YELLOW}"
        if git pull --rebase origin "${BRANCH}" && git push; then
            color_out "✅" "Synced ${BRANCH}" "${GREEN}"
        else
            color_out "❌" "Sync failed" "${RED}"
            return 1
        fi
    }

    gpo() {
        color_out "⬆️" "Pushing to $1..." "${YELLOW}"
        if git push origin "$1"; then
            color_out "✅" "Pushed to $1" "${GREEN}"
        else
            color_out "❌" "Push failed" "${RED}"
            return 1
        fi
    }

    # History management
    alias gundo='color_out "↩️" "Undoing last commit..." && git reset --soft HEAD~1 && color_out "✅" "Last commit undone"'
    alias greset='color_out "⚠️" "Resetting to remote..." && git reset --hard origin/$(git rev-parse --abbrev-ref HEAD) && color_out "✅" "Reset complete"'
    alias glog='color_out "📊" "Git log graph:" && git log --oneline --graph --decorate --all --color'
    alias glast='color_out "🔍" "Last commit:" && git log -1 --stat'
fi

##############################
# Rust Development 🦀
##############################
if command -v cargo >/dev/null 2>&1; then
    # Project initialization
    alias cg='color_out "🦀" "Cargo command:" && cargo'
    alias cgn='color_out "🆕" "Creating new project..." && cargo new && color_out "✅" "Project created"'
    alias cgi='color_out "🆕" "Initializing project..." && cargo init && color_out "✅" "Project initialized"'

    # Build and run
    alias cgb='color_out "🔨" "Building..." && cargo build && color_out "✅" "Build completed"'
    alias cgbr='color_out "🚀" "Building release..." && cargo build --release && color_out "✅" "Release build completed"'
    alias cgr='color_out "▶️" "Running..." && cargo run && color_out "✅" "Run complete"'
    alias cgrr='color_out "🚀" "Running release..." && cargo run --release && color_out "✅" "Release run complete"'

    # Development tools
    alias cgt='color_out "🧪" "Running tests..." && cargo test && color_out "✅" "Tests completed"'
    alias cgc='color_out "🔍" "Running Clippy..." && cargo clippy && color_out "✅" "Clippy check completed"'
    alias cgf='color_out "✨" "Formatting..." && cargo fmt && color_out "✅" "Code formatted"'
    alias cgx='color_out "🔧" "Fixing..." && cargo fix && color_out "✅" "Fixes applied"'

    # Dependencies
    alias cga='color_out "📦" "Adding dependency..." && cargo add && color_out "✅" "Dependency added"'
    alias cgu='color_out "🔄" "Updating dependencies..." && cargo update && color_out "✅" "Dependencies updated"'
    alias cgd='color_out "🌳" "Dependency tree:" && cargo tree --all-features'
fi

##############################
# Rustup Commands 🛠️
##############################
if command -v rustup >/dev/null 2>&1; then
    alias rca='color_out "📦" "Adding component..." && rustup component add && color_out "✅" "Component added"'
    alias rde='color_out "⚡" "Setting default..." && rustup default && color_out "✅" "Default toolchain set"'
    alias rdo='color_out "📚" "Opening documentation..." && rustup doc --open'
fi
