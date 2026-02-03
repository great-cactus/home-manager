#!/bin/bash
# .envファイルから環境変数を読み込むスクリプト
# 使用法: source import-env.sh ~/.env

while IFS= read -r line; do
  # 空行またはコメント行をスキップ
  if [[ "$line" =~ ^[[:space:]]*$ ]] || [[ "$line" =~ ^# ]]; then
    continue
  fi

  # キーと値を分割
  IFS="=" read -r key value <<< "$line"

  # 空白を削除し、エクスポート
  key=$(echo "$key" | xargs)
  value=$(echo "$value" | xargs)

  # エクスポート処理
  export "$key=$value"
done < "$1"
