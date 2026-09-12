<# 
.SYNOPSIS
    Smart Home VN Budget - Automated Deployment Script
.DESCRIPTION
    This script automates the deployment of Smart Home VN Budget to GitHub and Cloudflare Pages.
    Run this script in PowerShell as Administrator for best results.
.NOTES
    Author: AI Assistant
    Project: Smart Home VN Budget
#>

param(
    [string]$GitHubUsername = "",
    [string]$RepoName = "smarthome-vn-budget",
    [switch]$SkipGitInstall,
    [switch]$SkipCloudflare
)

$ErrorActionPreference = "Stop"
$ProjectPath = "D:\smarthome-vn-budget"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Smart Home VN Budget - Auto Deploy" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# ============================================
# Helper Functions
# ============================================
function Write-Step { param([string]$msg) Write-Host "`n[STEP] $msg" -ForegroundColor Yellow }
function Write-Success { param([string]$msg) Write-Host "[OK] $msg" -ForegroundColor Green }
function Write-Error { param([string]$msg) Write-Host "[ERROR] $msg" -ForegroundColor Red }
function Write-Info { param([string]$msg) Write-Host "[INFO] $msg" -ForegroundColor Gray }

function Check-Command {
    param([string]$Name, [string]$DownloadUrl = "")
    $path = Get-Command $Name -ErrorAction SilentlyContinue
    if ($path) {
        Write-Success "$Name found: $($path.Source)"
        return $true
    } else {
        Write-Error "$Name not found"
        if ($DownloadUrl) {
            Write-Info "Download from: $DownloadUrl"
        }
        return $false
    }
}

function Install-WithWinget {
    param([string]$PackageId, [string]$Name)
    Write-Step "Installing $Name via winget..."
    try {
        winget install --id $PackageId --accept-source-agreements --accept-package-agreements -q
        Write-Success "$Name installed"
        return $true
    } catch {
        Write-Error "Failed to install $Name"
        return $false
    }
}

# ============================================
# Step 1: Check/Install Prerequisites
# ============================================
Write-Step "Checking prerequisites..."

$hasGit = Check-Command "git" "https://git-scm.com/download/win"
$hasGh = Check-Command "gh" "https://cli.github.com/"
$hasNode = Check-Command "node" "https://nodejs.org/"
$hasNpm = Check-Command "npm"
$hasWinget = Check-Command "winget"

if (-not $hasGit -and -not $SkipGitInstall) {
    if ($hasWinget) {
        Install-WithWinget "Git.Git" "Git"
        $hasGit = Check-Command "git"
    } else {
        Write-Error "Git not found and winget not available. Please install Git manually from https://git-scm.com/download/win"
        exit 1
    }
}

if (-not $hasNode) {
    if ($hasWinget) {
        Install-WithWinget "OpenJS.NodeJS.LTS" "Node.js LTS"
        $hasNode = Check-Command "node"
        $hasNpm = Check-Command "npm"
    } else {
        Write-Error "Node.js not found. Please install from https://nodejs.org/"
        exit 1
    }
}

if (-not $hasGh -and $hasWinget) {
    Install-WithWinget "GitHub.cli" "GitHub CLI"
    $hasGh = Check-Command "gh"
}

# Refresh PATH
$env:PATH = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# ============================================
# Step 2: Initialize Git Repository
# ============================================
Write-Step "Initializing Git repository..."
Set-Location $ProjectPath

if (-not (Test-Path ".git")) {
    git init
    Write-Success "Git repository initialized"
} else {
    Write-Info "Git repository already exists"
}

# Create .gitignore if not exists
if (-not (Test-Path ".gitignore")) {
    @"
node_modules
dist
.build
.env
.env.local
.env.production
.DS_Store
*.log
.vercel
.netlify
.wrangler
coverage
*.local
"@ | Set-Content -Encoding UTF8 .gitignore
    Write-Success ".gitignore created"
}

# Add and commit
git add .
$commitMsg = "feat: initial release - Smart Home VN Budget`n`n- Astro 4.x + Tailwind CSS static site`n- 3 pilot articles (Budget Build, Sonoff Dongle, Smart Bulb comparison)`n- Affiliate system with link cloaking`n- Sitemap, RSS, PWA ready`n- Cloudflare Pages deployment ready"
git commit -m $commitMsg
Write-Success "Initial commit created"

# ============================================
# Step 3: Create GitHub Repository
# ============================================
if ($hasGh) {
    Write-Step "Creating GitHub repository..."
    
    if (-not $GitHubUsername) {
        $GitHubUsername = (gh api user --jq .login 2>$null)
        if (-not $GitHubUsername) {
            Write-Info "Please authenticate with GitHub CLI first:"
            Write-Info "  gh auth login"
            $GitHubUsername = Read-Host "Enter your GitHub username"
        }
    }
    
    if ($GitHubUsername) {
        try {
            gh repo create $RepoName --public --source=. --remote=origin --push
            Write-Success "Repository created and pushed: https://github.com/$GitHubUsername/$RepoName"
        } catch {
            Write-Error "Failed to create repo. Trying alternative..."
            git remote add origin "https://github.com/$GitHubUsername/$RepoName.git" 2>$null
            git push -u origin main
        }
    }
} else {
    Write-Info "GitHub CLI not available. Manual steps:"
    Write-Info "1. Go to https://github.com/new"
    Write-Info "2. Create repository: $RepoName"
    Write-Info "3. Run these commands:"
    Write-Info "   git remote add origin https://github.com/YOUR_USERNAME/$RepoName.git"
    Write-Info "   git push -u origin main"
}

# ============================================
# Step 4: Cloudflare Pages Deployment Guide
# ============================================
if (-not $SkipCloudflare) {
    Write-Step "Cloudflare Pages Deployment Guide"
    Write-Info "============================================"
    Write-Info "1. Go to: https://dash.cloudflare.com/pages"
    Write-Info "2. Click 'Create a project' > 'Connect to Git'"
    Write-Info "3. Select your GitHub repo: $RepoName"
    Write-Info "4. Configure build settings:"
    Write-Info "   - Build command: npm run build"
    Write-Info "   - Output directory: dist"
    Write-Info "   - Node version: 18 (or 20)"
    Write-Info "5. Add Environment Variables (Settings > Environment variables):"
    
    $envVars = @(
        @{Name="GA4_MEASUREMENT_ID"; Value="G-XXXXXXXXXX (from Google Analytics)"},
        @{Name="UMAMI_WEBSITE_ID"; Value="your-umami-website-id"},
        @{Name="UMAMI_SCRIPT_URL"; Value="https://analytics.yourdomain.com/script.js"},
        @{Name="SHOPEE_AFFILIATE_ID"; Value="your-shopee-affiliate-id"},
        @{Name="LAZADA_AFFILIATE_ID"; Value="your-lazada-affiliate-id"},
        @{Name="AMAZON_ASSOCIATES_TAG"; Value="your-amazon-tag"},
        @{Name="GEARVN_REF"; Value="your-gearvn-ref"},
        @{Name="ANPHUOC_REF"; Value="your-anphuoc-ref"},
        @{Name="ALIEXPRESS_AFF_FID"; Value="your-aliexpress-fid"}
    )
    
    $envVars | ForEach-Object {
        Write-Info "   - $($_.Name) = $($_.Value)"
    }
    
    Write-Info "6. Click 'Save and Deploy'"
    Write-Info "7. Your site will be live at: https://$RepoName.pages.dev"
    Write-Info ""
    Write-Info "Optional: Add custom domain in Pages > Custom domains"
}

# ============================================
# Step 5: Post-Deploy Checklist
# ============================================
Write-Step "Post-Deploy Checklist"
$checklist = @(
    "Verify site loads at https://$RepoName.pages.dev",
    "Submit sitemap to Google Search Console",
    "Setup GA4 and verify tracking",
    "Test affiliate links (/go/slug redirects)",
    "Register affiliate programs and update IDs",
    "Write actual content for 3 pilot articles (fix encoding)",
    "Setup Notion workspace",
    "Setup Umami analytics (Cloudflare Workers)"
)

$i = 1
$checklist | ForEach-Object {
    Write-Host "  [$i] $_" -ForegroundColor Gray
    $i++
}

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "  DEPLOYMENT PREPARATION COMPLETE!" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Project location: $ProjectPath" -ForegroundColor Green
Write-Host "GitHub repo: https://github.com/$GitHubUsername/$RepoName" -ForegroundColor Green
Write-Host "Live URL (after deploy): https://$RepoName.pages.dev" -ForegroundColor Green
Write-Host ""
Write-Host "Next: Run the Cloudflare Pages steps above, then start Sprint 2!" -ForegroundColor Yellow

# ============================================
# Step 6: Open relevant URLs
# ============================================
Write-Step "Opening helpful URLs..."
Start-Process "https://github.com/new"
Start-Process "https://dash.cloudflare.com/pages"
Start-Process "https://analytics.google.com"
Start-Process "https://github.com/cli/cli#installation"

Write-Host "`nDone! Check your browser for opened tabs." -ForegroundColor Green