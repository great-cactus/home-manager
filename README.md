# Home Manager Configuration

Nix Home Managerを使った開発環境設定の管理リポジトリ.

## 管理対象

| モジュール | 管理内容 |
|------------|----------|
| `modules/zsh/` | zsh設定（エイリアス・カスタム関数） |
| `modules/neovim/` | Neovim設定（dein.vimプラグイン・LSP・スニペット等） |
| `modules/claude/` | Claude Code設定（ルール・スキル） |
| `modules/obsidian/` | Obsidian Vault用ルール・スキル |

### パッケージ（`home.nix`で管理）

`gh`, `uv`, `fzf`, `cargo`, `deno`, `nodejs_24`, `ripgrep`, `trash-cli`, `llama-cpp`

---

## セットアップ

### 1. Nixのインストール（未導入の場合）

```bash
curl -L https://nixos.org/nix/install | sh

# Flakes有効化（~/.config/nix/nix.conf に追加）
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

### 2. 既存設定のバックアップ

```bash
mv ~/.zshrc ~/.zshrc.backup
```

### 3. 環境変数ファイルの作成

`~/.env` を作成し,動的な環境変数を定義：

```bash
cat > ~/.env << 'EOF'
PROMPT_COLOR=cyan
WIN_DEVICE=your-pc-name
EOF
```

### 4. 初回適用

```bash
# Linux (x86_64)
nix run .#homeConfigurations.linux.activationPackage

# macOS (Apple Silicon)
nix run .#homeConfigurations.macos.activationPackage
```

> ユーザー名とホームディレクトリは `flake.nix` の `extraSpecialArgs` で環境ごとに定義されているため,`home.nix` の編集は不要.

### 5. 新しいシェルを起動

```bash
exec zsh
```

---

## 日常の使い方

### 設定変更後の適用

```bash
# Linux
nix run .#homeConfigurations.linux.activationPackage

# macOS
nix run .#homeConfigurations.macos.activationPackage
```

### 依存パッケージの更新

```bash
nix flake update
```

---

## ディレクトリ構造

```
.
├── flake.nix              # Flake定義（依存関係・環境別設定）
├── flake.lock             # バージョンロック（自動生成）
├── home.nix               # Home Manager設定のルート
├── scripts/
│   └── import-env.sh      # .envファイル読み込みスクリプト
└── modules/
    ├── zsh/
    │   ├── default.nix    # zsh本体設定
    │   ├── aliases.nix    # エイリアス定義
    │   └── functions.nix  # カスタム関数
    ├── neovim/
    │   ├── default.nix    # Neovim設定（Nix）
    │   ├── init.lua       # 起動設定
    │   ├── dein.toml      # dein.vim プラグイン定義
    │   ├── dein_lazy.toml # dein.vim 遅延プラグイン定義
    │   └── nvim/
    │       ├── colors/    # カラースキーム
    │       ├── lua/
    │       │   ├── config/    # 機能別設定（スクロール・補完・LSP切替等）
    │       │   ├── lsp/       # LSP設定（pylsp, lua_ls, ltex, texlab 等）
    │       │   └── plugins/   # プラグイン設定（codecompanion, obsidian 等）
    │       ├── queries/   # Treesitter クエリ（highlights・injections）
    │       ├── snippets/  # スニペット（Fortran, LaTeX, Markdown 等）
    │       └── templates/ # ファイルテンプレート（Python, TeX 等）
    ├── claude/
    │   ├── default.nix    # ~/.claude/ へのシンボリックリンク定義
    │   ├── rules/         # Claude Codeの行動ルール（14ファイル）
    │   └── skills/        # Claude Codeのカスタムスキル
    │       ├── coding-standards/
    │       ├── smart-commit/
    │       └── obsidian-create-permanent-note/
    └── obsidian/
        ├── rules/         # Obsidian Vault向けルール
        └── skills/        # Obsidian Vault向けスキル
```

---

## 環境別設定

`flake.nix` で環境ごとにユーザー名とホームディレクトリを定義：

| 環境 | ユーザー名 | ホームディレクトリ |
|------|-----------|-------------------|
| linux | tnd | /home/tnd |
| macos | akiratsunoda | /Users/akiratsunoda |

新しい環境を追加する場合は `flake.nix` の `homeConfigurations` に設定を追加する.

---

## Claude Codeモジュールについて

`modules/claude/` はClaude Code（`~/.claude/`）の設定を管理する.

- **rules/**: Claude Codeが参照する行動ルール（コーディングスタイル・セキュリティ・テスト・Obsidian連携等）
- **skills/**: `/skill-name` で呼び出せるカスタムスキル

設定変更後はHome Managerを再適用すると `~/.claude/rules/` と `~/.claude/skills/` が更新される.

---

## トラブルシューティング

### "experimental feature 'flakes' is disabled" エラー

```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

### "Existing file would be clobbered" エラー

既存の設定ファイル（`.zshrc`等）が競合している場合,バックアップしてから再実行：

```bash
mv ~/.zshrc ~/.zshrc.backup
nix run .#homeConfigurations.linux.activationPackage
```

### Neovimプラグインが更新されない

dein.vimのキャッシュをクリアして再起動：

```
:call dein#clear_state()
:q
nvim
```

---

## 参考リンク

- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Nix Flakes](https://nixos.wiki/wiki/Flakes)
