#!/bin/bash
# HPC環境に nix-portable をセットアップし Home Manager を適用するスクリプト
# 使用法: bash bootstrap-hpc.sh
#
# Lustre ファイルシステム上ではNixがxattr操作に失敗するため,
# NP_LOCATION でローカルディスク（/tmp）にNixストアを配置する.
set -euo pipefail

NP_BIN="$HOME/.local/bin/nix-portable"
NP_STORE="/tmp/$USER/nix-portable"
REPO_URL="https://github.com/great-cactus/home-manager.git"
REPO_DIR="$HOME/projects/home-manager"
ENV_SETUP="$HOME/.local/bin/nix-portable-env.sh"

echo "=== HPC Nix-Portable Bootstrap ==="

# 1. nix-portable のダウンロード
if [ -f "$NP_BIN" ]; then
  echo "[skip] nix-portable already exists at $NP_BIN"
else
  echo "[1/5] Downloading nix-portable..."
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

# 3. Nixストア用ディレクトリを作成 & サンドボックス無効化
mkdir -p "$NP_STORE"
export NP_LOCATION="$NP_STORE"
export NIX_CONFIG="sandbox = false"
echo "[info] Nix store location: $NP_STORE"

# 4. リポジトリのクローン
if [ -d "$REPO_DIR" ]; then
  echo "[skip] Repository already exists at $REPO_DIR"
  cd "$REPO_DIR"
  git fetch origin
  git checkout hpc
  git pull origin hpc
else
  echo "[2/5] Cloning home-manager repository..."
  mkdir -p "$(dirname "$REPO_DIR")"
  git clone -b hpc "$REPO_URL" "$REPO_DIR"
  cd "$REPO_DIR"
fi

# 5. 環境変数ヘルパースクリプトを生成
cat > "$ENV_SETUP" << 'ENVEOF'
# nix-portable 環境変数（.zshrc や .bashrc から source する）
export NP_LOCATION="/tmp/$USER/nix-portable"
export NIX_CONFIG="sandbox = false"
export PATH="$HOME/.local/bin:$PATH"
ENVEOF
echo "[done] Created $ENV_SETUP"

# 6. 既存のランタイムキャッシュをクリア（NP_LOCATION変更時の不整合回避）
rm -f "$NP_STORE/.nix-portable/conf/nix.conf" 2>/dev/null || true

# 7. Home Manager の適用
echo "[3/5] Applying Home Manager configuration..."
nix-portable nix run --option sandbox false --impure .#homeConfigurations.hpc.activationPackage

echo "[4/5] Setup complete!"
echo ""
echo "=== 重要 ==="
echo "  Nixストアは /tmp 上にあるため,以下を .bashrc または .zshrc に追加してください："
echo ""
echo "    source ~/.local/bin/nix-portable-env.sh"
echo ""
echo "=== 次回以降の使い方 ==="
echo "  # 設定の更新"
echo "  cd $REPO_DIR && nix-portable nix run --impure .#homeConfigurations.hpc.activationPackage"
echo ""
echo "  # シェルを再読み込み"
echo "  exec zsh"
