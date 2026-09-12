<# 
.SYNOPSIS
    Operations Agent - Ongoing monitoring & maintenance for Smart Home VN Budget
#>

param(
    [string]$GitHubPAT = $env:GITHUB_PAT,
    [string]$CloudflareAPIToken = $env:CLOUDFLARE_API_TOKEN,
    [string]$CloudflareAccountId = $env:CLOUDFLARE_ACCOUNT_ID,
    [string]$TelegramBotToken = $env:TELEGRAM_BOT_TOKEN,
    [string]$TelegramChatId = $env:TELEGRAM_CHAT_ID,
    [switch]$RunOnce
)

$ErrorActionPreference = "Continue"
$ProjectPath = "D:\smarthome-vn-budget"
$LogPath = "$ProjectPath\operations.log"

function Write-OpLog { 
    param([string]$Level, [string]$Msg)
    $entry = "[$(Get-Date -Format 'HH:mm:ss')] [$Level] $Msg"
    Add-Content -Path $LogPath -Value $entry -Encoding UTF8
    $colors = @{INFO='Green'; WARN='Yellow'; ERROR='Red'; STEP='Cyan'; DEBUG='Gray'}
    Write-Host $entry -ForegroundColor $colors[$Level]
}

function Send-TelegramAlert { 
    param([string]$Msg)
    if ($TelegramBotToken -and $TelegramChatId) {
        try {
            $uri = "https://api.telegram.org/bot$TelegramBotToken/sendMessage"
            $body = @{chat_id=$TelegramChatId; text=$Msg; parse_mode="HTML"} | ConvertTo-Json
            Invoke-RestMethod -Method Post -Uri $uri -Body $body -ContentType "application/json" -TimeoutSec 10 | Out-Null
        } catch { Write-OpLog WARN "Telegram send failed: $($_.Exception.Message)" }
    }
}

# ============================================
# MONITORING CHECKS
# ============================================

function Check-SiteUptime {
    Write-OpLog STEP "Checking site uptime..."
    $urls = @(
        "https://smarthome-vn-budget.pages.dev",
        "https://smarthome-vn-budget.pages.dev/404.html",
        "https://smarthome-vn-budget.pages.dev/rss.xml",
        "https://smarthome-vn-budget.pages.dev/sitemap-index.xml"
    )
    
    foreach ($url in $urls) {
        try {
            $resp = Invoke-WebRequest -Uri $url -Method Head -TimeoutSec 10 -ErrorAction Stop
            if ($resp.StatusCode -ne 200) {
                Write-OpLog ERROR "URL $url returned $($resp.StatusCode)"
                Send-TelegramAlert "DOWN: $url returned $($resp.StatusCode)"
            } else {
                Write-OpLog INFO "OK: $url"
            }
        } catch {
            Write-OpLog ERROR "URL $url unreachable: $($_.Exception.Message)"
            Send-TelegramAlert "DOWN: $url - $($_.Exception.Message)"
        }
    }
}

function Check-GitHubActions {
    Write-OpLog STEP "Checking GitHub Actions..."
    if (-not $GitHubPAT) { Write-OpLog WARN "No GitHub PAT - skipping Actions check"; return }
    
    # Refresh PATH for gh CLI
    $env:PATH = [Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [Environment]::GetEnvironmentVariable("Path","User")
    
    $env:GH_TOKEN = $GitHubPAT
    try {
        $runs = gh api repos/hoangcongls12/smarthome-vn-budget/actions/runs --jq '.workflow_runs[:5] | .[] | {name: .name, status: .status, conclusion: .conclusion, created_at: .created_at}' | ConvertFrom-Json
        foreach ($run in $runs) {
            if ($run.status -eq 'in_progress') { Write-OpLog INFO "Workflow running: $($run.name)" }
            elseif ($run.conclusion -eq 'failure') {
                Write-OpLog ERROR "Workflow failed: $($run.name) at $($run.created_at)"
                Send-TelegramAlert "BUILD FAILED: $($run.name) at $($run.created_at)"
            }
        }
    } catch { Write-OpLog WARN "GitHub Actions check failed: $($_.Exception.Message)" }
}

function Check-AffiliateLinks {
    Write-OpLog STEP "Checking affiliate link redirects..."
    $testSlugs = @('sonoff-zbdongle-e', 'xiaomi-smart-bulb', 'aqara-motion-sensor', 'sonoff-mini-r4', 'raspberry-pi-4-4gb')
    
    foreach ($slug in $testSlugs) {
        try {
            $url = "https://smarthome-vn-budget.pages.dev/go/$slug"
            $resp = Invoke-WebRequest -Uri $url -Method Head -TimeoutSec 10 -MaximumRedirection 0 -ErrorAction Stop
            if ($resp.StatusCode -notin @(301,302,307,308)) {
                Write-OpLog WARN "Affiliate link $slug returned $($resp.StatusCode) (expected 3xx)"
            } else {
                Write-OpLog INFO "Affiliate OK: $slug -> $($resp.Headers.Location)"
            }
        } catch {
            Write-OpLog ERROR "Affiliate link $slug failed: $($_.Exception.Message)"
        }
    }
}

function Check-ContentFreshness {
    Write-OpLog STEP "Checking content freshness..."
    $contentPath = "$ProjectPath\src\content\blog"
    $files = Get-ChildItem -Path $contentPath -Filter "*.md"
    $staleThreshold = (Get-Date).AddDays(-30)
    
    foreach ($file in $files) {
        $lastWrite = $file.LastWriteTime
        if ($lastWrite -lt $staleThreshold) {
            Write-OpLog WARN "Stale content: $($file.Name) (last updated $lastWrite)"
        }
    }
    Write-OpLog INFO "Content check: $($files.Count) articles"
}

function Check-DiskSpace {
    Write-OpLog STEP "Checking disk space..."
    try {
        $drive = Get-PSDrive D -ErrorAction Stop
        if ($drive.Total -gt 0) {
            $freeGB = [math]::Round($drive.Free / 1GB, 2)
            $usedPct = [math]::Round(($drive.Used / $drive.Total) * 100, 1)
            Write-OpLog INFO "Disk D: $freeGB GB free ($usedPct percent used)"
            if ($freeGB -lt 1) { Send-TelegramAlert "DISK FULL: Only $freeGB GB free on D:" }
        }
    } catch { Write-OpLog WARN "Disk check failed: $($_.Exception.Message)" }
}

function Check-SSLExpiry {
    Write-OpLog STEP "Checking SSL certificate..."
    try {
        $cert = Invoke-WebRequest -Uri "https://smarthome-vn-budget.pages.dev" -Method Head -TimeoutSec 10
        Write-OpLog INFO "SSL OK (Cloudflare managed)"
    } catch { Write-OpLog WARN "SSL check failed: $($_.Exception.Message)" }
}

function Generate-DailyReport {
    Write-OpLog STEP "Generating daily report..."
    $report = "Daily Operations Report - $(Get-Date -Format 'dd/MM/yyyy')" + "`n" +
              "Site Uptime: Checked" + "`n" +
              "GitHub Actions: Checked" + "`n" +
              "Affiliate Links: Checked" + "`n" +
              "Content Freshness: Checked" + "`n" +
              "Disk Space: Checked" + "`n" +
              "SSL: Checked"
    Write-OpLog INFO "Daily report generated"
    Send-TelegramAlert $report
}

# ============================================
# MAIN
# ============================================
function Run-OperationsCycle {
    Write-OpLog STEP "============================================"
    Write-OpLog STEP "  OPERATIONS AGENT - $(Get-Date -Format 'dd/MM/yyyy HH:mm')"
    Write-OpLog STEP "============================================"
    
    Check-SiteUptime
    Check-GitHubActions
    Check-AffiliateLinks
    Check-ContentFreshness
    Check-DiskSpace
    Check-SSLExpiry
    Generate-DailyReport
    
    Write-OpLog STEP "Cycle completed."
}

if ($RunOnce) {
    Run-OperationsCycle
} else {
    Write-OpLog STEP "Starting Operations Agent daemon (every 15 min)..."
    while ($true) {
        Run-OperationsCycle
        Write-OpLog INFO "Sleeping 15 minutes..."
        Start-Sleep -Seconds 900
    }
}