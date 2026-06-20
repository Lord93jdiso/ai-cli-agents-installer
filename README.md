# AI CLI Agents Installer

Interactive CLI installer for AI coding agents. Supports macOS, Linux, and Windows.

## Features

- Compact scrollable menu with multi-select support
- Automatic Node.js installation when missing
- Shows installed / not installed status per agent
- Shows run commands (`$ binary`) after installation
- Navigation: ↑↓ move, `Space` select, `Enter` install, `q` quit

## Supported Agents

| Agent | Install Command | Binary |
|-------|----------------|--------|
| OpenCode | `npm install -g opencode-ai` | `opencode` |
| Claude Code | `npm install -g @anthropic-ai/claude-code` | `claude` |
| Gemini CLI | `npm install -g @google/gemini-cli` | `gemini` |
| Codex CLI | `npm install -g @openai/codex` | `codex` |
| GitHub Copilot CLI | `npm install -g @github/copilot` | `copilot` |
| Aider | `npm install -g aider` | `aider` |
| Qwen Code | `npm install -g @qwen-code/qwen-code` | `qwen` |
| Crush | `npm install -g @charmland/crush` | `crush` |
| Cline CLI | `npm install -g cline` | `cline` |
| Kilo Code CLI | `npm install -g @kilocode/cli` | `kilo` |
| Antigravity CLI | `curl -fsSL https://antigravity.google/cli/install.ps1 \| pwsh` | `agy` |
| Grok Build | `curl -fsSL https://x.ai/cli/install.ps1 \| pwsh` | `grok` |
| Kimi Code | `npm install -g @moonshot-ai/kimi-code` | `kimi` |
| Pi | `npm install -g @earendil-works/pi-coding-agent` | `pi` |
| MiMo Code | `npm install -g @mimo-ai/cli` | `mimo` |
| Codebuff | `npm install -g codebuff` | `codebuff` |
| Amp Code | `curl -fsSL https://ampcode.com/install.ps1 \| pwsh` | `amp` |

## Install

### macOS / Linux

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/<user>/ai-cli-agents-installer/main/install-ai-agents.sh)
```

Or manually:

```bash
chmod +x install-ai-agents.sh
./install-ai-agents.sh
```

### Windows (PowerShell 7+)

```powershell
pwsh -c "iwr -Uri https://raw.githubusercontent.com/<user>/ai-cli-agents-installer/main/install-ai-agents.ps1 -OutFile install-ai-agents.ps1; .\install-ai-agents.ps1"
```

Or manually:

```powershell
pwsh ./install-ai-agents.ps1
```

> **Note:** If `pwsh` is not available, install PowerShell 7 from [aka.ms/ps](https://aka.ms/ps).

## Usage

1. Run the script
2. Use ↑/↓ to navigate the list
3. Press `Space` to select agents (multi-select supported)
4. Press `Enter` to install selected agents
5. Run commands are shown after installation (`$ binary`)
6. Run `source ~/.zshrc` (or `~/.bashrc`) if prompted

## Structure

```
ai-cli-agents-installer/
├── install-ai-agents.sh     # macOS / Linux
├── install-ai-agents.ps1    # Windows (PowerShell 7+)
└── README.md
```

## Requirements

- **macOS/Linux**: Bash 4+, curl
- **Windows**: PowerShell 7+ (pwsh)

Node.js is installed automatically if missing.

## License

MIT
