# Home Manager Configuration

Nix Home Managerを使ったzsh/neovim設定の管理リポジトリ.

## Nixのインストール（未導入の場合）

```bash
# 公式インストーラー
curl -L https://nixos.org/nix/install | sh

# Flakes有効化（~/.config/nix/nix.conf に追加）
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

## セットアップ

### 1. 既存設定のバックアップ

```bash
mv ~/.zshrc ~/.zshrc.backup
```

### 2. 環境変数ファイルの作成

`~/.env` を作成し,動的な環境変数を定義：

```bash
cat > ~/.env << 'EOF'
PROMPT_COLOR=cyan
WIN_DEVICE=your-pc-name
EOF
```

### 3. 初回適用

```bash
# Linux
nix run .#homeConfigurations.linux.activationPackage

# macOS (Apple Silicon)
nix run .#homeConfigurations.macos.activationPackage
```

ユーザー名とホームディレクトリは `flake.nix` の `extraSpecialArgs` で環境ごとに定義されているため,`home.nix` の編集は不要.

### 4. Neovim（dein.vim）のセットアップ

```bash
# dein.vimのインストール
git clone https://github.com/Shougo/dein.vim ~/.cache/dein/repos/github.com/Shougo/dein.vim

# tomlファイルの配置（既存の設定がある場合）
cp /path/to/your/dein.toml ~/.cache/dein/
cp /path/to/your/dein_lazy.toml ~/.cache/dein/
```

初回起動時にdeinが自動でプラグインをインストールする.

### 5. 新しいシェルを起動

```bash
exec zsh
```

## 日常の使い方

### 設定を変更した後

```bash
# Linux
nix run .#homeConfigurations.linux.activationPackage

# macOS
nix run .#homeConfigurations.macos.activationPackage
```

### Flakeの依存関係を更新

```bash
nix flake update
```

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
    └── neovim/
        ├── default.nix    # neovim設定
        └── init.lua       # Lua設定
```

### 外部依存（dein.vim）

```
~/.cache/dein/
├── dein.toml              # 通常プラグイン定義
├── dein_lazy.toml         # 遅延読み込みプラグイン定義
└── repos/                 # プラグイン本体（自動生成）
```

## 環境別設定

`flake.nix` で環境ごとにユーザー名とホームディレクトリを定義：

| 環境 | ユーザー名 | ホームディレクトリ |
|------|-----------|-------------------|
| linux | tnd | /home/tnd |
| macos | akiratsunoda | /Users/akiratsunoda |

新しい環境を追加する場合は `flake.nix` の `homeConfigurations` に設定を追加する.

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
nix run .#homeConfigurations.macos.activationPackage
```

## 参考リンク

- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Nix Flakes](https://nixos.wiki/wiki/Flakes)
