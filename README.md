# Home Manager Configuration

Nix Home Managerを使った開発環境設定の管理リポジトリ.

## 管理対象

| モジュール | 管理内容 |
|------------|----------|
| `modules/zsh/` | zsh設定（エイリアス・カスタム関数） |
| `modules/neovim/` | Neovim設定（dein.vimプラグイン・LSP・スニペット等） |
| `modules/claude/` | Claude Code設定（ルール・スキル・settings.json） |
| `modules/wezterm/` | WezTerm設定（WSL環境でWindows側へコピー） |

### パッケージ（`home.nix`で管理）

`corefonts`, `gh`, `uv`, `fzf`, `cargo`, `deno`, `nodejs_24`, `ripgrep`, `trash-cli`, `llama-cpp`, `claude-code`, `julia-bin`, `ffmpeg`, `cmake`, `gnumake`, `ninja`, `evince`

---

## 環境一覧

| 環境 | ブランチ | 設定ファイル | 用途 |
|------|---------|-------------|------|
| linux | `main` | `home.nix` | WSL2 / デスクトップLinux |
| macos | `main` | `home.nix` | macOS (Apple Silicon) |
| hpc | `hpc` | `home-hpc.nix` | HPCクラスタ（rootなし・nix-portable） |

---

## セットアップ（Linux / macOS）

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
nix run --impure ".#homeConfigurations.linux.activationPackage"

# macOS (Apple Silicon)
nix run --impure .#homeConfigurations.macos.activationPackage
```

### 5. zsh をデフォルトシェルに設定

```bash
echo ~/.nix-profile/bin/zsh | sudo tee -a /etc/shells
chsh -s ~/.nix-profile/bin/zsh
```

### 6. 新しいシェルを起動

```bash
exec zsh
```

---

## セットアップ（HPC）

root権限なしのHPCクラスタ向け. [nix-portable](https://github.com/DavHau/nix-portable) を使い,`~/.nix-portable/store` にユーザ空間でNixストアを構築する.

### ワンライナーセットアップ

```bash
curl -sL https://raw.githubusercontent.com/great-cactus/home-manager/hpc/scripts/bootstrap-hpc.sh | bash
```

### 手動セットアップ

```bash
# 1. nix-portable をダウンロード
mkdir -p ~/.local/bin
curl -L "https://github.com/DavHau/nix-portable/releases/latest/download/nix-portable-$(uname -m)" \
  -o ~/.local/bin/nix-portable
chmod +x ~/.local/bin/nix-portable
export PATH="$HOME/.local/bin:$PATH"

# 2. リポジトリをクローン
git clone -b hpc https://github.com/great-cactus/home-manager.git ~/projects/home-manager
cd ~/projects/home-manager

# 3. Home Manager を適用
nix-portable nix run --impure .#homeConfigurations.hpc.activationPackage

# 4. シェルを再読み込み
exec zsh
```

### HPC向け設定の内容

`home-hpc.nix` は `home.nix` からHPC不要なものを除外した構成：

- **含まれるもの**: `gh`, `uv`, `fzf`, `cargo`, `deno`, `nodejs`, `ripgrep`, `trash-cli`, `ffmpeg`, zsh, Neovim
- **除外されたもの**: Claude Code, WezTerm, corefonts, oneAPI, evince, Copilot, Obsidian連携, LaTeX LSP

WezTerm terminfo は含まれるため,WezTermからSSHしても表示が崩れない.

### 設定の更新

```bash
cd ~/projects/home-manager
git pull origin hpc
nix-portable nix run --impure .#homeConfigurations.hpc.activationPackage
```

---

## 日常の使い方

### 設定変更後の適用

```bash
# Linux (x86_64)
nix run --impure ".#homeConfigurations.linux.activationPackage"

# macOS (Apple Silicon)
nix run --impure .#homeConfigurations.macos.activationPackage

# HPC
nix-portable nix run --impure .#homeConfigurations.hpc.activationPackage
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
├── home.nix               # Home Manager設定のルート（Linux/macOS）
├── home-hpc.nix           # Home Manager設定（HPC用）
├── scripts/
│   ├── import-env.sh      # .envファイル読み込みスクリプト
│   └── bootstrap-hpc.sh   # HPC環境セットアップスクリプト
└── modules/
    ├── zsh/               # zsh設定（エイリアス・カスタム関数）
    ├── neovim/            # Neovim設定（dein.vim・LSP・スニペット等）
    ├── claude/            # Claude Code設定（ルール・スキル・settings.json）
    └── wezterm/           # WezTerm設定（WSL→Windows側コピー）
```

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
- [nix-portable](https://github.com/DavHau/nix-portable)
