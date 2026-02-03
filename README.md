# Home Manager Configuration

Nix Home Managerを使ったzsh設定の管理リポジトリ.

## 前提条件

- Nix がインストール済み（Flakes有効）
- WSL2 または Linux環境

### Nixのインストール（未導入の場合）

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
cd ~/.config/home-manager
nix flake update
nix run home-manager -- switch --flake .#tnd
```

### 4. 新しいシェルを起動

```bash
exec zsh
```

## 日常の使い方

### 設定を変更した後

```bash
hms  # home-manager switch のエイリアス
```

### Flakeの依存関係を更新

```bash
cd ~/.config/home-manager
nix flake update
hms
```

## ディレクトリ構造

```
~/.config/home-manager/
├── flake.nix              # Flake定義（依存関係）
├── flake.lock             # バージョンロック（自動生成）
├── home.nix               # Home Manager設定のルート
├── scripts/
│   └── import-env.sh      # .envファイル読み込みスクリプト
└── modules/
    └── zsh/
        ├── default.nix    # zsh本体設定
        ├── aliases.nix    # エイリアス定義
        └── functions.nix  # カスタム関数
```

## カスタマイズ

### エイリアスを追加

`modules/zsh/aliases.nix` を編集：

```nix
programs.zsh.shellAliases = {
  # 既存のエイリアス...
  myalias = "my-command --flag";
};
```

### 関数を追加

`modules/zsh/functions.nix` を編集：

```nix
programs.zsh.initExtra = lib.mkAfter ''
  # 既存の関数...

  myfunc() {
    echo "Hello, $1"
  }
'';
```

### 環境変数を追加

- **静的な値**: `home.nix` の `home.sessionVariables` に追加
- **動的な値**: `~/.env` に追加（import-env.shで読み込み）

## macOSへの移行

`home.nix` を編集：

```nix
home.homeDirectory = "/Users/tnd";  # /home/tnd から変更
```

適用：

```bash
nix run home-manager -- switch --flake .#tnd@darwin
```

## トラブルシューティング

### "experimental feature 'flakes' is disabled" エラー

```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

## 参考リンク

- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Nix Flakes](https://nixos.wiki/wiki/Flakes)
