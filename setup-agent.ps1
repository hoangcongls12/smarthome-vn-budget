<# 
.SYNOPSIS
    Setup Agent - Fully automates Cloudflare Pages project creation & GitHub secrets
#>

param(
    [string]$GitHubPAT = $env:GITHUB_PAT,
    [string]$CloudflareAPIToken = $env:CLOUDFLARE_API_TOKEN,
    [string]$CloudflareAccountId = $env:CLOUDFLARE_ACCOUNT_ID,
    [string]$ProjectName = "smarthome-vn-budget",
    [string]$GitHubUser = "hoangcongls12",
    [string]$GitHubRepo = "smarthome-vn-budget",
    [string]$ProductionBranch = "main",
    [string]$BuildCommand = "npm run build",
    [string]$OutputDir = "dist"
)

$ErrorActionPreference = "Stop"
$ProjectPath = "D:\smarthome-vn-budget"

function Write-Log { param([string]$Level, [string]$Msg) 
    $entry = "[$(Get-Date -Format 'HH:mm:ss')] [$Level] $Msg"
    Add-Content -Path "$ProjectPath\setup-agent.log" -Value $entry -Encoding UTF8
    $colors = @{INFO='Green'; WARN='Yellow'; ERROR='Red'; STEP='Cyan'; SUCCESS='Magenta'}
    Write-Host $entry -ForegroundColor $colors[$Level]
}

# Validation
$missing = @()
if (-not $GitHubPAT) { $missing += "GitHub PAT" }
if (-not $CloudflareAPIToken) { $missing += "Cloudflare API Token" }
if (-not $CloudflareAccountId) { $missing += "Cloudflare Account ID" }

if ($missing.Count -gt 0) {
    Write-Log ERROR "Missing required parameters:"
    $missing | ForEach-Object { Write-Log ERROR "  - $_" }
    Write-Log INFO "Set via environment variables:"
    Write-Log INFO '  $env:CLOUDFLARE_API_TOKEN="your_token"'
    Write-Log INFO '  $env:CLOUDFLARE_ACCOUNT_ID="your_account_id"'
    exit 1
}

$env:GH_TOKEN = $GitHubPAT
$cfHeaders = @{Authorization = "Bearer $CloudflareAPIToken"; "Content-Type" = "application/json"}

# ============================================
# STEP 1: SET GITHUB SECRETS
# ============================================
Write-Log STEP "Step 1/5: Setting GitHub Secrets..."

$secrets = @{
    "CLOUDFLARE_API_TOKEN" = $CloudflareAPIToken
    "CLOUDFLARE_ACCOUNT_ID" = $CloudflareAccountId
    "GITHUB_PAT" = $GitHubPAT
}

foreach ($secret in $secrets.GetEnumerator()) {
    $name = $secret.Key
    $value = $secret.Value
    Write-Log INFO ("Setting secret: " + $name)
    try {
        $pubKey = gh api repos/hoangcongls12/smarthome-vn-budget/actions/secrets/public-key --jq '{key: .key, key_id: .key_id}'
        $keyId = $pubKey.key_id
        $encrypted = gh api --method PUT "repos/hoangcongls12/smarthome-vn-budget/actions/secrets/$name" -f encrypted_value="$value" -f key_id="$keyId" 2>&1
        Write-Log SUCCESS ("Secret " + $name + " configured")
    } catch {
        Write-Log WARN ("Secret " + $name + " failed, set manually in GitHub Settings > Secrets > Actions")
    }
}

# ============================================
# STEP 2: CREATE CLOUDFLARE PAGES PROJECT
# ============================================
Write-Log STEP "Step 2/5: Creating Cloudflare Pages Project..."

$projectBody = @{
    name = "smarthome-vn-budget"
    production_branch = "main"
    build_config = @{
        build_command = "npm run build"
        destination_dir = "dist"
        root_dir = ""
    }
    deployment_configs = @{}
} | ConvertTo-Json -Depth 4

try {
    $resp = Invoke-RestMethod -Method Post -Uri "https://api.cloudflare.com/client/v4/accounts/$CloudflareAccountId/pages/projects" -Headers @{Authorization = "Bearer $CloudflareAPIToken"; "Content-Type" = "application/json"} -Body $projectBody -ErrorAction Stop
    
    if ($resp.success) {
        Write-Log SUCCESS ("Pages project created: " + $resp.result.name)
        $projectId = $resp.result.id
    } elseif ($resp.errors[0].code -eq 10000) {
        Write-Log WARN "Project already exists, getting ID..."
        $existing = Invoke-RestMethod -Method Get -Uri "https://api.cloudflare.com/client/v4/accounts/$CloudflareAccountId/pages/projects/smarthome-vn-budget" -Headers @{Authorization = "Bearer $CloudflareAPIToken"}
        $projectId = $existing.result.id
        Write-Log INFO ("Using existing project ID: " + $projectId)
    } else {
        Write-Log ERROR ("Create failed: " + ($resp.errors | ConvertTo-Json))
        exit 1
    }
} catch {
    Write-Log ERROR ("API Error: " + $_.Exception.Message)
    exit 1
}

# ============================================
# STEP 3: CONFIGURE BUILD SETTINGS
# ============================================
Write-Log STEP "Step 3/5: Configuring build settings..."

$configBody = @{
    build_config = @{
        build_command = "npm run build"
        destination_dir = "dist"
        root_dir = ""
    }
    production_branch = "main"
} | ConvertTo-Json -Depth 4

try {
    $resp = Invoke-RestMethod -Method Put -Uri "https://api.cloudflare.com/client/v4/accounts/$CloudflareAccountId/pages/projects/$projectId" -Headers @{Authorization = "Bearer $CloudflareAPIToken"; "Content-Type" = "application/json"} -Body $configBody -ErrorAction Stop
    if ($resp.success) { Write-Log SUCCESS "Build config updated" }
} catch { Write-Log WARN ("Config update failed: " + $_.Exception.Message) }

# ============================================
# STEP 4: TRIGGER INITIAL DEPLOYMENT
# ============================================
Write-Log STEP "Step 4/5: Triggering initial deployment..."

try {
    $deploy = Invoke-RestMethod -Method Post -Uri "https://api.cloudflare.com/client/v4/accounts/$CloudflareAccountId/pages/projects/$projectId/deployments" -Headers @{Authorization = "Bearer $CloudflareAPIToken"; "Content-Type" = "application/json"} -Body @{branch="main"} | ConvertTo-Json -Depth 2 -ErrorAction Stop
    if ($deploy.success) {
        $deploymentId = $deploy.result.id
        Write-Log SUCCESS ("Deployment triggered: " + $deploymentId)
        Write-Log SUCCESS "Live URL (after build): https://smarthome-vn-budget.pages.dev"
    }
} catch { Write-Log WARN ("Deploy trigger failed: " + $_.Exception.Message) }

# ============================================
# STEP 5: VERIFY DEPLOYMENT
# ============================================
Write-Log STEP "Step 5/5: Verifying deployment..."

$maxWait = 300
$startTime = Get-Date

Write-Log INFO "Waiting for deployment to complete (max 5 min)..."

do {
    Start-Sleep 15
    try {
        $deploys = Invoke-RestMethod -Method Get -Uri "https://api.cloudflare.com/client/v4/accounts/$CloudflareAccountId/pages/projects/$projectId/deployments" -Headers @{Authorization = "Bearer $CloudflareAPIToken"}
        $latest = $deploys.result | Sort-Object created_on -Descending | Select-Object -First 1
        $status = $latest.status
        
        $elapsed = [math]::Round(((Get-Date) - $startTime).TotalMinutes, 1)
        Write-Log INFO ("Deploy status: " + $status + " (" + $elapsed + "min elapsed)")
        
        if ($status -eq "success") {
            Write-Log SUCCESS "============================================"
            Write-Log SUCCESS "  DEPLOYMENT SUCCESSFUL!"
            Write-Log SUCCESS "============================================"
            Write-Log SUCCESS "Live URL: https://smarthome-vn-budget.pages.dev"
            Write-Log SUCCESS "Custom domain can be added in Cloudflare Pages dashboard"
            exit 0
        } elseif ($status -in @("failed", "cancelled")) {
            Write-Log ERROR ("Deployment " + $status + ": " + $latest.error_message)
            exit 1
        }
    } catch { Write-Log WARN ("Status check: " + $_.Exception.Message) }
    
} while ((Get-Date) - $startTime).TotalSeconds -lt 300

Write-Log WARN "Timeout waiting for deployment. Check Cloudflare dashboard."
Write-Log INFO ("URL: https://dash.cloudflare.com/pages/$projectId")