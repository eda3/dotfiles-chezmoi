#Requires -Version 5.1
<#
.SYNOPSIS
    新品Windows PC ブートストラップスクリプト
.DESCRIPTION
    XDG環境変数設定 → git/chezmoi導入 → chezmoiでdotfiles展開
.USAGE
    irm https://raw.githubusercontent.com/eda3/dotfiles/master/bootstrap.ps1 | iex
#>

# コケたら止める（原因箇所が分かる）
$ErrorActionPreference = 'Stop'

# ============================================
# ヘルパー: PATHをセッション内で再読み込み
#   winget install直後にコマンドが見つからない罠への対策
# ============================================
function Update-SessionPath {
    $machine = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user    = [System.Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = @($machine, $user | Where-Object { $_ }) -join ';'
}

# ============================================
# ヘルパー: ツールが無ければwingetで導入（冪等）
# ============================================
function Ensure-Tool {
    param(
        [Parameter(Mandatory)][string] $Command,   # 確認するコマンド名 (例: git)
        [Parameter(Mandatory)][string] $WingetId    # wingetのID (例: Git.Git)
    )
    if (Get-Command $Command -ErrorAction SilentlyContinue) {
        Write-Host "[skip] $Command は既に導入済み" -ForegroundColor DarkGray
        return
    }
    Write-Host "[install] $Command を導入中 ($WingetId)..." -ForegroundColor Cyan
    winget install --id $WingetId -e --accept-source-agreements --accept-package-agreements
    Update-SessionPath   # 導入直後にPATH更新
    if (-not (Get-Command $Command -ErrorAction SilentlyContinue)) {
        throw "$Command の導入後もコマンドが見つかりません。手動確認が必要です。"
    }
    Write-Host "[ok] $Command 導入完了" -ForegroundColor Green
}

# ============================================
# 前提チェック: winget の存在
# ============================================
Write-Host "=== 前提チェック ===" -ForegroundColor Yellow
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "winget が見つかりません。" -ForegroundColor Red
    Write-Host "Microsoft Store から 'アプリ インストーラー (App Installer)' を導入してから再実行してください。" -ForegroundColor Red
    exit 1
}
Write-Host "[ok] winget 利用可能" -ForegroundColor Green

# ============================================
# ① XDG Base Directory 環境変数
#    永続（Userスコープ）＋ セッション内即反映（$env:）を併記
# ============================================
Write-Host "`n=== XDG 環境変数を設定 ===" -ForegroundColor Yellow
$xdg = @{
    XDG_CONFIG_HOME = "$env:USERPROFILE\.config"
    XDG_CACHE_HOME  = "$env:USERPROFILE\.cache"
    XDG_DATA_HOME   = "$env:USERPROFILE\.local\share"
    XDG_STATE_HOME  = "$env:USERPROFILE\.local\state"
}
foreach ($key in $xdg.Keys) {
    [System.Environment]::SetEnvironmentVariable($key, $xdg[$key], 'User')  # 永続
    Set-Item -Path "env:$key" -Value $xdg[$key]                            # セッション内即反映
    Write-Host "[set] $key = $($xdg[$key])" -ForegroundColor DarkGray
}

# ============================================
# ② 基盤ツール導入（git + chezmoi・冪等）
# ============================================
Write-Host "`n=== 基盤ツール導入 ===" -ForegroundColor Yellow
Ensure-Tool -Command 'git'     -WingetId 'Git.Git'
Ensure-Tool -Command 'chezmoi' -WingetId 'twpayne.chezmoi'

# ============================================
# ③ chezmoi でdotfiles展開＋ツール導入
# ============================================
Write-Host "`n=== chezmoi で環境構築 ===" -ForegroundColor Yellow
chezmoi init --apply eda3/dotfiles-chezmoi

Write-Host "`n=== ブートストラップ完了 ===" -ForegroundColor Green
Write-Host "新しいターミナルを開いて環境を確認してください。" -ForegroundColor Green
