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
    ./modules/claude
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
    llama-cpp
    claude-code
  ];

  # import-env.sh を ~/.local/bin に配置
  home.file.".local/bin/import-env.sh" = {
    source = ./scripts/import-env.sh;
    executable = true;
  };

  home.sessionVariables = {
    EDITOR = "nvim";
    LANGUAGE = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    LANG = "ja_JP.UTF-8";
  };

  home.activation.createSkkDirs = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p "${config.home.homeDirectory}/.cache/skk"
    mkdir -p "${config.home.homeDirectory}/.skk"
  '';

  # WSLg が PulseAudio を提供するため、systemd の pulseaudio サービスをマスクする
  home.activation.maskPulseaudioForWSLg = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ -e /mnt/wslg ]; then
      $DRY_RUN_CMD systemctl --user mask pulseaudio.service pulseaudio.socket 2>/dev/null || true
    fi
  '';
}
