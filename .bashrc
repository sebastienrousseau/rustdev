#!/usr/bin/env bash

# Exit if not running interactively
[[ $- != *i* ]] && return

# Load environment variables for Rust
# shellcheck disable=SC1091
[[ -f /etc/profile.d/rust.sh ]] && source /etc/profile.d/rust.sh

# Load aliases if they exist (fixed path)
# shellcheck disable=SC1090
[[ -f ~/.bash_aliases ]] && source ~/.bash_aliases

# Basic settings
umask 002
SHELL="/bin/bash"
TERM="xterm-256color"
# shellcheck disable=SC2025
PS1='\[\e[01;35m\]❯\[\e[0m\] \[\e[01;36m\]\w\[\e[0m\] \[\e[01;34m\]\$\[\e[0m\] '

# History settings
HISTSIZE=1000
HISTFILESIZE=2000
HISTCONTROL=erasedups:ignoredups:ignorespace
shopt -s histverify
if type git_prompt &>/dev/null; then
    PROMPT_COMMAND='history -a; PS1=$(git_prompt)'
fi

# Shell options
shopt -s cdspell checkwinsize cmdhist histappend nocaseglob

# Environment variables
export CLICOLOR=1
export LSCOLORS=gxBxhxDxfxhxhxhxhxcxcx

# Color definitions
CYAN='\033[01;36m'
MAGENTA='\033[01;35m'
BLUE='\033[01;34m'
GREEN='\033[01;32m'
YELLOW='\033[01;33m'
RED='\033[01;31m'
WHITE='\033[01;37m'
RESET='\e[0m'
BG_BLUE='\033[44m'

# Print centered text
print_centered() {
    local text="$1"
    local width=60
    printf "%*s\n" $(((${#text} + width) / 2)) "${text}"
}

# Print menu section
print_menu_section() {
    local title="$1"
    shift
    echo -e "\n${MAGENTA}${title}:${RESET}"
    local items=("$@")
    for item in "${items[@]}"; do
        echo -e "  ${CYAN}${item}${RESET}"
    done
}

# Helper function: Print a section as a sleek bullet list.
print_help_section() {
    local title="$1"
    shift
    # Print section header with extra bottom padding (newline)
    echo -e "\n${MAGENTA}=== ${title} ===${RESET}\n"
    while [[ "$#" -gt 0 ]]; do
        local cmd="$1"
        local desc="$2"
        shift 2
        printf "  ${CYAN}➜ %-10s${RESET} - %s\n" "$cmd" "$desc"
    done
    echo "" # Optional: add an extra newline after the section
}

# Helper function: Prompt user to continue to the next section.
prompt_next() {
    echo -e "\n${YELLOW}Press any key to view the next section, or 'q' to quit help${RESET}"
    read -n 1 -s choice
    if [[ "$choice" == "q" ]]; then
        return 1
    fi
    clear
    return 0
}

# Sleek, paginated help menu that displays one section at a time.
show_help_menu() {
    clear
    echo -e "${BG_BLUE}${WHITE}$(print_centered "RUST-DEV CONTAINER HELP")${RESET}"
    echo -e "${YELLOW}$(print_centered "Quick Reference Guide")${RESET}"
    echo

    # Cargo Commands
    print_help_section "Cargo Commands" \
        "cga" "Add a dependency" \
        "cgb" "Build project" \
        "cgbr" "Build project (release)" \
        "cgc" "Run Clippy" \
        "cgf" "Format code" \
        "cgx" "Apply fixes" \
        "cgn" "Create new Cargo project" \
        "cgi" "Initialize Cargo project" \
        "cgr" "Run project" \
        "cgrr" "Run project (release)" \
        "cgt" "Run tests" \
        "cgu" "Update dependencies" \
        "cgd" "Show dependency tree"
    prompt_next || {
        system_info
        return
    }

    # Git Commands
    print_help_section "Git Commands" \
        "g" "Git command prefix" \
        "ga" "Stage all changes" \
        "gc" "Commit changes" \
        "gcb" "Create & checkout new branch" \
        "gcl" "Clone repository" \
        "gco" "Checkout branch" \
        "gbd" "Delete branch locally" \
        "gbrd" "Delete remote branch" \
        "gcm" "Rebase on main/master" \
        "gcf" "Merge main/master into branch" \
        "glast" "Show last commit details" \
        "glog" "Display git log graph" \
        "gp" "Push changes" \
        "gpl" "Pull changes" \
        "gpo" "Push to specific branch" \
        "grb" "Rebase on specified branch" \
        "gst" "Show git status"
    prompt_next || {
        system_info
        return
    }

    # File & Editor Commands
    print_help_section "File & Editor Commands" \
        "e" "Edit file(s) using vim" \
        "l" "List files" \
        "la" "List all files" \
        "ll" "Detailed listing" \
        "lf" "List non-directory files" \
        "lt" "List files sorted by time" \
        "ltr" "Reverse time-sorted listing" \
        "v" "Edit file(s) using vim"
    prompt_next || {
        system_info
        return
    }

    # Navigation
    print_help_section "Navigation" \
        "-" "Switch to previous directory" \
        "~" "Go to home directory" \
        ".." "Go up one directory" \
        "..." "Go up two directories" \
        "cd.." "Go up one directory"
    prompt_next || {
        system_info
        return
    }

    # System Commands
    print_help_section "System Commands" \
        "c" "Clear screen" \
        "ea" "Edit bash aliases" \
        "eb" "Edit bash configuration" \
        "h" "Show history" \
        "kkill" "Kill process by name" \
        "p" "List processes" \
        "r" "Reload bash configuration" \
        "t" "Open system monitor" \
        "x" "Exit shell with farewell"
    prompt_next || {
        system_info
        return
    }

    # Rustup Commands
    print_help_section "Rustup Commands" \
        "rca" "Add a Rust component" \
        "rde" "Set default toolchain" \
        "rdo" "Open Rust documentation"

    echo -e "\n${YELLOW}Press any key to return to system info or 'c' to clear screen${RESET}"
    read -n 1 -s final_choice
    if [[ ${final_choice} == "c" ]]; then
        clear
    else
        system_info
    fi
}

# System information function
system_info() {
    # Memory information
    local mem mem_total mem_used mem_free mem_shared mem_cached mem_available mem_usage
    mem=$(free -b)
    mem_total=$(awk '/^[Mm]em/{printf "%.2f", $2/1073741824}' <<<"${mem}")
    mem_used=$(awk '/^[Mm]em/{printf "%.2f", $3/1073741824}' <<<"${mem}")
    mem_free=$(awk '/^[Mm]em/{printf "%.2f", $4/1073741824}' <<<"${mem}")
    mem_shared=$(awk '/^[Mm]em/{printf "%.2f", $5/1073741824}' <<<"${mem}")
    mem_cached=$(awk '/^[Mm]em/{printf "%.2f", $6/1073741824}' <<<"${mem}")
    mem_available=$(awk '/^[Mm]em/{printf "%.2f", $7/1073741824}' <<<"${mem}")
    mem_usage=$(awk '/Mem/ {printf("%3.1f%%", $3/$2*100)}' <<<"${mem}")

    # Swap information
    local swap_total swap_used swap_free swap_usage
    swap_total=$(awk '/^[Ss]wap/{printf "%.2f", $2/1073741824}' <<<"${mem}")
    swap_used=$(awk '/^[Ss]wap/{printf "%.2f", $3/1073741824}' <<<"${mem}")
    swap_free=$(awk '/^[Ss]wap/{printf "%.2f", $4/1073741824}' <<<"${mem}")
    swap_usage=$(awk '/Swap/ {printf("%3.1f%%", $3/$2*100)}' <<<"${mem}")

    # System information
    local ip4 kernel system_load root_used procs users
    ip4=$(ip addr show | grep -v inet6 | grep inet | awk 'NR==2 {print $2}' | cut -d/ -f 1)
    kernel=$(uname -r | sed 's/-ar.*$//')
    system_load=$(awk '{print $1}' /proc/loadavg)
    root_used=$(df -h / | awk '/\// {print $(NF-1)}')
    procs=$(ps aux | wc -l)
    users=$(users | wc -w)

    # Color threshold function
    color_by_threshold() {
        local value=$1
        local threshold=$2
        local numeric_value=${value//%/}
        if (($(echo "$numeric_value > $threshold" | bc -l))); then
            echo -e "${RED}${value}${RESET}"
        else
            echo -e "${GREEN}${value}${RESET}"
        fi
    }

    # Calculate colored values
    local colored_mem_usage
    colored_mem_usage=$(color_by_threshold "$mem_usage" "80")
    local colored_swap_usage
    colored_swap_usage=$(color_by_threshold "$swap_usage" "50")
    local colored_system_load
    colored_system_load=$(color_by_threshold "$system_load" "2")
    local colored_root_used=${root_used//%/}
    colored_root_used=$(color_by_threshold "$root_used" "90")

    # Display information
    clear
    local centered_text
    centered_text=$(print_centered "WELCOME TO RUST-DEV CONTAINER") || true
    echo -e "${BG_BLUE}${WHITE}${centered_text}${RESET}"
    local machine_info
    machine_info=$(uname -m) || true
    echo -e "${CYAN}Version: ${BLUE}1.0${RESET} - Linux ${kernel} (${machine_info})"
    echo
    echo -e "┌ ${MAGENTA}RAM:${RESET}\t\t\t┌ ${MAGENTA}SWAP:${RESET}"
    echo -e "├─ Used: ${RED}${mem_used}GB${RESET}\t\t├─ Used: ${RED}${swap_used}GB${RESET}"
    echo -e "├─ Free: ${GREEN}${mem_free}GB${RESET}\t\t├─ Free: ${GREEN}${swap_free}GB${RESET}"
    echo -e "├─ Shared: ${mem_shared}GB\t└─ Total: ${swap_total}GB"
    echo -e "├─ Cached: ${GREEN}${mem_cached}GB${RESET}"
    echo -e "├─ Available: ${GREEN}${mem_available}GB${RESET}"
    echo -e "└─ Total: ${mem_total}GB"
    echo
    echo -e "┌ ${MAGENTA}System:${RESET}\t\t┌ ${MAGENTA}Disk:${RESET}"
    echo -e "├─ System load: ${colored_system_load}\t├─ Processes: ${procs}"
    echo -e "├─ Usage of /: ${colored_root_used}\t├─ Users logged in: ${users}"
    echo -e "├─ Memory usage: ${colored_mem_usage}\t└─ IP address: ${ip4}"
    echo -e "└─ Swap usage: ${colored_swap_usage}"
    echo
    echo -e "${YELLOW}Type 'help' for available commands or type 'c' and press Enter to clear screen${RESET}"
    echo
}

# Show auto-completion list automatically
bind "set show-all-if-ambiguous On"

# Add help alias
alias help='show_help_menu'

# Display system information on login
system_info
