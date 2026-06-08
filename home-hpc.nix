{ config, pkgs, lib, username, homeDirectory, ... }:

{
  home.username = username;
  home.homeDirectory = homeDirectory;
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.git = {
    settings = {
      core.quotepath = false;
    };
  };

  imports = [
    ./modules/zsh
    ./modules/neovim
  ];

  home.packages = with pkgs; [
    gh
    uv
    fzf
    cargo
    deno
    nodejs_24
    ripgrep
    trash-cli
    ffmpeg
  ];

  # Nix 設定（nix-user-chroot 環境向け）
  home.file.".config/nix/nix.conf".text = ''
    experimental-features = nix-command flakes
    ignored-acls = lustre.lov
    sandbox = false
  '';

  # import-env.sh を ~/.local/bin に配置
  home.file.".local/bin/import-env.sh" = {
    source = ./scripts/import-env.sh;
    executable = true;
  };

  # WezTerm terminfo (SSH経由でもundercurl/色付き下線を有効にする)
  home.file.".terminfo/w/wezterm".source =
    "${pkgs.wezterm.terminfo}/share/terminfo/w/wezterm";

  home.sessionVariables = {
    EDITOR = "nvim";
    LANGUAGE = "en_US.UTF-8";
    LC_ALL = "C.UTF-8";
    LANG = "C.UTF-8";
    LESSCHARSET = "utf-8";
  };

  home.activation.createSkkDirs = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p "${config.home.homeDirectory}/.cache/skk"
    mkdir -p "${config.home.homeDirectory}/.skk"
  '';
}
