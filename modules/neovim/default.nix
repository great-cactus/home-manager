{ config, pkgs, lib, ... }:

let
  nvim-treesitter-with-parsers =
    let
      ts = pkgs.vimPlugins.nvim-treesitter;
      withParsers = ts.withPlugins (p: with p; [
        bash cpp diff fortran javascript julia
        latex lua markdown markdown_inline nix python
        query regex toml typescript typst vimdoc
      ]);
    in pkgs.symlinkJoin {
      name = "nvim-treesitter-with-parsers";
      # withPlugins はパーサ .so を passthru.dependencies に格納するため
      # symlinkJoin で ts (Lua ファイル) + 各パーサ derivation を結合する
      paths = [ ts ] ++ withParsers.dependencies;
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

  # OALD (Oxford Advanced Learner's Dictionary) StarDict形式
  # sdcv で英英辞書として使用する
  oald-stardict = pkgs.runCommand "oald-stardict" {
    src = pkgs.fetchurl {
      url = "https://archive.org/download/stardict_collections/archives-english/en-head/Oxford_Advanced_Learner_s_Dictionary.tar.gz";
      name = "oald.tar.gz";
      sha256 = "0pyi9nfc4q869gxankyzbsmavlsr025yl6vivw96ca3qdsmc8kpq";
    };
    nativeBuildInputs = [ pkgs.gnutar pkgs.gzip ];
  } ''
    mkdir -p $out
    tar xzf $src -C $out
  '';

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

    # LSPサーバーをNixで直接提供する
    extraPackages = with pkgs; [
      python3Packages.python-lsp-server  # pylsp
      texlab
      ltex-ls
      efm-langserver
      lua-language-server                # lua_ls
      nil                                # nil_ls
      fortls
      copilot-language-server            # copilot_ls (NES)
      sdcv                               # StarDict console dictionary
    ];
  };

  home.file = {
    # treesitter パーサ（既存）
    ".cache/dein/_generated/nvim-treesitter" = {
      source = nvim-treesitter-with-parsers;
      force = true;
    };

    # dein.vim をインストーラが期待するパスに配置（読み取り専用でよい）
    ".cache/dein/repos/github.com/Shougo/dein.vim" = {
      source = dein-vim-src;
      force = true;
    };

    # OALD StarDict辞書（sdcv のデフォルト検索パス）
    ".stardict/dic/oald" = {
      source = oald-stardict;
    };
  };

  # Nix store 上の TOML は mtime が固定で dein が変更を検知できないため、
  # 適用のたびにステートキャッシュを消して次回起動時に再生成させる
  # (dein#clear_state() と同等)
  home.activation.clearDeinState = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD rm -f "${config.home.homeDirectory}"/.cache/dein/.cache/*/state_*.vim \
                       "${config.home.homeDirectory}"/.cache/dein/.cache/*/cache_*
  '';

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
