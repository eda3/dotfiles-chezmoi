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

$env.config = {
    shell_integration: {
    osc133: false
    }
}
# $env.config.show_banner = true
$env.config.show_banner = false

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
# source ($nu.cache-dir | path join carapace.nu)

# --- ② carapace の登録（戻す時はこのコメントを外す）---
# $env.config.completions.external.completer = $carapace_completer

# --- （道Bの export extern "rg" 定義は削除 or コメントアウト。external_completer と競合するため）---

# --- ③ rg のフラグ補完（カテゴリ順・日本語）---
def rg-complete [spans: list<string>] {
    # フラグ以外（パターン・パス）はファイル補完に任せる
    if not (($spans | last) | str starts-with "-") {
        return null
    }
    {
        options: { sort: false, completion_algorithm: prefix }
        completions: [
            # === INPUT: 入力 ===
            { value: "-e",                          description: "検索パターンを指定(複数可・-で始まる語に便利)" }
            { value: "--regexp",                    description: "検索パターンを指定(複数可・-で始まる語に便利)" }
            { value: "-f",                          description: "パターンをファイルから読み込む(1行1パターン)" }
            { value: "--file",                      description: "パターンをファイルから読み込む(1行1パターン)" }
            { value: "--pre",                       description: "各PATHをCOMMANDに通した出力を検索(前処理)" }
            { value: "--pre-glob",                  description: "前処理コマンドを適用するファイルを絞る(glob)" }
            { value: "-z",                          description: "圧縮ファイル(gz/zip等)の中身も検索する" }
            { value: "--search-zip",                description: "圧縮ファイル(gz/zip等)の中身も検索する" }

            # === SEARCH: 検索の挙動 ===
            { value: "-s",                          description: "大文字小文字を区別する(デフォルト)" }
            { value: "--case-sensitive",            description: "大文字小文字を区別する(デフォルト)" }
            { value: "-i",                          description: "大文字小文字を区別しない" }
            { value: "--ignore-case",               description: "大文字小文字を区別しない" }
            { value: "-S",                          description: "小文字だけなら大小無視・大文字混じりなら区別(賢い)" }
            { value: "--smart-case",                description: "小文字だけなら大小無視・大文字混じりなら区別(賢い)" }
            { value: "-F",                          description: "パターンを正規表現でなくただの文字列として扱う" }
            { value: "--fixed-strings",             description: "パターンを正規表現でなくただの文字列として扱う" }
            { value: "-w",                          description: "単語境界で囲まれた時だけマッチ(単語単位)" }
            { value: "--word-regexp",               description: "単語境界で囲まれた時だけマッチ(単語単位)" }
            { value: "-x",                          description: "行全体がパターンに一致する時だけマッチ" }
            { value: "--line-regexp",               description: "行全体がパターンに一致する時だけマッチ" }
            { value: "-v",                          description: "マッチ\"しない\"行を出す(反転)" }
            { value: "--invert-match",              description: "マッチ\"しない\"行を出す(反転)" }
            { value: "-m",                          description: "マッチ行数の上限(この数で打ち切り)" }
            { value: "--max-count",                 description: "マッチ行数の上限(この数で打ち切り)" }
            { value: "-U",                          description: "複数行にまたがる検索を有効化" }
            { value: "--multiline",                 description: "複数行にまたがる検索を有効化" }
            { value: "--multiline-dotall",          description: "複数行時に「.」を改行にもマッチさせる" }
            { value: "-P",                          description: "PCRE2エンジンを使う(後方参照・先読み等が使える)" }
            { value: "--pcre2",                     description: "PCRE2エンジンを使う(後方参照・先読み等が使える)" }
            { value: "-a",                          description: "バイナリファイルもテキスト扱いで検索" }
            { value: "--text",                      description: "バイナリファイルもテキスト扱いで検索" }
            { value: "-E",                          description: "検索対象ファイルの文字コードを指定" }
            { value: "--encoding",                  description: "検索対象ファイルの文字コードを指定" }
            { value: "--engine",                    description: "使う正規表現エンジンを指定(default/pcre2/auto)" }
            { value: "-j",                          description: "使うスレッド数の目安" }
            { value: "--threads",                   description: "使うスレッド数の目安" }
            { value: "--crlf",                      description: "CRLF改行を使う(Windows向けに嬉しい)" }
            { value: "--null-data",                 description: "NUL(ヌル文字)を行区切りとして扱う" }
            { value: "--no-unicode",                description: "Unicodeモードを無効化" }
            { value: "--stop-on-nonmatch",          description: "非マッチ行が来たら検索を止める" }
            { value: "--mmap",                      description: "可能ならメモリマップで検索(速度調整)" }
            { value: "--dfa-size-limit",            description: "正規表現DFAのサイズ上限" }
            { value: "--regex-size-limit",          description: "コンパイル済み正規表現のサイズ上限" }

            # === FILTER: 検索対象の絞り込み ===
            { value: "-g",                          description: "ファイルパスをglobで含める/除外(例 -g '*.md')" }
            { value: "--glob",                      description: "ファイルパスをglobで含める/除外(例 -g '*.md')" }
            { value: "--iglob",                     description: "globで含める/除外(大小無視版)" }
            { value: "--glob-case-insensitive",     description: "全globパターンを大小無視で扱う" }
            { value: "-t",                          description: "指定タイプのファイルだけ検索(例 -t rust)" }
            { value: "--type",                      description: "指定タイプのファイルだけ検索(例 -t rust)" }
            { value: "-T",                          description: "指定タイプのファイルは検索しない" }
            { value: "--type-not",                  description: "指定タイプのファイルは検索しない" }
            { value: "--type-add",                  description: "ファイルタイプに新しいglobを追加" }
            { value: "--type-clear",                description: "あるファイルタイプのglob定義を消す" }
            { value: "-d",                          description: "ディレクトリを最大NUM階層までたどる" }
            { value: "--max-depth",                 description: "ディレクトリを最大NUM階層までたどる" }
            { value: "--max-filesize",              description: "このサイズより大きいファイルは無視" }
            { value: "--hidden",                    description: "隠しファイル・隠しディレクトリも検索(短縮形 -.)" }
            { value: "-L",                          description: "シンボリックリンクをたどる" }
            { value: "--follow",                    description: "シンボリックリンクをたどる" }
            { value: "--binary",                    description: "バイナリファイルを検索対象にする" }
            { value: "--one-file-system",           description: "別ファイルシステムのディレクトリはスキップ" }
            { value: "--no-ignore",                 description: "無視ファイル(.gitignore等)を一切使わない" }
            { value: "--no-ignore-dot",             description: ".ignore/.rgignore を使わない" }
            { value: "--no-ignore-vcs",             description: "バージョン管理(git等)の無視ファイルを使わない" }
            { value: "--no-ignore-global",          description: "グローバルな無視ファイルを使わない" }
            { value: "--no-ignore-parent",          description: "親ディレクトリの無視ファイルを使わない" }
            { value: "--no-ignore-exclude",         description: "ローカルの除外ファイルを使わない" }
            { value: "--no-ignore-files",           description: "--ignore-file 指定を使わない" }
            { value: "--no-require-git",            description: "gitリポジトリ外でも .gitignore を使う" }
            { value: "--ignore-file",               description: "追加の無視ファイルを指定" }
            { value: "--ignore-file-case-insensitive", description: "無視ファイルを大小無視で処理" }
            { value: "-u",                          description: "「賢い」フィルタを弱める(-uu -uuuで段階的に緩む)" }
            { value: "--unrestricted",              description: "「賢い」フィルタを弱める(-uu -uuuで段階的に緩む)" }

            # === OUTPUT: 出力の見た目・付加情報 ===
            { value: "-A",                          description: "マッチ行の\"後\"をNUM行表示" }
            { value: "--after-context",             description: "マッチ行の\"後\"をNUM行表示" }
            { value: "-B",                          description: "マッチ行の\"前\"をNUM行表示" }
            { value: "--before-context",            description: "マッチ行の\"前\"をNUM行表示" }
            { value: "-C",                          description: "マッチ行の前後をNUM行ずつ表示" }
            { value: "--context",                   description: "マッチ行の前後をNUM行ずつ表示" }
            { value: "-n",                          description: "行番号を表示(デフォルトON)" }
            { value: "--line-number",               description: "行番号を表示(デフォルトON)" }
            { value: "-N",                          description: "行番号を表示しない" }
            { value: "--no-line-number",            description: "行番号を表示しない" }
            { value: "-H",                          description: "各マッチ行にファイルパスを付ける" }
            { value: "--with-filename",             description: "各マッチ行にファイルパスを付ける" }
            { value: "-I",                          description: "ファイルパスを付けない" }
            { value: "--no-filename",               description: "ファイルパスを付けない" }
            { value: "-o",                          description: "行のうちマッチした部分だけ出力" }
            { value: "--only-matching",             description: "行のうちマッチした部分だけ出力" }
            { value: "-r",                          description: "マッチを指定テキストで置換して表示" }
            { value: "--replace",                   description: "マッチを指定テキストで置換して表示" }
            { value: "-p",                          description: "色+見出し+行番号のセット(見やすい表示)" }
            { value: "--pretty",                    description: "色+見出し+行番号のセット(見やすい表示)" }
            { value: "-q",                          description: "標準出力に何も出さない(終了コードだけ見る時)" }
            { value: "--quiet",                     description: "標準出力に何も出さない(終了コードだけ見る時)" }
            { value: "-b",                          description: "マッチ行のバイトオフセットを表示" }
            { value: "--byte-offset",               description: "マッチ行のバイトオフセットを表示" }
            { value: "-0",                          description: "ファイルパスの後にNULバイトを出力" }
            { value: "--null",                      description: "ファイルパスの後にNULバイトを出力" }
            { value: "-M",                          description: "この長さを超える行は省略" }
            { value: "--max-columns",               description: "この長さを超える行は省略" }
            { value: "--max-columns-preview",       description: "長すぎる行はプレビューを表示" }
            { value: "--column",                    description: "列番号を表示" }
            { value: "--heading",                   description: "マッチをファイルごとに見出しでグループ化" }
            { value: "--trim",                      description: "マッチ行の先頭の空白を削る" }
            { value: "--vimgrep",                   description: "vim互換フォーマットで出力" }
            { value: "--color",                     description: "色をいつ使うか(never/auto/always)" }
            { value: "--colors",                    description: "色の設定・スタイルを細かく指定" }
            { value: "--passthru",                  description: "マッチ行も非マッチ行も両方出力" }
            { value: "--include-zero",              description: "マッチ0件のファイルも集計出力に含める" }
            { value: "--sort",                      description: "結果を昇順でソート(path/modified等)" }
            { value: "--sortr",                     description: "結果を降順でソート" }
            { value: "--path-separator",            description: "パス表示のパス区切り文字を設定" }
            { value: "--context-separator",         description: "コンテキスト区切りの文字列を設定" }
            { value: "--field-context-separator",   description: "コンテキスト行のフィールド区切りを設定" }
            { value: "--field-match-separator",     description: "マッチ行のフィールド区切りを設定" }
            { value: "--hostname-bin",              description: "ホスト名を取得するプログラムを指定" }
            { value: "--hyperlink-format",          description: "ハイパーリンクの書式を設定" }
            { value: "--block-buffered",            description: "ブロックバッファリングを強制" }
            { value: "--line-buffered",             description: "行バッファリングを強制" }
            { value: "-h",                          description: "ヘルプを表示" }
            { value: "--help",                      description: "ヘルプを表示" }

            # === OUTPUT MODES: 出力モード ===
            { value: "-c",                          description: "ファイルごとのマッチ\"行数\"を表示" }
            { value: "--count",                     description: "ファイルごとのマッチ\"行数\"を表示" }
            { value: "--count-matches",             description: "ファイルごとのマッチ\"回数\"を表示(1行複数も数える)" }
            { value: "-l",                          description: "マッチが1件以上あったファイルのパスだけ表示" }
            { value: "--files-with-matches",        description: "マッチが1件以上あったファイルのパスだけ表示" }
            { value: "--files-without-match",       description: "マッチが0件のファイルのパスを表示" }
            { value: "--json",                      description: "検索結果をJSON Lines形式で出力" }

            # === LOGGING: ログ ===
            { value: "--stats",                     description: "検索の統計情報を表示" }
            { value: "--debug",                     description: "デバッグメッセージを表示" }
            { value: "--trace",                     description: "トレースメッセージを表示(debugより詳しい)" }
            { value: "--no-messages",               description: "一部のエラーメッセージを抑制" }
            { value: "--no-ignore-messages",        description: "gitignoreパースエラーを抑制" }

            # === OTHER: その他 ===
            { value: "--files",                     description: "検索対象になるファイル一覧を表示(検索はしない)" }
            { value: "--type-list",                 description: "サポートされる全ファイルタイプを表示" }
            { value: "--generate",                  description: "manページや補完スクリプトを生成" }
            { value: "--no-config",                 description: "設定ファイルを一切読まない" }
            { value: "--pcre2-version",             description: "rgが使うPCRE2のバージョンを表示" }
            { value: "-V",                          description: "rgのバージョンを表示" }
            { value: "--version",                   description: "rgのバージョンを表示" }
        ]
    }
}

# --- ④ 自作 external_completer（rg だけ自作・他はファイル補完）---
$env.config.completions.external.completer = {|spans|
    match ($spans | first) {
        "rg" => (rg-complete $spans)
        _ => null
    }
}
