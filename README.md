# Home Manager for HPC

root権限なしのHPCクラスタに [nix-portable](https://github.com/DavHau/nix-portable) で開発環境を構築する.

## セットアップ

### ワンライナー

```bash
curl -sL https://raw.githubusercontent.com/great-cactus/home-manager/hpc/scripts/bootstrap-hpc.sh | bash
```

以下が自動で行われる：

1. `nix-portable` を `~/.local/bin/` にダウンロード
2. このリポジトリを `~/projects/home-manager` にクローン
3. Home Manager を適用（zsh, Neovim, CLIツール一式をインストール）

完了後 `exec zsh` で新しいシェルを起動する.

### 手動セットアップ

```bash
# nix-portable をダウンロード
mkdir -p ~/.local/bin
curl -L "https://github.com/DavHau/nix-portable/releases/latest/download/nix-portable-$(uname -m)" \
  -o ~/.local/bin/nix-portable
chmod +x ~/.local/bin/nix-portable
export PATH="$HOME/.local/bin:$PATH"

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
└── ~/.nix-portable/store/   ← /nix/store の代替（ユーザ空間）

flake.nix
├── home.nix                 ← Linux/macOS 用（mainブランチ）
└── home-hpc.nix             ← HPC 用（このブランチ）
    ├── modules/zsh/
    └── modules/neovim/
```

nix-portable は `/nix/store` への書き込み権限がない場合,自動的に `~/.nix-portable/store` を使う. user namespace が利用できない環境では proot にフォールバックする.

## トラブルシューティング

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

### Neovimプラグインが更新されない

```vim
:call dein#clear_state()
:q
```

再度 `nvim` を起動すると再構築される.
