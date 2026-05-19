# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## コマンド

### 設定の適用

```bash
# Linux (x86_64)
nix run .#homeConfigurations.linux.activationPackage

# macOS (Apple Silicon)
nix run .#homeConfigurations.macos.activationPackage
```

### 依存パッケージの更新

```bash
nix flake update
```

### 開発シェルの起動

```bash
nix develop
```

## アーキテクチャ

### エントリーポイント

- `flake.nix`: Flake定義。`nixpkgs`, `home-manager`, `claude-code-nix` を依存に持ち、`linux`（x86_64）と `macos`（aarch64）の2環境を定義する。ユーザー名とホームディレクトリは環境ごとに `extraSpecialArgs` で渡され、`home.nix` 内には直書きしない。
- `home.nix`: Home Manager設定のルート。パッケージ一覧・セッション変数・activation scriptはここで管理する。`modules/zsh`, `modules/neovim`, `modules/claude` をインポートする（`modules/obsidian` は現在インポートされていない）。

### モジュール構成

各モジュールは `default.nix` を持ち、`home.nix` から `import` される。

| モジュール | 役割 |
|---|---|
| `modules/zsh/` | zsh本体設定・エイリアス・カスタム関数 |
| `modules/neovim/` | Neovim設定（dein.vim + Lua config + LSP + スニペット） |
| `modules/claude/` | `~/.claude/rules/` と `~/.claude/skills/` へのシンボリックリンク定義 |

### Claude モジュールの仕組み

`modules/claude/default.nix` は `home.file` を使って `modules/claude/rules/*.md` と `modules/claude/skills/*/SKILL.md` を `~/.claude/` 以下に配置する。**ファイルを追加・削除した場合は必ず `default.nix` の `home.file` マッピングも更新すること。**

- `rules/`: Claude Codeがグローバルルールとして参照する `.md` ファイル群
- `skills/`: `/skill-name` で呼び出せるカスタムスキル（各ディレクトリに `SKILL.md` 1ファイル）

### 環境変数の動的管理

`scripts/import-env.sh` が `~/.local/bin/` に配置され、`~/.env` ファイルから `PROMPT_COLOR` や `WIN_DEVICE` などの動的変数を読み込む。静的な変数は `home.nix` の `home.sessionVariables` で管理する。
