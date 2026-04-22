{ config, pkgs, lib, ... }:

let
  nvim-treesitter-with-parsers =
    let ts = pkgs.vimPlugins.nvim-treesitter;
    in pkgs.symlinkJoin {
      name = "nvim-treesitter-with-parsers";
      paths = [
        ts
        (ts.withPlugins (p: with p; [
          bash cpp diff fortran javascript julia kotlin
          latex lua markdown markdown_inline nix python
          query regex toml typescript typst vimdoc
        ]))
      ];
    };

  # dein.vim をインストーラが期待するパスに配置するための derivation
  # installer.sh は ~/.cache/dein/repos/github.com/Shougo/dein.vim を前提とする
  dein-vim-src = pkgs.fetchFromGitHub {
    owner = "Shougo";
    repo  = "dein.vim";
    rev   = "32cd283e564511d26cb25c6bc00d573183563c32";
    hash  = "sha256-/DmbdiFO1O/fz4biTAynRJ0JgAp8FbY7XMW1oO9kCnM=";
  };

  # ~/.config/nvim/lua/config/ に配置する個別 .lua ファイル一覧
  nvimLuaConfigFiles = lib.filterAttrs
    (n: v: v == "regular" && lib.hasSuffix ".lua" n)
    (builtins.readDir ./nvim/lua/config);

  ddcDictPath = "${pkgs.scowl}/share/dict/wamerican.txt";

in {
  programs.neovim = {
    enable = true;
    package = pkgs.neovim-unwrapped;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    withRuby = false;
    withPython3 = true;

    initLua = builtins.readFile ./init.lua;
  };

  home.file = {
    # treesitter パーサ（既存）
    ".cache/dein/_generated/nvim-treesitter".source =
      nvim-treesitter-with-parsers;

    # dein.vim をインストーラが期待するパスに配置（読み取り専用でよい）
    ".cache/dein/repos/github.com/Shougo/dein.vim".source = dein-vim-src;
  };

  xdg.configFile = {
    # dein プラグイン定義（~/.cache/dein/ ではなく ~/.config/nvim/dein/ に置く）
    # → dein のステートキャッシュ（~/.cache/dein/）と分離する
    "nvim/dein/dein.toml".source      = ./dein.toml;
    "nvim/dein/dein_lazy.toml".text = builtins.replaceStrings
      [ "/usr/share/dict/american-english" ]
      [ ddcDictPath ]
      (builtins.readFile ./dein_lazy.toml);

    # ディレクトリ単位でリンク
    "nvim/colors".source    = ./nvim/colors;
    "nvim/queries".source   = ./nvim/queries;
    "nvim/snippets".source  = ./nvim/snippets;
    "nvim/templates".source = ./nvim/templates;
    "nvim/lua/lsp".source     = ./nvim/lua/lsp;
    "nvim/lua/plugins".source = ./nvim/lua/plugins;
  }
  # lua/config/ の個別 .lua ファイルをファイル単位でリンク
  // lib.mapAttrs' (name: _: {
    name  = "nvim/lua/config/${name}";
    value.source = ./nvim/lua/config + "/${name}";
  }) nvimLuaConfigFiles;
}
