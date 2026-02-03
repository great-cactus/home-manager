{ config, pkgs, lib, ... }:

{
  home.username = "tnd";
  home.homeDirectory = "/home/tnd";
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;

  imports = [
    ./modules/zsh
  ];

  home.packages = with pkgs; [
    gh
    uv
    fzf
    cargo
    deno
    nodejs_24
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
}
