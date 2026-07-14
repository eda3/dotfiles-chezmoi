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
    [carapace "rsteube.Carapace"]
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
    # Linux: ツール導入
    #   方針: 「apt だと古い」を嫌い、Rust製(zellij/helix)は cargo install で
    #         最新を入れる(えだの実need + cargo 一元管理の意志)。
    #         非Rust製(git/chezmoi/gh)は apt/公式インストーラ。
    #   前提: cargo が使えること(install_nu.sh 経由なら rust 導入済み)。
    #   共用サーバのためログインシェルは変更しない。
    # =========================================================================
    step "Linux: ツール導入"

    # --- cargo の存在確認(Rust製ツールの導入に必須) -------------------------
    if not (has-command "cargo") {
        warn "cargo が見つかりません。zellij/helix の導入をスキップします。"
        warn "先に install_nu.sh(rust 導入込み)を実行してください。"
    }

    # --- git (C製 → apt) -----------------------------------------------------
    if (has-command "git") {
        info "[skip] git は既に導入済み"
    } else {
        info "[install] git を導入中 (apt)..."
        try {
            sudo apt-get update
            sudo apt-get install -y git
        } catch {
            warn "git の apt 導入が失敗しました。続行します。"
        }
    }

    # --- zellij (Rust製 → cargo install) -------------------------------------
    # ※ apt 版は古いため cargo で最新を入れる。ビルドに時間がかかる。
    if (has-command "zellij") {
        info "[skip] zellij は既に導入済み"
    } else if (has-command "cargo") {
        info "[install] zellij を cargo install 中(ビルドに数分〜十数分)..."
        try {
            cargo install zellij
        } catch {
            warn "zellij の cargo install が失敗しました。続行します。"
        }
    }

    # --- helix (Rust製 → cargo install) --------------------------------------
    # ※ crate 名は helix-term。apt 版は古いため cargo で最新を入れる。
    # ※【要注意】cargo install だけでは runtime ディレクトリ(構文定義等)が
    #    入らず、シンタックスハイライトが効かない等の不具合が出うる。
    #    対処案: 環境変数 HELIX_RUNTIME を runtime の場所に向ける、
    #            もしくは runtime を ~/.config/helix/runtime へ配置する。
    #    → ここは実機で確認して必要なら追記する(今は cargo install のみ)。
    if (has-command "hx") {
        info "[skip] helix (hx) は既に導入済み"
    } else if (has-command "cargo") {
        info "[install] helix を cargo install 中(ビルドに数分〜十数分)..."
        try {
            cargo install helix-term
        } catch {
            warn "helix の cargo install が失敗しました。続行します。"
        }
        warn "helix は runtime 配置が別途必要な場合あり(構文ハイライト等)。実機で要確認。"
    }

    # --- gh (Go製 → apt: GitHub 公式リポジトリ) ------------------------------
    # ※ gh は cargo では入らない(Go製)。GitHub 公式の apt リポジトリを使うのが王道。
    #    公式手順(リポジトリ鍵登録)は環境で変わりうるため、ここは骨組みとして
    #    「apt に gh があれば入れる」簡易版。無ければ公式手順を実機で追記。
    if (has-command "gh") {
        info "[skip] gh は既に導入済み"
    } else {
        info "[install] gh を導入中 (apt)..."
        try {
            sudo apt-get install -y gh
        } catch {
            warn "gh の apt 導入が失敗しました(公式リポジトリ登録が必要な場合あり)。続行します。"
        }
    }

    # --- chezmoi (Go製 → 公式インストーラ) -----------------------------------
    # ※ chezmoi も cargo では入らない(Go製)。公式インストーラが確実。
    #    root 運用の VPS 前提。BINDIR を /usr/local/bin にして PATH 既通の場所へ。
    if (has-command "chezmoi") {
        info "[skip] chezmoi は既に導入済み"
    } else {
        info "[install] chezmoi を公式インストーラで導入中..."
        try {
            # 公式インストーラを /usr/local/bin へ。root 前提。
            sh -c 'curl -fsSL https://get.chezmoi.io | sh -s -- -b /usr/local/bin'
        } catch {
            warn "chezmoi の公式インストーラが失敗しました。続行します。"
        }
    }
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
