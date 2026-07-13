#!/usr/bin/env bash
# ============================================
# 新品Linux(Ubuntu/Debian) PC 下準備スクリプト
#   Homebrew導入 → nushell導入
#   XDGはLinuxネイティブなので設定不要
#   この後 `nu bootstrap.nu` を実行
#
#   参考: https://brew.sh/  https://www.nushell.sh/ja/book/installation.html
# .USAGE
#   curl -fsSL https://raw.githubusercontent.com/eda3/dotfiles-chezmoi/master/install_nu.sh | bash
#   その後: nu bootstrap.nu
# ============================================
set -euo pipefail

echo "=== nushell 下準備 (Homebrew方式) ==="

# ============================================
# ① Homebrew 導入
#    無ければ公式インストーラで導入し、PATHを通す
# ============================================
echo "--- ① Homebrew 確認 ---"
if command -v brew >/dev/null 2>&1; then
    echo "[skip] brew は既に導入済み"
else
    echo "[install] Homebrew を導入中..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo "[ok] Homebrew 導入完了"
fi

# --- brew に PATH を通す（Linux版は /home/linuxbrew/.linuxbrew に入る）---
# 現シェルで brew コマンドを使えるようにする
if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [ -x "$HOME/.linuxbrew/bin/brew" ]; then
    eval "$("$HOME/.linuxbrew/bin/brew" shellenv)"
fi

# ============================================
# ② nushell 導入
# ============================================
echo "--- ② nushell 導入 ---"
if command -v nu >/dev/null 2>&1; then
    echo "[skip] nu は既に導入済み"
else
    echo "[install] nushell を導入中..."
    brew install nushell
    echo "[ok] nushell 導入完了"
fi

echo ""
echo "=== 下準備 完了 ==="
echo "次のコマンドで環境構築を続けてください:"
echo "  nu bootstrap.nu"
