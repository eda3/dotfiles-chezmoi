# config.nu
#
# Installed by:
# version = "0.109.1"
#
# This file is used to override default Nushell settings, define
# (or import) custom commands, or run any other startup tasks.
# See https://www.nushell.sh/book/configuration.html
#
# Nushell sets "sensible defaults" for most configuration settings, 
# so your `config.nu` only needs to override these defaults if desired.
#
# You can open this file in your default editor using:
#     config nu
#
# You can also pretty-print and page through the documentation for configuration
# options using:
#     config nu --doc | nu-highlight | less -R

$env.EDITOR = "hx"

def cl [] {
  powershell.exe -Command $"Set-Clipboard '($in)'"
}

$env.config.shell_integration.osc133 = false
$env.config.show_banner = false

def ll [] {ls -l}
def ltr [] {ls | sort-by modified}

# git系（短縮エイリアス）
alias gs = git status
alias gaa = git add -A
alias gcom = git commit -m 
alias gl = git log --oneline --graph -20
alias gf = git diff


alias ls-builtin = ls
# ディレクトリ内の項目のファイル名・サイズ・更新時刻を一覧表示する。
def ls [
    --all (-a),         # (-a) 隠しファイルも表示する
    --long (-l),        # (-l) 各項目の利用可能な全カラムを取得する（低速；カラムはプラットフォーム依存）
    --short-names (-s), # (-s) パスを含めずファイル名のみ表示する
    --full-paths (-f),  # (-f) パスを絶対パスで表示する
    --du (-d),          # (-d) ディレクトリのメタデータサイズの代わりに見かけのディレクトリサイズ（ディスク使用量）を表示する
    --directory (-D),   # (-D) 指定ディレクトリの中身ではなくディレクトリ自体を一覧表示する
    --mime-type (-m),   # (-m) type列に'file'の代わりにMIMEタイプを表示する（ファイル名のみに基づく；中身は検査しない）
    --threads (-t),     # (-t) 複数スレッドで中身を一覧する（出力順は非決定的になる）
    ...pattern: glob,   # 使用するglobパターン
]: [ nothing -> table ] {
    let pattern = if ($pattern | is-empty) { [ '.' ] } else { $pattern }
    (ls-builtin
        --all=$all
        --long=$long
        --short-names=$short_names
        --full-paths=$full_paths
        --du=$du
        --directory=$directory
        --mime-type=$mime_type
        --threads=$threads
        ...$pattern
    ) | sort-by type name -i
}

$env.config.keybindings ++= [
    {
        name: completion_menu
        modifier: control
        keycode: char_t
        mode: emacs
        event: { send: menu name: completion_menu }
    }
    {
        name: history_menu
        modifier: control
        keycode: char_r
        mode: emacs
        event: { send: menu name: history_menu }
    }
]

# carapace設定用
# ═══════════════════════════════════════════════════════════════════
# 補完設定 — carapace を外して external_completer 自作（A-単独）
# 目的  : rg のフラグを「カテゴリ順・日本語」で補完する
# 方針  : carapace は使わない → rg 以外は当面ファイル補完のみ
#         よく使うコマンドを1個ずつ match のブランチに足して育てる
# 戻し方: carapace に戻すなら ①②のコメントを外し ③④を消す/コメントアウト
# 注意  : external_completer で record の sort:false が効くかは実機で要確認
#         （効けばカテゴリ順・効かなければ別手）
# ═══════════════════════════════════════════════════════════════════

# --- ① carapace 本体の読み込み（戻す時はこのコメントを外す）---
source ($nu.cache-dir | path join carapace.nu)

# --- ② carapace の登録（戻す時はこのコメントを外す）---
$env.config.completions.external.completer = $carapace_completer


# =============================================================================
# ripgrep (rg) 日本語オプション補完 — nushell extern 定義
# 元ネタ: rg --help (ripgrep 15.1.0)
# 使い方: この定義を読み込むと `rg -`+Tab で日本語説明つき補完が出る
# 注意 : 説明は「読んで試す」ための教材。実挙動は rg で試して確認すること
# =============================================================================

export extern "rg" [
    # --- 位置引数 ---
    pattern?: string                        # 検索する正規表現パターン
    ...path: path                           # 検索対象のファイル or ディレクトリ

    # --- INPUT: 入力オプション ---
    --regexp(-e): string                    # 検索パターンを指定(複数可・-で始まる語の検索に便利)
    --file(-f): path                        # パターンをファイルから読み込む(1行1パターン)
    --pre: string                           # 各PATHをCOMMANDに通した出力を検索する(前処理)
    --pre-glob: string                      # 前処理コマンドを適用するファイルを絞る(glob)
    --search-zip(-z)                        # 圧縮ファイル(gz/zip等)の中身も検索する

    # --- SEARCH: 検索の挙動 ---
    --case-sensitive(-s)                    # 大文字小文字を区別する(デフォルト)
    --crlf                                  # CRLF改行を使う(Windows向けに嬉しい)
    --dfa-size-limit: string                # 正規表現DFAのサイズ上限
    --encoding(-E): string                  # 検索対象ファイルの文字コードを指定
    --engine: string                        # 使う正規表現エンジンを指定(default/pcre2/auto)
    --fixed-strings(-F)                     # パターンを正規表現でなくただの文字列として扱う
    --ignore-case(-i)                       # 大文字小文字を区別しない
    --invert-match(-v)                      # マッチ"しない"行を出す(反転)
    --line-regexp(-x)                       # 行全体がパターンに一致する時だけマッチ
    --max-count(-m): int                    # マッチ行数の上限(この数で打ち切り)
    --mmap                                  # 可能ならメモリマップで検索(速度調整)
    --multiline(-U)                         # 複数行にまたがる検索を有効化
    --multiline-dotall                      # 複数行時に「.」を改行にもマッチさせる
    --no-unicode                            # Unicodeモードを無効化
    --null-data                             # NUL(ヌル文字)を行区切りとして扱う
    --pcre2(-P)                             # PCRE2エンジンを使う(後方参照・先読み等が使える)
    --regex-size-limit: string              # コンパイル済み正規表現のサイズ上限
    --smart-case(-S)                        # 小文字だけなら大小無視・大文字混じりなら区別(賢い)
    --stop-on-nonmatch                      # 非マッチ行が来たら検索を止める
    --text(-a)                              # バイナリファイルもテキスト扱いで検索
    --threads(-j): int                      # 使うスレッド数の目安
    --word-regexp(-w)                       # 単語境界で囲まれた時だけマッチ(単語単位)
    --auto-hybrid-regex                     # 【非推奨】適切ならPCRE2を使う
    --no-pcre2-unicode                      # 【非推奨】PCRE2のUnicodeモードを無効化

    # --- FILTER: 検索対象の絞り込み ---
    --binary                                # バイナリファイルを検索対象にする
    --follow(-L)                            # シンボリックリンクをたどる
    --glob(-g): string                      # ファイルパスをglobで含める/除外する(例 -g '*.md')
    --glob-case-insensitive                 # 全globパターンを大小無視で扱う
    --hidden                                # 隠しファイル・隠しディレクトリも検索(短縮形 -.)
    --iglob: string                         # globで含める/除外する(大小無視版)
    --ignore-file: path                     # 追加の無視ファイルを指定
    --ignore-file-case-insensitive          # 無視ファイルを大小無視で処理
    --max-depth(-d): int                    # ディレクトリを最大NUM階層までたどる
    --max-filesize: string                  # このサイズより大きいファイルは無視
    --no-ignore                             # 無視ファイル(.gitignore等)を一切使わない
    --no-ignore-dot                         # .ignore/.rgignore を使わない
    --no-ignore-exclude                     # ローカルの除外ファイルを使わない
    --no-ignore-files                       # --ignore-file 指定を使わない
    --no-ignore-global                      # グローバルな無視ファイルを使わない
    --no-ignore-parent                      # 親ディレクトリの無視ファイルを使わない
    --no-ignore-vcs                         # バージョン管理(git等)の無視ファイルを使わない
    --no-require-git                        # gitリポジトリ外でも .gitignore を使う
    --one-file-system                       # 別ファイルシステムのディレクトリはスキップ
    --type(-t): string                      # 指定タイプのファイルだけ検索(例 -t rust)
    --type-not(-T): string                  # 指定タイプのファイルは検索しない
    --type-add: string                      # ファイルタイプに新しいglobを追加
    --type-clear: string                    # あるファイルタイプのglob定義を消す
    --unrestricted(-u)                      # 「賢い」フィルタを弱める(-uu -uuuで段階的に緩む)

    # --- OUTPUT: 出力の見た目・付加情報 ---
    --after-context(-A): int                # マッチ行の"後"をNUM行表示
    --before-context(-B): int               # マッチ行の"前"をNUM行表示
    --block-buffered                        # ブロックバッファリングを強制
    --byte-offset(-b)                       # マッチ行のバイトオフセットを表示
    --color: string                         # 色をいつ使うか(never/auto/always)
    --colors: string                        # 色の設定・スタイルを細かく指定
    --column                                # 列番号を表示
    --context(-C): int                      # マッチ行の前後をNUM行ずつ表示
    --context-separator: string             # コンテキスト区切りの文字列を設定
    --field-context-separator: string       # コンテキスト行のフィールド区切りを設定
    --field-match-separator: string         # マッチ行のフィールド区切りを設定
    --heading                               # マッチをファイルごとに見出しでグループ化
    --help(-h)                              # ヘルプを表示
    --hostname-bin: string                  # ホスト名を取得するプログラムを指定
    --hyperlink-format: string              # ハイパーリンクの書式を設定
    --include-zero                          # マッチ0件のファイルも集計出力に含める
    --line-buffered                         # 行バッファリングを強制
    --line-number(-n)                       # 行番号を表示(デフォルトON)
    --no-line-number(-N)                    # 行番号を表示しない
    --max-columns(-M): int                  # この長さを超える行は省略
    --max-columns-preview                   # 長すぎる行はプレビューを表示
    --null(-0)                              # ファイルパスの後にNULバイトを出力
    --only-matching(-o)                     # 行のうちマッチした部分だけ出力
    --path-separator: string                # パス表示のパス区切り文字を設定
    --passthru                              # マッチ行も非マッチ行も両方出力
    --pretty(-p)                            # 色+見出し+行番号のセット(見やすい表示)
    --quiet(-q)                             # 標準出力に何も出さない(終了コードだけ見る時)
    --replace(-r): string                   # マッチを指定テキストで置換して表示
    --sort: string                          # 結果を昇順でソート(path/modified等)
    --sortr: string                         # 結果を降順でソート
    --trim                                  # マッチ行の先頭の空白を削る
    --vimgrep                               # vim互換フォーマットで出力
    --with-filename(-H)                     # 各マッチ行にファイルパスを付ける
    --no-filename(-I)                       # ファイルパスを付けない
    --sort-files                            # 【非推奨】結果をファイルパスでソート

    # --- OUTPUT MODES: 出力モード ---
    --count(-c)                             # ファイルごとのマッチ"行数"を表示
    --count-matches                         # ファイルごとのマッチ"回数"を表示(1行複数マッチも数える)
    --files-with-matches(-l)                # マッチが1件以上あったファイルのパスだけ表示
    --files-without-match                   # マッチが0件のファイルのパスを表示
    --json                                  # 検索結果をJSON Lines形式で出力

    # --- LOGGING: ログ ---
    --debug                                 # デバッグメッセージを表示
    --no-ignore-messages                    # gitignoreパースエラーを抑制
    --no-messages                           # 一部のエラーメッセージを抑制
    --stats                                 # 検索の統計情報を表示
    --trace                                 # トレースメッセージを表示(debugより詳しい)

    # --- OTHER: その他の挙動 ---
    --files                                 # 検索対象になるファイル一覧を表示(検索はしない)
    --generate: string                      # manページや補完スクリプトを生成
    --no-config                             # 設定ファイルを一切読まない
    --pcre2-version                         # rgが使うPCRE2のバージョンを表示
    --type-list                             # サポートされる全ファイルタイプを表示
    --version(-V)                           # rgのバージョンを表示
]

# ghq と fzf用
def --env gf [] {
    ghq list --full-path | fzf | decode utf-8 | str trim | cd $in
}

# lsとfzf用
def --env gl [] {
    cd (ls | where type == dir | get name | str join (char nl) | fzf | decode utf-8 | str trim)
}

def --env chcd [] {
    chezmoi source-path | str replace 'home' '' |  cd $in;
}
