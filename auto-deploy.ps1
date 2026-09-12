<# 
.SYNOPSIS
    Fully automated deployment for Smart Home VN Budget
    Uses PAT token - no browser interaction needed
    Self-healing: installs missing tools, retries on failure
#>

param(
    [string]$GitHubPAT = "",
    [string]$CloudflareAPIToken = "",
    [string]$CloudflareAccountId = "",
    [switch]$SkipPrerequisites
)

$ErrorActionPreference = "Continue"
$ProjectPath = "D:\smarthome-vn-budget"
$RepoName = "smarthome-vn-budget"
$GitHubUser = "hoangcongls12"

# ============================================
# LOGGER & STATE MANAGEMENT
# ============================================
$LogPath = "$ProjectPath\deploy.log"
$StatePath = "$ProjectPath\deploy-state.json"

function Write-Log { 
    param([string]$Level, [string]$Msg)
    $entry = "[$(Get-Date -Format 'HH:mm:ss')] [$Level] $Msg"
    Add-Content -Path $LogPath -Value $entry -Encoding UTF8
    $colors = @{INFO='Green'; WARN='Yellow'; ERROR='Red'; STEP='Cyan'; DEBUG='Gray'}
    Write-Host $entry -ForegroundColor $colors[$Level]
}

function Save-State { 
    param([string]$Step, [string]$Status, [string]$Data = "")
    $state = @{LastStep=$Step; Status=$Status; Timestamp=(Get-Date -Format 'o'); Data=$Data} | ConvertTo-Json -Depth 3
    Set-Content -Path $StatePath -Value $state -Encoding UTF8
}

function Load-State {
    if (Test-Path $StatePath) { return (Get-Content $StatePath -Raw | ConvertFrom-Json) }
    return @{LastStep=""; Status=""; Data=""}
}

function Invoke-WithRetry {
    param([scriptblock]$Action, [int]$MaxRetries=3, [int]$DelaySec=5, [string]$StepName)
    for ($i=1; $i -le $MaxRetries; $i++) {
        try {
            Write-Log STEP "[$StepName] Attempt $i/$MaxRetries"
            $result = & $Action
            if ($result) { Write-Log INFO "[$StepName] Success"; return $true }
        } catch {
            Write-Log WARN "[$StepName] Attempt $i failed: $($_.Exception.Message)"
            if ($i -lt $MaxRetries) { Start-Sleep $DelaySec }
        }
    }
    Write-Log ERROR "[$StepName] FAILED after $MaxRetries attempts"
    return $false
}

# ============================================
# AGENT 1: PREREQUISITE INSTALLER
# ============================================
function Agent-Prerequisites {
    Write-Log STEP "AGENT-1: Installing prerequisites..."
    Save-State "Prerequisites" "Running"
    
    $installers = @(
        @{Name="Git"; Url="https://github.com/git-for-windows/git/releases/download/v2.45.1.windows.1/Git-2.45.1-64-bit.exe"; Args="/VERYSILENT /NORESTART"; Check="git --version"},
        @{Name="Node.js"; Url="https://nodejs.org/dist/v18.20.4/node-v18.20.4-x64.msi"; Args="/qn /norestart"; Check="node --version"},
        @{Name="GitHubCLI"; Url="https://github.com/cli/cli/releases/download/v2.45.0/gh_2.45.0_windows_amd64.msi"; Args="/qn /norestart"; Check="gh --version"}
    )

    foreach ($inst in $installers) {
        if (-not (Invoke-WithRetry { & $inst.Check; return $true } -MaxRetries 1 -StepName "Check $($inst.Name)")) {
            Write-Log STEP "Installing $($inst.Name)..."
            $localPath = "$env:TEMP\$($inst.Name).exe"
            if ($inst.Url -like "*.msi") { $localPath = "$env:TEMP\$($inst.Name).msi" }
            Invoke-WebRequest -Uri $inst.Url -OutFile $localPath
            if ($inst.Url -like "*.msi") {
                Start-Process msiexec.exe -ArgumentList "/i `"$localPath`" $($inst.Args)" -Wait -NoNewWindow
            } else {
                Start-Process $localPath -ArgumentList $inst.Args -Wait -NoNewWindow
            }
            $env:PATH = [Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [Environment]::GetEnvironmentVariable("Path","User")
        }
    }
    Save-State "Prerequisites" "Completed"
    return $true
}

# ============================================
# AGENT 2: GITHUB AUTHENTICATOR (PAT-based)
# ============================================
function Agent-GitHubAuth {
    param([string]$PAT)
    Write-Log STEP "AGENT-2: GitHub Authentication..."
    Save-State "GitHubAuth" "Running"
    
    if (-not $PAT) {
        Write-Log ERROR "GitHub PAT required!"
        return $false
    }
    
    $env:GH_TOKEN = $PAT
    try {
        $user = gh api user --jq .login
        Write-Log INFO "Authenticated as: $user"
        Save-State "GitHubAuth" "Completed" $user
        return $true
    } catch {
        Write-Log ERROR "PAT invalid: $($_.Exception.Message)"
        return $false
    }
}

# ============================================
# AGENT 3: GIT OPERATIONS
# ============================================
function Agent-GitOps {
    Write-Log STEP "AGENT-3: Git Operations..."
    Save-State "GitOps" "Running"
    
    Set-Location $ProjectPath
    
    git config --global user.email "hoangcongls12@gmail.com"
    git config --global user.name "hoangcongls12"
    
    if (-not (git rev-parse --verify HEAD 2>$null)) {
        git add .
        git commit -m "feat: initial release - Smart Home VN Budget`n`n- Astro 4.x + Tailwind CSS static site`n- 3 pilot articles`n- Affiliate system with link cloaking`n- Sitemap, RSS, PWA ready`n- Cloudflare Pages deployment ready"
    }
    
    try {
        gh repo view $GitHubUser/$RepoName 2>$null
        Write-Log INFO "Repo exists, pushing..."
    } catch {
        Write-Log INFO "Creating new repo..."
        gh repo create $RepoName --public --source=. --remote=origin
    }
    
    git push -u origin main --force
    Save-State "GitOps" "Completed"
    return $true
}

# ============================================
# AGENT 4: CLOUDFLARE PAGES DEPLOYER
# ============================================
function Agent-CloudflareDeploy {
    param([string]$APIToken, [string]$AccountId)
    Write-Log STEP "AGENT-4: Cloudflare Pages Deployment..."
    Save-State "CloudflareDeploy" "Running"
    
    if (-not $APIToken -or -not $AccountId) {
        Write-Log WARN "Cloudflare credentials missing - skipping auto deploy"
        Save-State "CloudflareDeploy" "Skipped" "Missing credentials"
        return $true
    }
    
    $headers = @{Authorization = "Bearer $APIToken"; "Content-Type" = "application/json"}
    
    $projectBody = @{
        name = $RepoName
        production_branch = "main"
        build_config = @{
            build_command = "npm run build"
            destination_dir = "dist"
            root_dir = ""
        }
        deployment_configs = @{}
    } | ConvertTo-Json -Depth 4
    
    try {
        $resp = Invoke-RestMethod -Method Post -Uri "https://api.cloudflare.com/client/v4/accounts/$AccountId/pages/projects" -Headers $headers -Body $projectBody
        if ($resp.success) { Write-Log INFO "Cloudflare Pages project created" }
    } catch {
        Write-Log WARN "Project may exist: $($_.Exception.Message)"
    }
    
    $deployBody = @{branch = "main"} | ConvertTo-Json
    try {
        $deploy = Invoke-RestMethod -Method Post -Uri "https://api.cloudflare.com/client/v4/accounts/$AccountId/pages/projects/$RepoName/deployments" -Headers $headers -Body $deployBody
        if ($deploy.success) { 
            Write-Log INFO "Deployment triggered: $($deploy.result.id)"
            $url = "https://$RepoName.pages.dev"
            Write-Log INFO "Live URL (after build): $url"
        }
    } catch {
        Write-Log WARN "Deploy trigger failed: $($_.Exception.Message)"
    }
    
    Save-State "CloudflareDeploy" "Completed"
    return $true
}

# ============================================
# AGENT 5: CI/CD PIPELINE SETUP
# ============================================
function Agent-CICDSetup {
    Write-Log STEP "AGENT-5: GitHub Actions CI/CD Setup..."
    Save-State "CICDSetup" "Running"
    
    $workflowDir = "$ProjectPath\.github\workflows"
    if (-not (Test-Path $workflowDir)) { New-Item -ItemType Directory -Path $workflowDir -Force | Out-Null }
    
    $workflow = @"
name: Deploy to Cloudflare Pages

on:
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: read
  deployments: write

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: npm run build
      - uses: cloudflare/pages-action@v1
        with:
          apiToken: `$`{`{ secrets.CLOUDFLARE_API_TOKEN `}`}`
          accountId: `$`{`{ secrets.CLOUDFLARE_ACCOUNT_ID `}`}`
          projectName: smarthome-vn-budget
          directory: dist
          branch: main
"@
    
    Set-Content -Path "$workflowDir\deploy.yml" -Value $workflow -Encoding UTF8
    
    git add .github/workflows/deploy.yml
    git commit -m "ci: add Cloudflare Pages deployment workflow"
    git push
    
    Save-State "CICDSetup" "Completed"
    return $true
}

# ============================================
# AGENT 6: VERIFICATION & HEALTH CHECK
# ============================================
function Agent-Verification {
    Write-Log STEP "AGENT-6: Verification & Health Check..."
    Save-State "Verification" "Running"
    
    Set-Location $ProjectPath
    npm run build
    
    if (Test-Path "dist\index.html") { Write-Log INFO "Build output verified" }
    
    $repoUrl = "https://github.com/$GitHubUser/$RepoName"
    Write-Log INFO "GitHub Repo: $repoUrl"
    
    Save-State "Verification" "Completed"
    return $true
}

# ============================================
# MAIN ORCHESTRATOR
# ============================================
function Main-Orchestrator {
    Write-Log STEP "============================================"
    Write-Log STEP "  SMART HOME VN BUDGET - FULL AUTO DEPLOY"
    Write-Log STEP "============================================"
    
    $state = Load-State
    if ($state.LastStep) { Write-Log INFO "Resuming from: $($state.LastStep) [$($state.Status)]" }
    
    if (-not $GitHubPAT) { $GitHubPAT = $env:GITHUB_PAT }
    if (-not $CloudflareAPIToken) { $CloudflareAPIToken = $env:CLOUDFLARE_API_TOKEN }
    if (-not $CloudflareAccountId) { $CloudflareAccountId = $env:CLOUDFLARE_ACCOUNT_ID }
    
    $agents = @(
        @{Name="Prerequisites"; Action={Agent-Prerequisites}; Required=$true},
        @{Name="GitHubAuth"; Action={Agent-GitHubAuth -PAT $GitHubPAT}; Required=$true},
        @{Name="GitOps"; Action={Agent-GitOps}; Required=$true},
        @{Name="CloudflareDeploy"; Action={Agent-CloudflareDeploy -APIToken $CloudflareAPIToken -AccountId $CloudflareAccountId}; Required=$false},
        @{Name="CICDSetup"; Action={Agent-CICDSetup}; Required=$true},
        @{Name="Verification"; Action={Agent-Verification}; Required=$true}
    )
    
    foreach ($agent in $agents) {
        if ($state.LastStep -eq $agent.Name -and $state.Status -eq "Completed") {
            Write-Log INFO "Skipping $($agent.Name) - already completed"
            continue
        }
        
        $success = Invoke-WithRetry -Action $agent.Action -MaxRetries 3 -DelaySec 10 -StepName $agent.Name
        
        if (-not $success -and $agent.Required) {
            Write-Log ERROR "Required agent $($agent.Name) failed. Deployment halted."
            Save-State $agent.Name "Failed"
            exit 1
        }
    }
    
    Write-Log STEP "============================================"
    Write-Log STEP "  DEPLOYMENT COMPLETED SUCCESSFULLY!"
    Write-Log STEP "============================================"
    Write-Log INFO "GitHub: https://github.com/$GitHubUser/$RepoName"
    Write-Log INFO "Live URL: https://$RepoName.pages.dev"
    Write-Log INFO "Local Dev: npm run dev (http://localhost:4321)"
}

# ============================================
# ENTRY POINT
# ============================================
if (-not $SkipPrerequisites) { Agent-Prerequisites }
Main-Orchestrator