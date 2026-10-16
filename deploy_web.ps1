# ==============================================================================
# 🚀 DOK-KEY Safe Deployment & Verification Script (deploy_web.ps1)
# ==============================================================================
# 이 스크립트는 루트 랜딩페이지와 하위 web/ 데모 모드의 2-Tier 구조를 엄격히 검증하고
# 배포 실수를 원천 방지하며 로컬(XAMPP)과 원격(GitHub Pages)을 안전하게 동기화합니다.
# ==============================================================================

param(
    [string]$CommitMessage = ""
)

$ErrorActionPreference = "Stop"
$RepoDir = "C:\Works\DOK-KEY-release"
$LocalHtdocsDir = "c:\xampp\htdocs\dokkey"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "🗝️  DOK-KEY Safe Deployment Pipeline 시작" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# ------------------------------------------------------------------------------
# 1. 2-Tier 아키텍처 무결성 검증 (루트 index.html 덮어쓰기 방지)
# ------------------------------------------------------------------------------
Write-Host "`n[1/5] 루트 랜딩 페이지 무결성 검증 중..." -ForegroundColor Yellow

$RootIndex = Join-Path $RepoDir "index.html"
if (!(Test-Path $RootIndex)) {
    Write-Error "❌ 치명적 오류: 루트 index.html이 존재하지 않습니다!"
}

$RootContent = Get-Content $RootIndex -Raw -Encoding UTF8
if (!$RootContent.Contains("TYPE: DOK-KEY-OFFICIAL-LANDING")) {
    Write-Error "❌ 배포 중단: 루트 index.html에 공식 랜딩 서명(TYPE: DOK-KEY-OFFICIAL-LANDING)이 없습니다! Flutter Web 파일로 덮어씌워졌을 가능성이 있습니다."
}

if ($RootContent.Contains('src="flutter_bootstrap.js"') -or $RootContent.Contains('src="main.dart.js"')) {
    Write-Error "❌ 배포 중단: 루트 index.html에 Flutter Web 스크립트가 포함되어 있습니다! 루트는 순수 시네마틱 랜딩 페이지여야 합니다."
}
Write-Host "   ✅ 루트 랜딩 페이지 무결성 확인 완료 (보호 서명 정상)" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 2. 웹 데모 (web/) 필수 파일 존재 확인
# ------------------------------------------------------------------------------
Write-Host "`n[2/5] 웹 데모(web/) 구성 요소 검증 중..." -ForegroundColor Yellow

$WebIndex = Join-Path $RepoDir "web\index.html"
$WebMainJs = Join-Path $RepoDir "web\main.dart.js"
$WebBootstrap = Join-Path $RepoDir "web\flutter_bootstrap.js"

if (!(Test-Path $WebIndex) -or !(Test-Path $WebMainJs) -or !(Test-Path $WebBootstrap)) {
    Write-Error "❌ 배포 중단: web/ 폴더에 필수 파일(index.html, main.dart.js, flutter_bootstrap.js)이 누락되었습니다."
}
Write-Host "   ✅ 웹 데모 필수 파일 확인 완료" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 3. main.dart.js Web 호환성 패치 검사 및 자동 보정
# ------------------------------------------------------------------------------
Write-Host "`n[3/5] main.dart.js Web 호환성 (Platform._environment) 패치 확인 중..." -ForegroundColor Yellow

$JsContent = [System.IO.File]::ReadAllText($WebMainJs, [System.Text.Encoding]::UTF8)

$NeedsPatch = $false
$TargetThrow = 'ck4(){throw A.h(A.b0("Platform._environment"))}'
if ($JsContent.Contains($TargetThrow)) {
    $NeedsPatch = $true
}

if ($NeedsPatch) {
    Write-Host "   ⚠️ 미패치 상태 감지: Web 브라우저 호환성 패치 적용 중..." -ForegroundColor Yellow
    
    $Old1 = "ck7(){throw A.h(A.b0(`"Platform._pathSeparator`"))},`nck6(){throw A.h(A.b0(`"Platform._operatingSystem`"))},`nck4(){throw A.h(A.b0(`"Platform._environment`"))},"
    $New1 = "ck7(){return`"/`"},`nck6(){return`"web`"},`nck4(){return{a:{aK:function(){return false},t:function(){return null},b:function(){return 0}}}},"
    
    $Old2 = "ck8(){var s=`$.ck5`nif(s==null)A.ck4()`ns.toString`nreturn s},"
    $New2 = "ck8(){var s=`$.ck5`nif(s==null)s=A.ck4()`ns.toString`nreturn s},"
    
    $JsContent = $JsContent.Replace($Old1, $New1).Replace($Old2, $New2)
    [System.IO.File]::WriteAllText($WebMainJs, $JsContent, [System.Text.Encoding]::UTF8)
    Write-Host "   ✅ main.dart.js 패치 적용 완료!" -ForegroundColor Green
} else {
    Write-Host "   ✅ main.dart.js Web 호환성 패치 이미 적용됨 (정상)" -ForegroundColor Green
}

# ------------------------------------------------------------------------------
# 4. 로컬 XAMPP 웹서버(c:\xampp\htdocs\dokkey) 1:1 완벽 동기화
# ------------------------------------------------------------------------------
Write-Host "`n[4/5] 로컬 XAMPP htdocs 동기화 중..." -ForegroundColor Yellow

if (Test-Path $LocalHtdocsDir) {
    Copy-Item -Path (Join-Path $RepoDir "index.html") -Destination (Join-Path $LocalHtdocsDir "index.html") -Force
    Copy-Item -Path (Join-Path $RepoDir "DEPLOYMENT_RULES.md") -Destination (Join-Path $LocalHtdocsDir "DEPLOYMENT_RULES.md") -Force
    Copy-Item -Path (Join-Path $RepoDir "AGENTS.md") -Destination (Join-Path $LocalHtdocsDir "AGENTS.md") -Force
    
    $LocalWebDir = Join-Path $LocalHtdocsDir "web"
    if (!(Test-Path $LocalWebDir)) {
        New-Item -ItemType Directory -Path $LocalWebDir -Force | Out-Null
    }
    Copy-Item -Path (Join-Path $RepoDir "web\*") -Destination $LocalWebDir -Recurse -Force
    Write-Host "   ✅ 로컬 XAMPP(c:\xampp\htdocs\dokkey) 동기화 완료" -ForegroundColor Green
} else {
    Write-Host "   ℹ️ 로컬 XAMPP 폴더를 찾을 수 없어 건너뜁니다." -ForegroundColor Gray
}

# ------------------------------------------------------------------------------
# 5. Git 상태 확인 및 원격(gh-pages) 배포
# ------------------------------------------------------------------------------
Write-Host "`n[5/5] Git 상태 확인 및 배포 중..." -ForegroundColor Yellow

Push-Location $RepoDir
try {
    git add .
    $Status = git status --porcelain
    if ([string]::IsNullOrWhiteSpace($Status)) {
        Write-Host "   ℹ️ 변경된 파일이 없어 커밋을 건너뜁니다." -ForegroundColor Cyan
    } else {
        if ([string]::IsNullOrWhiteSpace($CommitMessage)) {
            $DateStr = Get-Date -Format "yyyy-MM-dd HH:mm"
            $CommitMessage = "deploy(web): automated safe deployment ($DateStr)"
        }
        git commit -m "$CommitMessage"
        git push origin gh-pages
        Write-Host "   ✅ GitHub Pages(gh-pages) 배포 성공!" -ForegroundColor Green
    }
} finally {
    Pop-Location
}

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "🎉 모든 검증과 배포가 성공적으로 완료되었습니다!" -ForegroundColor Cyan
Write-Host "   • 공식 홈: https://alivekevin.github.io/DOK-KEY-release/" -ForegroundColor White
Write-Host "   • 웹 데모: https://alivekevin.github.io/DOK-KEY-release/web/" -ForegroundColor White
Write-Host "==========================================================" -ForegroundColor Cyan
