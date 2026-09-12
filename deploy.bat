@echo off
REM Smart Home VN Budget - Simple Deployment Batch Script
REM Run this file to start the automated deployment

echo ============================================
echo  Smart Home VN Budget - Quick Deploy
echo ============================================
echo.

REM Check if we're in the right directory
if not exist "package.json" (
    echo ERROR: Please run this from D:\smarthome-vn-budget
    pause
    exit /b 1
)

echo [1/5] Checking for required tools...
where git >nul 2>nul
if %errorlevel% neq 0 (
    echo Git not found. Installing via winget...
    winget install --id Git.Git --accept-source-agreements --accept-package-agreements
    echo Please restart this script after Git installs.
    pause
    exit /b 1
)
echo Git: OK

where node >nul 2>nul
if %errorlevel% neq 0 (
    echo Node.js not found. Installing via winget...
    winget install --id OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
    echo Please restart this script after Node installs.
    pause
    exit /b 1
)
echo Node.js: OK

where gh >nul 2>nul
if %errorlevel% neq 0 (
    echo GitHub CLI not found. Installing via winget...
    winget install --id GitHub.cli --accept-source-agreements --accept-package-agreements
)
echo GitHub CLI: OK

echo.
echo [2/5] Initializing Git repository...
if not exist ".git" (
    git init
    echo Git initialized
) else (
    echo Git already initialized
)

echo.
echo [3/5] Creating .gitignore...
if not exist ".gitignore" (
    echo node_modules > .gitignore
    echo dist >> .gitignore
    echo .build >> .gitignore
    echo .env >> .gitignore
    echo .env.local >> .gitignore
    echo .env.production >> .gitignore
    echo .DS_Store >> .gitignore
    echo *.log >> .gitignore
    echo .vercel >> .gitignore
    echo .netlify >> .gitignore
    echo .wrangler >> .gitignore
    echo coverage >> .gitignore
    echo *.local >> .gitignore
    echo .gitignore created
)

echo.
echo [4/5] Committing changes...
git add .
git commit -m "feat: initial release - Smart Home VN Budget

- Astro 4.x + Tailwind CSS static site
- 3 pilot articles (Budget Build, Sonoff Dongle, Smart Bulb comparison)
- Affiliate system with link cloaking
- Sitemap, RSS, PWA ready
- Cloudflare Pages deployment ready"

echo.
echo [5/5] Creating GitHub repository...
echo Please enter your GitHub username:
set /p GH_USER="GitHub Username: "

if "%GH_USER%"=="" (
    echo No username provided. Skipping GitHub repo creation.
    echo You can manually create the repo at https://github.com/new
) else (
    echo Creating repo %GH_USER%/smarthome-vn-budget...
    gh repo create smarthome-vn-budget --public --source=. --remote=origin --push
    if %errorlevel% neq 0 (
        echo.
        echo GitHub CLI might need authentication. Run:
        echo   gh auth login
        echo.
        echo Then manually push:
        echo   git remote add origin https://github.com/%GH_USER%/smarthome-vn-budget.git
        echo   git push -u origin main
    )
)

echo.
echo ============================================
echo  LOCAL SETUP COMPLETE!
echo ============================================
echo.
echo Next steps for Cloudflare Pages:
echo 1. Go to https://dash.cloudflare.com/pages
echo 2. Click "Create a project" > "Connect to Git"
echo 3. Select your repo: smarthome-vn-budget
echo 4. Build settings:
echo    - Build command: npm run build
echo    - Output directory: dist
echo    - Node version: 18
echo 5. Add Environment Variables:
echo    - GA4_MEASUREMENT_ID = G-XXXXXXXXXX
echo    - SHOPEE_AFFILIATE_ID = your-id
echo    - LAZADA_AFFILIATE_ID = your-id
echo    - AMAZON_ASSOCIATES_TAG = your-tag
echo    (and other affiliate IDs)
echo 6. Click "Save and Deploy"
echo.
echo Your site will be live at: https://smarthome-vn-budget.pages.dev
echo.
pause