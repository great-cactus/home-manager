# Home Manager for HPC

root権限なしのHPCクラスタに [nix-portable](https://github.com/DavHau/nix-portable) で開発環境を構築する.

## セットアップ

### ワンライナー

```bash
curl -sL https://raw.githubusercontent.com/great-cactus/home-manager/hpc/scripts/bootstrap-hpc.sh | bash
```

以下が自動で行われる：

1. `nix-portable` を `~/.local/bin/` にダウンロード
2. Nixストアを `/tmp/$USER/nix-portable/` に配置（Lustre回避）
3. このリポジトリを `~/projects/home-manager` にクローン
4. Home Manager を適用（zsh, Neovim, CLIツール一式をインストール）

完了後 `exec zsh` で新しいシェルを起動する.

### 手動セットアップ

```bash
# nix-portable をダウンロード
mkdir -p ~/.local/bin
curl -L "https://github.com/DavHau/nix-portable/releases/latest/download/nix-portable-$(uname -m)" \
  -o ~/.local/bin/nix-portable
chmod +x ~/.local/bin/nix-portable
export PATH="$HOME/.local/bin:$PATH"

# Nixストアをローカルディスクに配置（Lustre上では動作しない）
export NP_LOCATION="/tmp/$USER/nix-portable"
mkdir -p "$NP_LOCATION"

# リポジトリをクローン
git clone -b hpc https://github.com/great-cactus/home-manager.git ~/projects/home-manager

# Home Manager を適用
cd ~/projects/home-manager
nix-portable nix run --impure .#homeConfigurations.hpc.activationPackage

# シェルを再読み込み
exec zsh
```

## 事前準備

セットアップ前に `~/.env` を作成しておく：

```bash
cat > ~/.env << 'EOF'
PROMPT_COLOR=green
WIN_DEVICE=hpc-cluster
EOF
```

既存の `.zshrc` がある場合はバックアップしておく：

```bash
mv ~/.zshrc ~/.zshrc.backup
```

## 設定の更新

```bash
cd ~/projects/home-manager
git pull origin hpc
nix-portable nix run --impure .#homeConfigurations.hpc.activationPackage
```

## Lustre ファイルシステムについて

多くのHPCクラスタではホームディレクトリが Lustre 上にある. Nix は `lustre.lov` 拡張属性の削除に失敗するため,Nixストアを **ローカルディスク（`/tmp`）** に配置する必要がある.

- ブートストラップスクリプトは自動で `NP_LOCATION=/tmp/$USER/nix-portable` を設定する
- zsh 起動時に `~/.local/bin/nix-portable-env.sh` を読み込み,`NP_LOCATION` を維持する
- `/tmp` はノード再起動で消えるため,再起動後は再度 Home Manager を適用する

## 含まれるもの

### パッケージ

`gh`, `uv`, `fzf`, `cargo`, `deno`, `nodejs`, `ripgrep`, `trash-cli`, `ffmpeg`

### モジュール

| モジュール | 内容 |
|------------|------|
| `modules/zsh/` | zsh設定・エイリアス・カスタム関数 |
| `modules/neovim/` | Neovim設定・LSP（pylsp, lua_ls, nil, fortls）・ddc補完・skkeleton |

### main ブランチとの差分

HPC環境では不要な以下を除外している：

- Claude Code / Copilot（ネット接続なし）
- WezTerm設定（terminfo のみ含む）
- LaTeX関連（texlab, ltex-ls, efm）
- Obsidian連携・TTS・markdown-preview
- corefonts, evince, llama-cpp, cmake, ninja, oneAPI

## 仕組み

```
nix-portable
└── /tmp/$USER/nix-portable/.nix-portable/store/  ← Lustre回避

flake.nix
├── home.nix                 ← Linux/macOS 用（mainブランチ）
└── home-hpc.nix             ← HPC 用（このブランチ）
    ├── modules/zsh/
    └── modules/neovim/
```

## トラブルシューティング

### "removing extended attribute 'lustre.lov'" エラー

`NP_LOCATION` が Lustre 上を指している. ローカルディスクに変更する：

```bash
export NP_LOCATION="/tmp/$USER/nix-portable"
mkdir -p "$NP_LOCATION"
```

### nix-portable が動かない

proot フォールバックを強制する：

```bash
NP_RUNTIME=proot nix-portable nix run --impure .#homeConfigurations.hpc.activationPackage
```

### "Existing file would be clobbered" エラー

既存の設定ファイルが競合している：

```bash
mv ~/.zshrc ~/.zshrc.backup
```

### ノード再起動後にコマンドが見つからない

`/tmp` のNixストアが消えているため再適用する：

```bash
cd ~/projects/home-manager
nix-portable nix run --impure .#homeConfigurations.hpc.activationPackage
```

### Neovimプラグインが更新されない

```vim
:call dein#clear_state()
:q
```

再度 `nvim` を起動すると再構築される.
