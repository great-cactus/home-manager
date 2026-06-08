# Home Manager for HPC

root権限なしのHPCクラスタに [nix-user-chroot](https://github.com/nix-community/nix-user-chroot) で開発環境を構築する.

nix-user-chroot はユーザー名前空間を使って `~/.nix` を `/nix` にマウントし, 通常の Nix 環境を提供する.
[nix-portable](https://github.com/DavHau/nix-portable) (proot) より安定かつ高速.

## 前提条件

- ユーザー名前空間が有効であること（`unshare --user --pid echo YES` で確認）
- `curl`, `git` が使用可能であること

## セットアップ

### ワンライナー

```bash
curl -sL https://raw.githubusercontent.com/great-cactus/home-manager/hpc/scripts/bootstrap-hpc.sh | bash
```

以下が自動で行われる：

1. `nix-user-chroot` を `~/.local/bin/` にダウンロード
2. `~/.nix` に Nix をインストール（Lustre 対策の `nix.conf` も自動生成）
3. このリポジトリを `~/projects/home-manager` にクローン
4. Home Manager を適用（zsh, Neovim, CLIツール一式をインストール）
5. `.bashrc` に自動エントリーを追加

完了後 `exec bash` で新しいシェルを起動する（自動的に chroot + zsh に切り替わる）.

### 手動セットアップ

```bash
# nix-user-chroot をダウンロード
mkdir -p ~/.local/bin
curl -fL "https://github.com/nix-community/nix-user-chroot/releases/download/2.1.1/nix-user-chroot-bin-2.1.1-x86_64-unknown-linux-musl" \
  -o ~/.local/bin/nix-user-chroot
chmod +x ~/.local/bin/nix-user-chroot
export PATH="$HOME/.local/bin:$PATH"

# Nix ストア用ディレクトリを作成
mkdir -p ~/.nix

# Lustre 対策の nix.conf を作成
mkdir -p ~/.config/nix
cat > ~/.config/nix/nix.conf << 'EOF'
ignored-acls = lustre.lov
sandbox = false
EOF

# Nix をインストール（LD_LIBRARY_PATH を空にして HPC module 汚染を回避）
LD_LIBRARY_PATH= nix-user-chroot ~/.nix bash -c \
  "curl -L https://nixos.org/nix/install | bash"

# リポジトリをクローン
git clone -b hpc https://github.com/great-cactus/home-manager.git ~/projects/home-manager

# Home Manager を適用
LD_LIBRARY_PATH= nix-user-chroot ~/.nix bash -c \
  ". ~/.nix-profile/etc/profile.d/nix.sh && cd ~/projects/home-manager && nix run --impure .#homeConfigurations.hpc.activationPackage"

# シェルを再読み込み
exec bash
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

chroot 内（通常のログイン後）で直接実行する：

```bash
cd ~/projects/home-manager
git pull origin hpc
nix run --impure .#homeConfigurations.hpc.activationPackage
```

## 仕組み

```
~/.nix/                         <- Nix ストア（nix-user-chroot が /nix にマウント）
~/.local/bin/nix-user-chroot    <- chroot バイナリ
~/.config/nix/nix.conf          <- Lustre 対策設定
~/.bashrc                       <- 自動エントリー（chroot + zsh 起動）

flake.nix
├── home.nix                    <- Linux/macOS 用（main ブランチ）
└── home-hpc.nix                <- HPC 用（このブランチ）
    ├── modules/zsh/
    └── modules/neovim/
```

**ログインの流れ：**

```
SSH ログイン → bash 起動
  → .bashrc の自動エントリーが /nix 不在を検出
  → nix-user-chroot が ~/.nix を /nix にマウント
  → Nix 管理の zsh がログインシェルとして起動
  → Home Manager で管理された環境が利用可能に
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

## nix-portable からの移行

以前 nix-portable を使っていた場合、以下で旧環境を削除できる：

```bash
rm -f ~/.local/bin/nix-portable
rm -f ~/.local/bin/nix-portable-env.sh
rm -rf /tmp/$USER/nix-portable
```

`.bashrc` から `nix-portable-env.sh` の source 行があれば手動で削除する.

## トラブルシューティング

### "User namespace is not available" エラー

`unshare --user` がブロックされている. システム管理者に確認する：

```bash
# カーネルパラメータの確認
cat /proc/sys/user/max_user_namespaces
# 0 の場合は無効化されている
```

### "removing extended attribute 'lustre.lov'" エラー

`~/.config/nix/nix.conf` に以下が設定されているか確認する：

```
ignored-acls = lustre.lov
```

### "CXXABI not found" / リンクエラー

HPC module の `LD_LIBRARY_PATH` が Nix のライブラリと競合している. chroot 進入時に `LD_LIBRARY_PATH=` で空にしているか確認する.

手動で nix コマンドを実行する場合：

```bash
LD_LIBRARY_PATH= nix-user-chroot ~/.nix bash -l
```

### "unable to create thread" (flake/libgit2 エラー)

一部の環境で flake 使用時に libgit2 がスレッド作成に失敗する場合がある. 回避策：

```bash
# チャンネル経由で home-manager をインストール
nix-user-chroot ~/.nix bash -c "
  . ~/.nix-profile/etc/profile.d/nix.sh
  nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
  nix-channel --update
  nix-shell '<home-manager>' -A install
"
```

### chroot に入らずにログインしたい

```bash
SKIP_NIX_CHROOT=1 bash
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
