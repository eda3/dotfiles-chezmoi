#!/usr/bin/env bash
# =============================================================================
# install_nu.sh — Linux(VPS)向け nushell インストールスクリプト (cargo方式)
# -----------------------------------------------------------------------------
# 役割:
#   cargo install nu で nushell の最新版を導入する。
#   これは 4 環境統一(Windows/新PC/VPSデバッグ/VPS本番)のうち Linux 側の下準備。
#   ※ Windows は winget で導入(方式を揃える美学より実用優先の割り切り)。
#
# 重要な設計方針:
#   - ログインシェルは変更しない (chsh も /etc/passwd も .bashrc も触らない)。
#     このサーバは共用のため、nushell を使わない他ユーザーに影響を与えない。
#     使いたいときは `nu` と打って起動する。それだけ。
#   - rust ツールチェーンの有無を rustup の存在で判定する。
#       * rustup が無ければ rustup を新規インストール
#       * rustup が有れば rustup update で最新化(戦略A: 予防的)
#     → nushell の要求 rustc バージョンは将来上がるので、
#       数値をハードコードせず「常に最新 rust」で回避する。
#   - 冪等: 何回叩いても安全。再実行すれば nushell も最新に更新される
#           (cargo install が既存を上書き)。
#
# 前提:
#   - x86_64 Linux (uname -m で確認済み)
#
# 使い方:
#   chmod +x install_nu.sh
#   ./install_nu.sh
# =============================================================================

set -euo pipefail

# ---- ログ用ヘルパ -----------------------------------------------------------
info()  { printf '\033[0;32m[INFO]\033[0m %s\n'  "$*"; }
warn()  { printf '\033[0;33m[WARN]\033[0m %s\n'  "$*" >&2; }
error() { printf '\033[0;31m[ERROR]\033[0m %s\n' "$*" >&2; }

# ---- 0. 実行環境チェック ----------------------------------------------------
machine="$(uname -m)"
if [ "${machine}" != "x86_64" ]; then
  error "このスクリプトは x86_64 専用です (検出: ${machine})。"
  exit 1
fi

# ---- 1. rust ツールチェーンの用意 (rustup の有無で分岐) ---------------------
if command -v rustup >/dev/null 2>&1; then
  # --- rust が既にある: 戦略A = 予防的に最新化してからビルド ---
  info "rustup 検出。rust ツールチェーンを最新化します (rustup update)..."
  rustup update
else
  # --- rust が無い: rustup を新規インストール ---
  info "rustup が見つかりません。rustup を新規インストールします..."
  # 公式インストーラ。-y で対話なし、default プロファイルで stable を導入
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  # このシェルセッションに PATH を反映 (cargo/rustc を今すぐ使うため)
  # rustup は ~/.cargo/env に環境設定を書く
  # shellcheck disable=SC1091
  . "${HOME}/.cargo/env"
fi

# ここまでで cargo が使える状態のはず。念のため確認。
if ! command -v cargo >/dev/null 2>&1; then
  error "cargo が見つかりません。rust のインストールに失敗した可能性があります。"
  error "手動で 'source \$HOME/.cargo/env' を試すか、rustup を確認してください。"
  exit 1
fi

info "cargo: $(cargo --version)"
info "rustc: $(rustc --version)"

# ---- 2. nushell を cargo でインストール ------------------------------------
# ※ ビルドに時間がかかる (2GB VPS 実測で約11分半)。OOM はしなかった実績あり。
# ※ cargo install は既存を上書きするので、再実行 = 最新への更新も兼ねる。
info "nushell を cargo install します (ビルドに数分〜十数分かかります)..."
cargo install nu

# ---- 3. 検証 ----------------------------------------------------------------
# cargo で入れたバイナリは通常 ~/.cargo/bin/nu に置かれる。
# PATH に ~/.cargo/bin が通っていれば `nu` で起動できる。
if command -v nu >/dev/null 2>&1; then
  info "インストール完了: $(nu --version)"
  info "起動するには 'nu' と入力してください(ログインシェルは変更していません)。"
else
  warn "nu が PATH 上に見つかりません。"
  warn "~/.cargo/bin が PATH に含まれるか確認してください (例: source \$HOME/.cargo/env)。"
fi
