<#
.SYNOPSIS
    AI CLI Agents Installer for Windows
    Node.js installation + interactive CLI AI agent selection menu
#>

#Requires -Version 5.1

$ErrorActionPreference = "Stop"

# ─── Colors / Console helpers ────────────────────────────────────────────
$Host.UI.RawUI.ForegroundColor = [ConsoleColor]::White

function Write-Info($m)    { Write-Host "[INFO] $m" -ForegroundColor Cyan }
function Write-Success($m) { Write-Host "$m" -ForegroundColor Green }
function Write-Warn($m)    { Write-Host "$m" -ForegroundColor Yellow }
function Write-Err($m)     { Write-Host "$m" -ForegroundColor Red }

# ─── Agents ───────────────────────────────────────────────────────────────
$Agents = @(
    , ('OpenCode',           'npm', 'opencode-ai',              'opencode')
    , ('Claude Code',        'npm', '@anthropic-ai/claude-code','claude')
    , ('Gemini CLI',         'npm', '@google/gemini-cli',       'gemini')
    , ('Codex CLI',          'npm', '@openai/codex',            'codex')
    , ('GitHub Copilot CLI', 'npm', '@github/copilot',          'copilot')
    , ('Aider',              'npm', 'aider',                    'aider')
    , ('Qwen Code',          'npm', '@qwen-code/qwen-code',     'qwen')
    , ('Crush',              'npm', '@charmland/crush',         'crush')
    , ('Cline CLI',          'npm', 'cline',                    'cline')
    , ('Kilo Code CLI',      'npm', '@kilocode/cli',            'kilo')
    , ('Antigravity CLI',    'ps1', 'https://antigravity.google/cli/install.ps1', 'agy')
    , ('Grok Build',         'ps1', 'https://x.ai/cli/install.ps1',                'grok')
    , ('Kimi Code',          'npm', '@moonshot-ai/kimi-code',   'kimi')
    , ('Pi',                 'npm', '@earendil-works/pi-coding-agent',  'pi')
    , ('MiMo Code',          'npm', '@mimo-ai/cli',             'mimo')
    , ('Codebuff',           'npm', 'codebuff',                 'codebuff')
    , ('Amp Code',           'ps1', 'https://ampcode.com/install.ps1',               'amp')
)

$selected = @()
$current = 0
$viewport = 5

# ─── Node.js ──────────────────────────────────────────────────────────────
function Check-Node {
    $node = Get-Command node -ErrorAction SilentlyContinue
    if ($node) {
        $ver = node --version
        Write-Success "✓ Node.js $ver already installed"
        return $true
    }
    return $false
}

function Install-Node {
    Write-Info "Installing Node.js..."

    if (Get-Command winget -ErrorAction SilentlyContinue) {
        try {
            winget install --id OpenJS.NodeJS.LTS --source winget --accept-source-agreements --accept-package-agreements 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq -1978335189) { return }
        } catch {}
    }

    if (Get-Command choco -ErrorAction SilentlyContinue) {
        try { choco install nodejs-lts -y 2>&1 | Out-Null; return } catch {}
    }

    if (Get-Command scoop -ErrorAction SilentlyContinue) {
        try { scoop install nodejs-lts 2>&1 | Out-Null; return } catch {}
    }

    Write-Info "Downloading Node.js installer..."
    $url = "https://nodejs.org/dist/latest/node-v22.14.0-x64.msi"
    $msi = "$env:TEMP\node-installer.msi"
    try {
        Invoke-WebRequest -Uri $url -OutFile $msi -UseBasicParsing
        Write-Info "Starting installation..."
        Start-Process msiexec -ArgumentList "/i", "`"$msi`"", "/qn", "/norestart" -Wait -NoNewWindow
        Remove-Item $msi -Force -ErrorAction SilentlyContinue
    } catch {
        Write-Err "Node.js installation failed: $_"
        exit 1
    }
}

function Ensure-Node {
    Write-Host "╔" -NoNewline; Write-Host "══════════════════════════════════════════════════" -NoNewline; Write-Host "╗"
    Write-Host "║" -NoNewline;     Write-Host "          Checking Node.js                       " -NoNewline; Write-Host "║"
    Write-Host "╚" -NoNewline; Write-Host "══════════════════════════════════════════════════" -NoNewline; Write-Host "╝"
    Write-Host ""

    if (-not (Check-Node)) {
        Write-Warn "Node.js not found. Installing..."
        Write-Host ""
        Install-Node
        $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
        if (Check-Node) {
            Write-Success "✓ Node.js installed successfully"
        } else {
            Write-Err "Node.js installation failed"
            exit 1
        }
    }
    Start-Sleep -Milliseconds 500
}

# ─── Compact Menu ─────────────────────────────────────────────────────────
function Get-ScrollOffset {
    return $script:scrollOffset
}

function Update-ScrollOffset {
    $total = $Agents.Count
    $maxOffset = [Math]::Max(0, $total - $viewport)
    if ($current -lt $script:scrollOffset) {
        $script:scrollOffset = $current
    }
    if ($current -ge ($script:scrollOffset + $viewport)) {
        $script:scrollOffset = $current - $viewport + 1
    }
    if ($script:scrollOffset -gt $maxOffset) { $script:scrollOffset = $maxOffset }
    if ($script:scrollOffset -lt 0) { $script:scrollOffset = 0 }
}

function Draw-Menu {
    $total = $Agents.Count
    $offset = Get-ScrollOffset
    $end = $offset + $viewport
    if ($end -gt $total) { $end = $total }

    $out = ""

    $out += " ${bold}AI CLI Agents Installer${reset}${esc}[K`n"
    $out += "${esc}[K`n"

    for ($i = $offset; $i -lt $end; $i++) {
        $name, $type, $data, $binary = $Agents[$i]

        $installed = Get-Command $binary -ErrorAction SilentlyContinue
        $statusText = if ($installed) { 'installed' } else { 'not installed' }
        $sc = if ($installed) { $green } else { $red }

        $check = ' '
        if ($selected -contains $i) { $check = '●' }

        if ($i -eq $current) {
            $out += " $blue▸${reset} [$check] $name $sc$statusText${reset}${esc}[K`n"
        } else {
            $out += "  [$check] $name $sc$statusText${reset}${esc}[K`n"
        }
        $out += "${esc}[K`n"
    }

    $remaining = $total - $end
    $above = $offset
    if ($above -gt 0 -or $remaining -gt 0) {
        $out += " ${yellow}↑$above ↓$remaining${reset}${esc}[K`n"
    } else {
        $out += "${esc}[K`n"
    }

    $out += " ${bold}↑/↓${reset} ${bold}Space${reset} sel ${bold}Enter${reset} inst ${bold}q${reset} quit${esc}[K"
    [Console]::Write($out)
}

function Install-Selected {
    if ($selected.Count -eq 0) {
        Write-Warn "Nothing selected."
        return
    }

    $installed = @()

    Write-Host ""
    Write-Host "Installing selected agents:"
    Write-Host ""

    foreach ($idx in $selected) {
        $name, $type, $data, $binary = $Agents[$idx]
        Write-Info "→ Installing $name..."

        $ok = $false
        if ($type -eq 'npm') {
            npm install -g $data 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Success "  ✓ $name installed"
                $ok = $true
            } else {
                Write-Err "  ✗ Error installing $name"
            }
        } elseif ($type -eq 'ps1') {
            try {
                iex "& { $(irm $data) }" 2>&1 | Out-Null
                if ($LASTEXITCODE -eq 0 -or -not $LASTEXITCODE) {
                    Write-Success "  ✓ $name installed"
                    $ok = $true
                } else {
                    Write-Err "  ✗ Error installing $name"
                }
            } catch {
                Write-Err "  ✗ Error installing $($name): $_"
            }
        }
        if ($ok) {
            $installed += @{ binary = $binary; name = $name }
        }
        Write-Host ""
    }

    Write-Host ""
    Write-Success "Installation complete!"
    Write-Warn "Restart the terminal or open a new console."

    if ($installed.Count -gt 0) {
        Write-Host ""
        Write-Host "Run commands:"
        foreach ($a in $installed) {
            Write-Host "  $ $($a.binary)" -ForegroundColor Cyan
        }
    }

    Write-Host ""
    Write-Host "Press Enter to exit..." -NoNewline
    $null = Read-Host
}

# ─── Main ─────────────────────────────────────────────────────────────────
Clear-Host
Ensure-Node

$menuHeight = 4 + $viewport * 2
$esc = [char]27
$bold = "${esc}[1m"
$reset = "${esc}[0m"
$green = "${esc}[32m"
$red = "${esc}[31m"
$blue = "${esc}[34m"
$yellow = "${esc}[33m"
$script:scrollOffset = 0
$script:menuStartRow = -1
$first = $true

[Console]::CursorVisible = $false

do {
    if ($first) {
        $script:menuStartRow = [Console]::CursorTop
        Draw-Menu
        $first = $false
    } else {
        [Console]::SetCursorPosition(0, $script:menuStartRow)
        Draw-Menu
    }

    $key = [Console]::ReadKey($true)
    $k = $key.Key

    switch ($k) {
        ([ConsoleKey]::UpArrow) {
            $current--
            if ($current -lt 0) { $current = $Agents.Count - 1 }
            Update-ScrollOffset
        }
        ([ConsoleKey]::DownArrow) {
            $current++
            if ($current -ge $Agents.Count) { $current = 0 }
            Update-ScrollOffset
        }
        ([ConsoleKey]::Spacebar) {
            if ($selected -contains $current) {
                $selected = $selected | Where-Object { $_ -ne $current }
            } else {
                $selected += $current
            }
        }
        ([ConsoleKey]::Enter) {
            Write-Host ""
            if ($selected.Count -gt 0) {
                Install-Selected
            } else {
                Write-Warn "Exiting..."
            }
            break
        }
        ([ConsoleKey]::Q) {
            Write-Host ""
            Write-Warn "Exiting..."
            break
        }
    }
} while ($k -ne [ConsoleKey]::Enter -and $k -ne [ConsoleKey]::Q)

[Console]::CursorVisible = $true
$Host.UI.RawUI.ForegroundColor = [ConsoleColor]::White
