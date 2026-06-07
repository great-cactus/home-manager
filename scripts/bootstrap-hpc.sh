#!/bin/bash
# HPC環境に nix-portable をセットアップし Home Manager を適用するスクリプト
# 使用法: bash bootstrap-hpc.sh
set -euo pipefail

NP_BIN="$HOME/.local/bin/nix-portable"
REPO_URL="https://github.com/great-cactus/home-manager.git"
REPO_DIR="$HOME/projects/home-manager"

echo "=== HPC Nix-Portable Bootstrap ==="

# 1. nix-portable のダウンロード
if [ -f "$NP_BIN" ]; then
  echo "[skip] nix-portable already exists at $NP_BIN"
else
  echo "[1/4] Downloading nix-portable..."
  mkdir -p "$(dirname "$NP_BIN")"
  curl -L "https://github.com/DavHau/nix-portable/releases/latest/download/nix-portable-$(uname -m)" \
    -o "$NP_BIN"
  chmod +x "$NP_BIN"
  echo "[done] nix-portable installed at $NP_BIN"
fi

# 2. PATH に ~/.local/bin を追加（未設定の場合）
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
  export PATH="$HOME/.local/bin:$PATH"
  echo "[info] Added ~/.local/bin to PATH for this session"
fi

# 3. リポジトリのクローン
if [ -d "$REPO_DIR" ]; then
  echo "[skip] Repository already exists at $REPO_DIR"
  cd "$REPO_DIR"
  git fetch origin
  git checkout hpc
  git pull origin hpc
else
  echo "[2/4] Cloning home-manager repository..."
  mkdir -p "$(dirname "$REPO_DIR")"
  git clone -b hpc "$REPO_URL" "$REPO_DIR"
  cd "$REPO_DIR"
fi

# 4. Home Manager の適用
echo "[3/4] Applying Home Manager configuration..."
nix-portable nix run --impure .#homeConfigurations.hpc.activationPackage

echo "[4/4] Setup complete!"
echo ""
echo "=== 次回以降の使い方 ==="
echo "  # 設定の更新"
echo "  cd $REPO_DIR && nix-portable nix run --impure .#homeConfigurations.hpc.activationPackage"
echo ""
echo "  # nix-portable 経由でパッケージを実行"
echo "  nix-portable nix shell nixpkgs#<package>"
echo ""
echo "  # シェルを再読み込み"
echo "  exec zsh"
