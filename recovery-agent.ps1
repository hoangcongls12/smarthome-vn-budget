<# 
.SYNOPSIS
    Recovery Agent - Auto-fixes common deployment issues
    Handles: missing PATH, missing repo, token permissions, failed secrets
#>

param(
    [string]$GitHubPAT = $env:GITHUB_PAT,
    [string]$CloudflareAPIToken = $env:CLOUDFLARE_API_TOKEN,
    [string]$CloudflareAccountId = $env:CLOUDFLARE_ACCOUNT_ID
)

$ErrorActionPreference = "Continue"
$ProjectPath = "D:\smarthome-vn-budget"

function Write-FixLog { param([string]$Level, [string]$Msg) 
    $entry = "[$(Get-Date -Format 'HH:mm:ss')] [$Level] $Msg"
    Add-Content -Path "$ProjectPath\recovery.log" -Value $entry -Encoding UTF8
    $colors = @{INFO='Green'; WARN='Yellow'; ERROR='Red'; STEP='Cyan'; FIX='Magenta'}
    Write-Host $entry -ForegroundColor $colors[$Level]
}

# ============================================
# FIX 1: RESTORE PATH
# ============================================
function Fix-Path {
    Write-FixLog STEP "FIX 1: Restoring PATH..."
    $newPath = [Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [Environment]::GetEnvironmentVariable("Path","User")
    $env:PATH = $newPath
    $refresh = @(
        "C:\Program Files\Git\bin",
        "C:\Program Files\Git\cmd",
        "C:\Program Files\nodejs",
        "C:\Users\$env:USERNAME\AppData\Local\GitHubDesktop\bin",
        "C:\Program Files\GitHub CLI"
    )
    foreach ($p in $refresh) { if (Test-Path $p -and $env:PATH -notlike "*$p*") { $env:PATH += ";$p" } }
    Write-FixLog FIX "PATH restored: $($env:PATH -split ';' | Where-Object {$_ -like '*git*' -or $_ -like '*node*' -or $_ -like '*github*'})"
}

# ============================================
# FIX 2: VERIFY TOOLS
# ============================================
function Fix-Tools {
    Write-FixLog STEP "FIX 2: Verifying tools..."
    $tools = @(
        @{Name="git"; Check="git --version"; InstallUrl="https://github.com/git-for-windows/git/releases/download/v2.45.1.windows.1/Git-2.45.1-64-bit.exe"},
        @{Name="node"; Check="node --version"; InstallUrl="https://nodejs.org/dist/v18.20.4/node-v18.20.4-x64.msi"},
        @{Name="npm"; Check="npm --version"; InstallUrl=""},
        @{Name="gh"; Check="gh --version"; InstallUrl="https://github.com/cli/cli/releases/download/v2.45.0/gh_2.45.0_windows_amd64.msi"}
    )
    
    foreach ($t in $tools) {
        try {
            Invoke-Expression $t.Check | Out-Null
            Write-FixLog FIX "$($t.Name) OK"
        } catch {
            Write-FixLog WARN "$($t.Name) missing, attempting install..."
            if ($t.InstallUrl) {
                $local = "$env:TEMP\$($t.Name)_install.exe"
                if ($t.InstallUrl -like "*.msi") { $local = "$env:TEMP\$($t.Name)_install.msi" }
                try {
                    Invoke-WebRequest -Uri $t.InstallUrl -OutFile $local -ErrorAction Stop
                    if ($t.InstallUrl -like "*.msi") { Start-Process msiexec.exe -ArgumentList "/i `"$local`" /qn /norestart" -Wait -NoNewWindow }
                    else { Start-Process $local -ArgumentList "/VERYSILENT /NORESTART" -Wait -NoNewWindow }
                    Fix-Path
                    Write-FixLog FIX "$($t.Name) installed"
                } catch { Write-FixLog ERROR "Failed to install $($t.Name): $($_.Exception.Message)" }
            }
        }
    }
}

# ============================================
# FIX 3: GITHUB REPO CREATION
# ============================================
function Fix-GitHubRepo {
    Write-FixLog STEP "FIX 3: Ensuring GitHub repo exists..."
    $repoName = "smarthome-vn-budget"
    $gitHubUser = "hoangcongls12"
    
    # Check if repo exists
    try {
        $env:GH_TOKEN = $GitHubPAT
        $repo = gh api repos/hoangcongls12/smarthome-vn-budget 2>$null
        if ($repo) { Write-FixLog FIX "Repo exists"; return }
    } catch {}
    
    Write-FixLog STEP "Creating GitHub repo..."
    try {
        # Initialize git if needed
        if (-not (Test-Path ".git")) { git init; Write-FixLog FIX "Git initialized" }
        
        # Config
        git config --global user.email "hoangcongls12@gmail.com"
        git config --global user.name "hoangcongls12"
        git config --global --add safe.directory D:/smarthome-vn-budget
        
        # Commit
        git add .
        if (-not (git rev-parse --verify HEAD 2>$null)) {
            git commit -m "feat: initial release - Smart Home VN Budget"
            Write-FixLog FIX "Initial commit created"
        }
        
        # Create repo via gh
        gh repo create smarthome-vn-budget --public --source=. --remote=origin --push
        Write-FixLog FIX "GitHub repo created and pushed"
    } catch {
        Write-FixLog ERROR "Repo creation failed: $($_.Exception.Message)"
        Write-FixLog WARN "Manual: gh repo create smarthome-vn-budget --public --source=. --remote=origin --push"
    }
}

# ============================================
# FIX 4: CLOUDFLARE TOKEN PERMISSIONS
# ============================================
function Fix-CloudflareToken {
    Write-FixLog STEP "FIX 4: Verifying Cloudflare token permissions..."
    
    try {
        $resp = Invoke-RestMethod -Method Get -Uri "https://api.cloudflare.com/client/v4/accounts" -Headers @{Authorization = "Bearer $CloudflareAPIToken"} -ErrorAction Stop
        if (-not $resp.success) { throw "API failed: $($resp.errors | ConvertTo-Json)" }
        Write-FixLog FIX "Token can list accounts"
    } catch {
        Write-FixLog ERROR "Token invalid or missing permissions: $($_.Exception.Message)"
        Write-FixLog WARN "CREATE NEW TOKEN at https://dash.cloudflare.com/profile/api-tokens"
        Write-FixLog WARN "Permissions needed: Account:Pages:Edit, Account:Account Settings:Read"
        return $false
    }
    return $true
}

# ============================================
# FIX 5: GITHUB SECRETS (after repo exists)
# ============================================
function Fix-GitHubSecrets {
    Write-FixLog STEP "FIX 5: Setting GitHub Secrets..."
    
    $secrets = @{
        "CLOUDFLARE_API_TOKEN" = $CloudflareAPIToken
        "CLOUDFLARE_ACCOUNT_ID" = $CloudflareAccountId
        "GITHUB_PAT" = $GitHubPAT
    }
    
    foreach ($secret in $secrets.GetEnumerator()) {
        $name = $secret.Key
        $value = $secret.Value
        Write-FixLog INFO ("Setting secret: " + $name)
        try {
            $pubKey = gh api repos/hoangcongls12/smarthome-vn-budget/actions/secrets/public-key --jq '{key: .key, key_id: .key_id}'
            $keyId = $pubKey.key_id
            gh api --method PUT "repos/hoangcongls12/smarthome-vn-budget/actions/secrets/$name" -f encrypted_value="$value" -f key_id="$keyId" 2>&1 | Out-Null
            Write-FixLog FIX ("Secret " + $name + " set")
        } catch {
            Write-FixLog WARN ("Secret " + $name + " failed - set manually in GitHub Settings > Secrets > Actions")
        }
    }
}

# ============================================
# FIX 6: CLOUDFLARE PAGES PROJECT
# ============================================
function Fix-CloudflarePages {
    Write-FixLog STEP "FIX 6: Creating Cloudflare Pages project..."
    
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
            Write-FixLog FIX ("Pages project created: " + $resp.result.name)
            $global:projectId = $resp.result.id
        } elseif ($resp.errors[0].code -eq 10000) {
            Write-FixLog WARN "Project exists, getting ID..."
            $existing = Invoke-RestMethod -Method Get -Uri "https://api.cloudflare.com/client/v4/accounts/$CloudflareAccountId/pages/projects/smarthome-vn-budget" -Headers @{Authorization = "Bearer $CloudflareAPIToken"}
            $global:projectId = $existing.result.id
            Write-FixLog FIX ("Using existing project: " + $global:projectId)
        } else {
            throw ($resp.errors | ConvertTo-Json)
        }
    } catch {
        Write-FixLog ERROR ("Pages project failed: " + $_.Exception.Message)
        return $false
    }
    
    # Configure build
    $configBody = @{
        build_config = @{ build_command = "npm run build"; destination_dir = "dist"; root_dir = "" }
        production_branch = "main"
    } | ConvertTo-Json -Depth 4
    
    try {
        Invoke-RestMethod -Method Put -Uri "https://api.cloudflare.com/client/v4/accounts/$CloudflareAccountId/pages/projects/$global:projectId" -Headers @{Authorization = "Bearer $CloudflareAPIToken"; "Content-Type" = "application/json"} -Body $configBody -ErrorAction Stop | Out-Null
        Write-FixLog FIX "Build config updated"
    } catch { Write-FixLog WARN "Config update failed: $($_.Exception.Message)" }
    
    # Trigger deploy
    try {
        $deploy = Invoke-RestMethod -Method Post -Uri "https://api.cloudflare.com/client/v4/accounts/$CloudflareAccountId/pages/projects/$global:projectId/deployments" -Headers @{Authorization = "Bearer $CloudflareAPIToken"; "Content-Type" = "application/json"} -Body @{branch="main"} | ConvertTo-Json -Depth 2 -ErrorAction Stop
        if ($deploy.success) { Write-FixLog FIX ("Deployment triggered: " + $deploy.result.id) }
    } catch { Write-FixLog WARN "Deploy trigger failed: $($_.Exception.Message)" }
}

# ============================================
# MAIN RECOVERY ORCHESTRATOR
# ============================================
Write-FixLog STEP "============================================"
Write-FixLog STEP "  RECOVERY AGENT - AUTO-FIXING ISSUES"
Write-FixLog STEP "============================================"

$GitHubPAT = $env:GITHUB_PAT
$CloudflareAPIToken = $env:CLOUDFLARE_API_TOKEN
$CloudflareAccountId = $env:CLOUDFLARE_ACCOUNT_ID

# Run all fixes in order
Fix-Path
Fix-Tools
Fix-GitHubRepo
$tokenOk = Fix-CloudflareToken

if ($tokenOk) {
    Fix-GitHubSecrets
    Fix-CloudflarePages
}

Write-FixLog FIX "============================================"
Write-FixLog FIX "  RECOVERY COMPLETE"
Write-FixLog FIX "============================================"
Write-FixLog INFO "Next steps:"
Write-FixLog INFO "1. Check Cloudflare Pages dashboard for deployment status"
Write-FixLog INFO "2. Verify live site: https://smarthome-vn-budget.pages.dev"
Write-FixLog INFO "3. Run operations-agent.ps1 -RunOnce to verify"