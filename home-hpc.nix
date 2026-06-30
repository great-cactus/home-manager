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

  # /etc/profile.d/hpe.sh が source /usr/share/Modules/init/bash をハードコードしており、
  # zsh 起動時に export -f 等の bash 専用構文でエラーが出る（HPCベンダー設定バグ）。
  # ~/.zshenv で stderr を退避・抑制し、~/.zshrc 冒頭で復元する。
  programs.zsh.envExtra = ''
    exec 9>&2 2>/dev/null
  '';
  programs.zsh.initContent = lib.mkOrder 0 ''
    exec 2>&9 9>&-
  '';

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
  home.file.".config/nix/nix.conf" = {
    text = ''
      experimental-features = nix-command flakes
      ignored-acls = lustre.lov
      sandbox = false
    '';
    force = true;
  };

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
