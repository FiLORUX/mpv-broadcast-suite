# mpv Broadcast Suite Installer - Windows PowerShell
# Installs configuration files and scripts to appropriate mpv directories

$ErrorActionPreference = "Stop"

# ANSI colour codes for PowerShell
$RED = "`e[31m"
$GREEN = "`e[32m"
$YELLOW = "`e[33m"
$BLUE = "`e[34m"
$NC = "`e[0m"

# Determine mpv config directory
$MPV_CONFIG = "$env:APPDATA\mpv"
$SCREENSHOTS_DIR = "$HOME\mpv_screenshots"

Write-Host "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
Write-Host "${BLUE}║       mpv Broadcast Suite Installer (Windows)              ║${NC}"
Write-Host "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
Write-Host ""

# Check if mpv is installed
$mpvPath = Get-Command mpv -ErrorAction SilentlyContinue
if (-not $mpvPath) {
    Write-Host "${YELLOW}Warning: mpv not found in PATH${NC}"
    Write-Host "Please install mpv from: https://mpv.io/installation/"
    Write-Host ""
    $continue = Read-Host "Continue anyway? (y/N)"
    if ($continue -notmatch "^[Yy]$") {
        exit 1
    }
} else {
    $mpvVersion = & mpv --version | Select-String -Pattern "\d+\.\d+\.\d+" | ForEach-Object { $_.Matches.Value } | Select-Object -First 1
    Write-Host "Detected mpv version: ${GREEN}${mpvVersion}${NC}"
    Write-Host ""
}

# Create directories
Write-Host "${BLUE}[1/4]${NC} Creating directories..."
New-Item -ItemType Directory -Force -Path "$MPV_CONFIG\scripts" | Out-Null
New-Item -ItemType Directory -Force -Path "$SCREENSHOTS_DIR" | Out-Null
Write-Host "${GREEN}✓${NC} Directories created"
Write-Host ""

# Backup existing configuration
Write-Host "${BLUE}[2/4]${NC} Checking for existing configuration..."
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$BACKUP_DIR = "$MPV_CONFIG\backup_$timestamp"
$backupNeeded = $false

$filesToCheck = @(
    "mpv.conf",
    "input.conf",
    "scripts\timecode.lua",
    "scripts\audiomap.lua"
)

foreach ($file in $filesToCheck) {
    $fullPath = Join-Path $MPV_CONFIG $file
    if (Test-Path $fullPath) {
        if (-not $backupNeeded) {
            New-Item -ItemType Directory -Force -Path "$BACKUP_DIR\scripts" | Out-Null
            $backupNeeded = $true
        }
        $backupPath = Join-Path $BACKUP_DIR $file
        Copy-Item -Path $fullPath -Destination $backupPath -Force
        Write-Host "${YELLOW}!${NC} Backed up existing: $file"
    }
}

if ($backupNeeded) {
    Write-Host "${GREEN}✓${NC} Backup created at: $BACKUP_DIR"
} else {
    Write-Host "${GREEN}✓${NC} No existing configuration found"
}
Write-Host ""

# Install files
Write-Host "${BLUE}[3/4]${NC} Installing configuration files..."

# Check if we're in the correct directory
if (-not (Test-Path "mpv.conf") -or -not (Test-Path "input.conf")) {
    Write-Host "${RED}Error: Configuration files not found${NC}"
    Write-Host "Please run this script from the mpv-broadcast-suite directory"
    exit 1
}

Copy-Item -Path "mpv.conf" -Destination "$MPV_CONFIG\" -Force
Write-Host "${GREEN}✓${NC} Installed mpv.conf"

Copy-Item -Path "input.conf" -Destination "$MPV_CONFIG\" -Force
Write-Host "${GREEN}✓${NC} Installed input.conf"

Copy-Item -Path "scripts\timecode.lua" -Destination "$MPV_CONFIG\scripts\" -Force
Write-Host "${GREEN}✓${NC} Installed timecode.lua"

Copy-Item -Path "scripts\audiomap.lua" -Destination "$MPV_CONFIG\scripts\" -Force
Write-Host "${GREEN}✓${NC} Installed audiomap.lua"
Write-Host ""

# Verify installation
Write-Host "${BLUE}[4/4]${NC} Verifying installation..."
$allGood = $true

foreach ($file in $filesToCheck) {
    $fullPath = Join-Path $MPV_CONFIG $file
    if (-not (Test-Path $fullPath)) {
        Write-Host "${RED}✗${NC} Missing: $file"
        $allGood = $false
    }
}

if ($allGood) {
    Write-Host "${GREEN}✓${NC} All files installed successfully"
} else {
    Write-Host "${RED}✗${NC} Some files failed to install"
    exit 1
}
Write-Host ""

# Installation complete
Write-Host "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
Write-Host "${GREEN}║           Installation Complete!                           ║${NC}"
Write-Host "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
Write-Host ""
Write-Host "Configuration installed to: ${BLUE}$MPV_CONFIG${NC}"
Write-Host "Screenshots will be saved to: ${BLUE}$SCREENSHOTS_DIR${NC}"
Write-Host ""
Write-Host "Quick Start:"
Write-Host "  1. Launch mpv with any video file: mpv your_video.mp4"
Write-Host "  2. Press 't' to toggle timecode display"
Write-Host "  3. Press 'F1' for keyboard shortcuts"
Write-Host "  4. Press 'Ctrl+i' for audio information"
Write-Host ""
Write-Host "Documentation: https://github.com/yourusername/mpv-broadcast-suite"
Write-Host ""

