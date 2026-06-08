#!/bin/bash
# HPC環境に nix-user-chroot で Nix + Home Manager をセットアップするスクリプト
# 使用法: bash bootstrap-hpc.sh
#
# nix-user-chroot はユーザー名前空間を使って ~/.nix を /nix にマウントし、
# root権限なしで通常の Nix 環境を提供する。
# nix-portable (proot) より安定かつ高速。
#
# 参考: https://zenn.dev/ultimatile/articles/nvim-supercomputer-nix
set -euo pipefail

NUC_VERSION="2.1.1"
NUC_BIN="$HOME/.local/bin/nix-user-chroot"
NIX_STORE="$HOME/.nix"
NIX_CONF="$HOME/.config/nix/nix.conf"
REPO_URL="https://github.com/great-cactus/home-manager.git"
REPO_DIR="$HOME/projects/home-manager"

echo "=== HPC Nix-User-Chroot Bootstrap ==="

# 0. ユーザー名前空間の確認
echo "[check] Verifying user namespace support..."
if unshare --user --pid echo YES 2>/dev/null; then
  echo "  -> OK"
else
  echo "[error] User namespace is not available on this system."
  echo "  nix-user-chroot requires user namespace support (unshare --user)."
  echo "  システム管理者に user.max_user_namespaces の設定を確認してください."
  exit 1
fi

# 1. nix-user-chroot のダウンロード
if [ -f "$NUC_BIN" ]; then
  echo "[skip] nix-user-chroot already exists at $NUC_BIN"
else
  echo "[1/5] Downloading nix-user-chroot v${NUC_VERSION}..."
  mkdir -p "$(dirname "$NUC_BIN")"
  curl -fL "https://github.com/nix-community/nix-user-chroot/releases/download/${NUC_VERSION}/nix-user-chroot-bin-${NUC_VERSION}-x86_64-unknown-linux-musl" \
    -o "$NUC_BIN"
  chmod +x "$NUC_BIN"
  echo "  -> Installed at $NUC_BIN"
fi

# 2. PATH に ~/.local/bin を追加（未設定の場合）
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
  export PATH="$HOME/.local/bin:$PATH"
fi

# 3. Nix ストアの作成 & nix.conf の設定
mkdir -p "$NIX_STORE"
mkdir -p "$(dirname "$NIX_CONF")"
if [ -f "$NIX_CONF" ] && ! [ -L "$NIX_CONF" ]; then
  echo "[skip] nix.conf already exists at $NIX_CONF"
else
  # シンボリックリンク（home-manager管理）の場合は実ファイルで上書き
  rm -f "$NIX_CONF"
  cat > "$NIX_CONF" << 'EOF'
# Lustre ファイルシステムの拡張属性エラーを回避
ignored-acls = lustre.lov
# ユーザー名前空間内でのビルドサンドボックスを無効化
sandbox = false
EOF
  echo "[info] Created $NIX_CONF"
fi

# 4. Nix のインストール
if [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
  echo "[skip] Nix is already installed"
else
  echo "[2/5] Installing Nix via nix-user-chroot..."
  # LD_LIBRARY_PATH を空にして HPC module の汚染を回避
  LD_LIBRARY_PATH= "$NUC_BIN" "$NIX_STORE" bash -c \
    "curl -L https://nixos.org/nix/install | bash"
  echo "  -> Nix installed"
fi

# 5. リポジトリのクローン
if [ -d "$REPO_DIR" ]; then
  echo "[skip] Repository already exists at $REPO_DIR"
  cd "$REPO_DIR"
  git fetch origin
  git checkout hpc
  git pull origin hpc
else
  echo "[3/5] Cloning home-manager repository..."
  mkdir -p "$(dirname "$REPO_DIR")"
  git clone -b hpc "$REPO_URL" "$REPO_DIR"
  cd "$REPO_DIR"
fi

# 6. Home Manager の適用
echo "[4/5] Applying Home Manager configuration..."
LD_LIBRARY_PATH= "$NUC_BIN" "$NIX_STORE" bash -c \
  ". \$HOME/.nix-profile/etc/profile.d/nix.sh && cd '$REPO_DIR' && nix run --impure .#homeConfigurations.hpc.activationPackage"

# 7. .bashrc に自動エントリーを追加
echo "[5/5] Configuring auto-enter..."
BASHRC="$HOME/.bashrc"
MARKER="# nix-user-chroot auto-enter"

if [ -f "$BASHRC" ] && grep -q "$MARKER" "$BASHRC"; then
  echo "[skip] Auto-enter already configured in .bashrc"
else
  cat >> "$BASHRC" << 'BASHEOF'

# nix-user-chroot auto-enter
# インタラクティブシェルで自動的に Nix chroot 環境に入る
# 無効化: SKIP_NIX_CHROOT=1 bash でログイン
if [ ! -d /nix ] && [ -x "$HOME/.local/bin/nix-user-chroot" ] && [[ $- == *i* ]] && [ -z "${SKIP_NIX_CHROOT:-}" ]; then
  if [ -x "$HOME/.nix-profile/bin/zsh" ]; then
    exec env LD_LIBRARY_PATH= "$HOME/.local/bin/nix-user-chroot" "$HOME/.nix" \
      "$HOME/.nix-profile/bin/zsh" -l
  else
    exec env LD_LIBRARY_PATH= "$HOME/.local/bin/nix-user-chroot" "$HOME/.nix" \
      /bin/bash -l
  fi
fi
BASHEOF
  echo "  -> Added auto-enter to $BASHRC"
fi

echo ""
echo "=== Setup complete! ==="
echo ""
echo "次のステップ:"
echo "  exec bash    # シェル再起動（自動的に Nix chroot + zsh に入ります）"
echo ""
echo "以降の設定更新（chroot 内で直接実行）:"
echo "  cd $REPO_DIR"
echo "  nix run --impure .#homeConfigurations.hpc.activationPackage"
echo ""
echo "chroot に入らずにログインしたい場合:"
echo "  SKIP_NIX_CHROOT=1 bash"
echo ""
echo "旧 nix-portable 環境の削除（任意）:"
echo "  rm -f ~/.local/bin/nix-portable ~/.local/bin/nix-portable-env.sh"
echo "  rm -rf /tmp/\$USER/nix-portable"
