#!/usr/bin/env nu
# =============================================================================
# bootstrap.nu — 4環境統一 共通本体スクリプト (nushell製)
# -----------------------------------------------------------------------------
# 役割:
#   install_nu.ps1 (Windows) / install_nu.sh (Linux) で nushell を導入した後、
#   このスクリプトを `nu bootstrap.nu` で実行する。
#   OS を判定して必要なツール群を導入し、最後に chezmoi で設定を展開する。
#
# 前提:
#   - nushell は既に導入済み (install_nu.* が済ませている)
#   - このスクリプトは nushell の文法で書かれている
#
# 対象4環境:
#   Windows(現PC) / 新PC / VPSデバッグ / VPS本番
#
# 設計方針:
#   - Windows は winget で統一 (install_nu.ps1 と同じ方針)
#   - Linux は「apt or cargo/GitHubバイナリ」を実機確認して後で埋める
#     (今は骨組み: プレースホルダにして文法を先に固める)
#   - ログインシェルは変更しない (共用サーバのため)
#   - 導入すべきツール: git / chezmoi / zellij / helix / gh
#
# 使い方:
#   nu bootstrap.nu
# =============================================================================

# ---- ログ用ヘルパ -----------------------------------------------------------
# nushell の print はそのまま標準出力へ。色は ansi コマンドで付ける。
def info [msg: string] {
    print $"(ansi green)[INFO](ansi reset) ($msg)"
}
def warn [msg: string] {
    print $"(ansi yellow)[WARN](ansi reset) ($msg)"
}
def step [msg: string] {
    print $"(ansi cyan)=== ($msg) ===(ansi reset)"
}

# ---- 導入したいツール一覧 ---------------------------------------------------
# name    : コマンド名 (存在確認と表示に使う)
# winget  : Windows の winget ID
# ※ Linux 側の導入方法は下の linux 分岐で個別に扱う (方式がツールごとに違うため)
let tools = [
    [name    winget];
    [git     "Git.Git"]
    [chezmoi "twpayne.chezmoi"]
    [zellij  "Zellij.Zellij"]
    [helix   "Helix.Helix"]
    [gh      "GitHub.cli"]
]

# ---- コマンドの存在確認ヘルパ -----------------------------------------------
# `which` は nushell 組み込み。見つかれば1行以上返る → is-not-empty で判定。
def has-command [cmd: string]: nothing -> bool {
    (which $cmd | is-not-empty)
}

# =============================================================================
# メイン処理
# =============================================================================

step "OS 判定"
# nushell はOS情報を $nu.os-info で持つ。name は "windows" / "linux" / "macos" 等。
let os = $nu.os-info.name
info $"検出したOS: ($os)"

# -----------------------------------------------------------------------------
# OS分岐
# -----------------------------------------------------------------------------

if $os == "windows" {
    # =========================================================================
    # Windows: winget で統一導入
    # =========================================================================
    step "Windows: ツール導入 (winget)"

    for tool in $tools {
        if (has-command $tool.name) {
            info $"[skip] ($tool.name) は既に導入済み"
        } else {
            info $"[install] ($tool.name) を導入中 (($tool.winget))..."
            # winget を外部コマンドとして実行。
            # ※ winget は「既に最新でアップグレード無し」の時に非ゼロ終了を返すことがあり、
            #   nushell はそれを失敗と見なしてスクリプトを中断してしまう。
            #   try/catch で握りつぶし、1つのツールで止まらず次へ進めるようにする。
            try {
                (
                    winget install
                        --id $tool.winget
                        -e
                        --accept-source-agreements
                        --accept-package-agreements
                )
            } catch {
                # 失敗(非ゼロ終了)しても致命ではない場合が多いので警告に留めて続行。
                # 例: 既にインストール済み/アップグレード無し。
                warn $"($tool.name) の winget install が非ゼロ終了。続行します。"
            }
        }
    }
} else if $os == "linux" {
    # =========================================================================
    # Linux: 【骨組み】導入方式は実機確認して後で埋める
    # =========================================================================
    step "Linux: ツール導入 (未確定・プレースホルダ)"

    warn "Linux 側のツール導入は未実装です (実機確認して埋めてください)。"
    warn "候補: apt / cargo / GitHubバイナリ直DL (ツールごとに最適解が異なる)。"

    # --- 実機確認して埋めるメモ ---------------------------------------------
    # git     : apt にある想定 (`sudo apt install -y git`)
    # chezmoi : 公式インストーラ or apt or cargo。VPS(root) で要確認
    # zellij  : cargo(ビルド長い) or GitHubバイナリ直DL。x86_64 前提
    # helix   : apt(PPA) or cargo or GitHubバイナリ。%APPDATA%問題はWin側のみ
    # gh      : apt(GitHub公式リポジトリ登録) が王道
    #
    # ※ VPS は root 運用 & 共用サーバ。nushell を cargo で入れた実績(11分半)を踏まえ、
    #    重いビルドを避けたいものは apt/バイナリを優先する方針で埋める予定。
    #
    # for tool in $tools {
    #     if (has-command $tool.name) {
    #         info $"[skip] ($tool.name) は既に導入済み"
    #     } else {
    #         # TODO: ツールごとの導入コマンドをここに実装
    #     }
    # }

} else {
    # =========================================================================
    # その他OS (macos 等): 現状は対象外
    # =========================================================================
    warn $"未対応のOSです: ($os)。このスクリプトは windows / linux のみ対応。"
}

# -----------------------------------------------------------------------------
# chezmoi で設定を展開 (OS共通)
# -----------------------------------------------------------------------------
step "chezmoi: 設定を展開"

if (has-command "chezmoi") {
    info "chezmoi init --apply を実行します..."
    # 既に chezmoi 管理下にある前提。リポジトリ指定が要る場合は引数を足す。
    # 例: chezmoi init --apply https://github.com/eda3/dotfiles-chezmoi.git
    chezmoi init --apply eda3/dotfiles-chezmoi
} else {
    warn "chezmoi が見つかりません。ツール導入が未完了の可能性があります。"
    warn "(Linux は現在プレースホルダのため、chezmoi 未導入ならここに来ます)"
}

step "bootstrap 完了"
info "環境構築が完了しました。"
