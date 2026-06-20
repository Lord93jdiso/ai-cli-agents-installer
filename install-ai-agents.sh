#!/bin/bash
# AI CLI Agents Installer — macOS & Linux
# Установка Node.js + выбор и установка AI агентов (npm/curl)

# ─── Colors ───────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ─── Agents ───────────────────────────────────────────────────────────────
AGENTS=(
    "OpenCode|npm:opencode-ai|opencode"
    "Claude Code|npm:@anthropic-ai/claude-code|claude"
    "Gemini CLI|npm:@google/gemini-cli|gemini"
    "Codex CLI|npm:@openai/codex|codex"
    "GitHub Copilot CLI|npm:@github/copilot|copilot"
    "Aider|npm:aider|aider"
    "Qwen Code|npm:@qwen-code/qwen-code|qwen"
    "Crush|npm:@charmland/crush|crush"
    "Cline CLI|npm:cline|cline"
    "Kilo Code CLI|npm:@kilocode/cli|kilo"
    "Goose|curl:https://github.com/aaif-goose/goose/releases/download/stable/download_cli.sh|goose"
    "Antigravity CLI|curl:https://antigravity.google/cli/install.sh|agy"
    "Grok Build|curl:https://x.ai/cli/install.sh|grok"
    "Kimi Code|npm:@moonshot-ai/kimi-code|kimi"
    "Pi|npm:@earendil-works/pi-coding-agent|pi"
    "MiMo Code|curl:https://mimo.xiaomi.com/install|mimo"
    "Codebuff|npm:codebuff|codebuff"
    "Amp Code|curl:https://ampcode.com/install.sh|amp"
)

SELECTED=()
CURRENT=0
VIEWPORT=5

hide_cursor() { echo -ne "\033[?25l"; }
show_cursor() { echo -ne "\033[?25h"; }

cleanup() {
    show_cursor
    echo -ne "\033[0m"
    stty echo 2>/dev/null
    stty sane 2>/dev/null
}
trap cleanup EXIT INT TERM

# ─── Node.js Install ──────────────────────────────────────────────────────
check_node() {
    if command -v node >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Node.js $(node --version) already installed${NC}"
        return 0
    fi
    return 1
}

install_node() {
    case "$(uname -s)" in
        Darwin)
            echo -e "${BLUE}Installing Node.js via Homebrew...${NC}"
            if command -v brew >/dev/null 2>&1; then
                brew install node
            else
                curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
            fi
            ;;
        Linux)
            if command -v apt-get >/dev/null 2>&1; then
                echo -e "${BLUE}Installing Node.js via apt...${NC}"
                curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
                sudo apt-get install -y nodejs
            elif command -v dnf >/dev/null 2>&1; then
                echo -e "${BLUE}Installing Node.js via dnf...${NC}"
                curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash -
                sudo dnf install -y nodejs
            elif command -v pacman >/dev/null 2>&1; then
                echo -e "${BLUE}Installing Node.js via pacman...${NC}"
                sudo pacman -S --noconfirm nodejs npm
            elif command -v zypper >/dev/null 2>&1; then
                echo -e "${BLUE}Installing Node.js via zypper...${NC}"
                sudo zypper install -y nodejs
            else
                echo -e "${RED}Package manager not supported. Install Node.js manually from https://nodejs.org${NC}"
                exit 1
            fi
            ;;
        *)
            echo -e "${RED}Unsupported OS${NC}"
            exit 1
            ;;
    esac
}

ensure_node() {
    echo ""
    echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║          Checking Node.js                       ║${NC}"
    echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════╝${NC}"
    echo ""

    if check_node; then
        return
    fi

    echo -e "${YELLOW}Node.js not found. Installing...${NC}"
    echo ""
    install_node
    echo ""
    if check_node; then
        echo -e "${GREEN}✓ Node.js installed successfully${NC}"
    else
        echo -e "${RED}Node.js installation failed${NC}"
        exit 1
    fi
    sleep 1
}

ensure_npm_prefix() {
    local prefix
    prefix=$(npm config get prefix 2>/dev/null)
    if [[ ! -w "$prefix" ]]; then
        echo -e "${YELLOW}Directory $prefix is not writable.${NC}"
        echo -e "${BLUE}Setting up user-local npm prefix in ~/.npm-global...${NC}"
        mkdir -p ~/.npm-global
        npm config set prefix ~/.npm-global
        echo ""

        local rc
        if [[ -f ~/.zshrc ]]; then
            rc=~/.zshrc
        else
            rc=~/.bashrc
        fi

        if ! grep -q '\.npm-global/bin' "$rc" 2>/dev/null; then
            echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> "$rc"
            echo -e "${GREEN}✓ PATH added to $rc${NC}"
        fi
        export PATH="$HOME/.npm-global/bin:$PATH"
        echo -e "${GREEN}✓ npm configured for user-local installation${NC}"
        echo ""
    fi
}

# ─── Compact TUI ──────────────────────────────────────────────────────────
MENU_HEIGHT=$((VIEWPORT + 3))
SCROLL_OFFSET=0

draw() {
    local total=${#AGENTS[@]}

    local offset=$SCROLL_OFFSET
    if [[ $CURRENT -lt $offset ]]; then
        offset=$CURRENT
    elif [[ $CURRENT -ge $((offset + VIEWPORT)) ]]; then
        offset=$((CURRENT - VIEWPORT + 1))
    fi
    local max_offset=$((total - VIEWPORT))
    [[ $max_offset -lt 0 ]] && max_offset=0
    [[ $offset -gt $max_offset ]] && offset=$max_offset
    [[ $offset -lt 0 ]] && offset=0
    SCROLL_OFFSET=$offset

    local out=""

    out+=" ${BOLD}AI CLI Agents Installer${NC}\n"

    local end=$((offset + VIEWPORT))
    [[ $end -gt $total ]] && end=$total

    for i in $(seq $offset $((end - 1))); do
        IFS='|' read -r name inst binary <<< "${AGENTS[$i]}"

        local installed=false
        command -v "$binary" >/dev/null 2>&1 && installed=true

        local check=" "
        [[ " ${SELECTED[*]} " =~ " ${i} " ]] && check="${GREEN}*${NC}"

        local mark=" "
        [[ $i -eq $CURRENT ]] && mark="${BOLD}${BLUE}›${NC}"

        local status_text=""
        if $installed; then
            status_text="${GREEN}installed${NC}"
        else
            status_text="${RED}not installed${NC}"
        fi

        out+=" $mark [$check] $name $status_text\033[K\n"
    done

    if [[ $offset -gt 0 || $end -lt $total ]]; then
        local remaining=$((total - end))
        local above=$offset
        out+=" ${YELLOW}↑${above} ↓${remaining}${NC}\033[K\n"
    else
        out+="\033[K\n"
    fi

    out+=" ${BOLD}↑/↓${NC} ${BOLD}Space${NC} sel ${BOLD}Enter${NC} inst ${BOLD}q${NC} quit\033[K"
    echo -ne "$out"
}

install_selected() {
    if [[ ${#SELECTED[@]} -eq 0 ]]; then
        echo -e "${YELLOW}Nothing selected.${NC}"
        return
    fi

    local installed_agents=()

    echo ""
    echo -e "${BOLD}Installing selected agents:${NC}"
    echo ""

    for idx in "${SELECTED[@]}"; do
        IFS='|' read -r name inst binary <<< "${AGENTS[$idx]}"
        echo -e "${BLUE}→ ${BOLD}$name${NC}..."

        local ok=false
        if [[ "$inst" == npm:* ]]; then
            local pkg="${inst#npm:}"
            if npm install -g "$pkg" 2>&1; then
                if command -v "$binary" >/dev/null 2>&1; then
                    echo -e "${GREEN}  ✓ $name installed${NC}"
                    ok=true
                else
                    echo -e "${YELLOW}  ⚠ $name installed, but $binary not found in PATH${NC}"
                    ok=true
                fi
            else
                echo -e "${RED}  ✗ Error installing $name${NC}"
            fi
        elif [[ "$inst" == curl:* ]]; then
            local url="${inst#curl:}"
            if command -v curl >/dev/null 2>&1; then
                if curl -fsSL "$url" | bash 2>&1; then
                    echo -e "${GREEN}  ✓ $name installed${NC}"
                    ok=true
                else
                    echo -e "${RED}  ✗ Error installing $name${NC}"
                fi
            else
                echo -e "${RED}  ✗ curl not found. Install curl and try again.${NC}"
            fi
        fi
        if $ok; then
            installed_agents+=("$binary|$name")
        fi
        echo ""
    done

    echo -e "${GREEN}${BOLD}Installation complete!${NC}"

    local rc_file=""
    if [[ -f ~/.zshrc ]]; then
        rc_file="~/.zshrc"
    elif [[ -f ~/.bashrc ]]; then
        rc_file="~/.bashrc"
    elif [[ -f ~/.bash_profile ]]; then
        rc_file="~/.bash_profile"
    fi
    if [[ -n "$rc_file" ]]; then
        echo ""
        echo -e "${YELLOW}Run in terminal: source $rc_file${NC}"
    fi

    if [[ ${#installed_agents[@]} -gt 0 ]]; then
        echo ""
        echo -e "${BOLD}Commands to run:${NC}"
        for item in "${installed_agents[@]}"; do
            IFS='|' read -r bin name <<< "$item"
            echo -e "  ${CYAN}$ ${BOLD}$bin${NC}"
        done
    fi
}

# ─── Main ──────────────────────────────────────────────────────────────────
has_npm_selected() {
    local idx h i
    for idx in "${SELECTED[@]}"; do
        IFS='|' read -r h i <<< "${AGENTS[$idx]}"
        [[ "$i" == npm:* ]] && return 0
    done
    return 1
}

ensure_node
ensure_npm_prefix

stty -echo 2>/dev/null
hide_cursor

echo "" >&2
first=1

while true; do
    if [[ $first -eq 1 ]]; then
        draw
        first=0
    else
        echo -ne "\033[$((MENU_HEIGHT - 1))A\033[J"
        draw
    fi

    k=''
    seq=''
    IFS= read -rsn1 k

    if [[ "$k" == $'\x1b' ]]; then
        IFS= read -rsn2 -t 0.1 seq 2>/dev/null || true
    fi

    if [[ "$seq" == '[A' || "$seq" == 'OA' ]]; then
        ((CURRENT--))
        [[ $CURRENT -lt 0 ]] && CURRENT=$((${#AGENTS[@]} - 1))
    elif [[ "$seq" == '[B' || "$seq" == 'OB' ]]; then
        ((CURRENT++))
        [[ $CURRENT -ge ${#AGENTS[@]} ]] && CURRENT=0
    elif [[ "$k" == ' ' ]]; then
        if [[ " ${SELECTED[*]} " =~ " ${CURRENT} " ]]; then
            local new=()
            for v in "${SELECTED[@]}"; do [[ "$v" != "$CURRENT" ]] && new+=("$v"); done
            SELECTED=("${new[@]}")
        else
            SELECTED+=("$CURRENT")
        fi
    elif [[ -z "$k" || "$k" == $'\x0a' || "$k" == $'\x0d' ]]; then
        echo ""
        show_cursor
        stty echo 2>/dev/null
        if [[ ${#SELECTED[@]} -gt 0 ]]; then
            install_selected
        else
            echo -e "${YELLOW}Exiting...${NC}"
        fi
        exit 0
    elif [[ "$k" == 'q' || "$k" == 'Q' ]]; then
        echo ""
        echo -e "${YELLOW}Exiting...${NC}"
        exit 0
    fi
done
