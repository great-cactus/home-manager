{ pkgs, ... }:

let
  # matplotlib reads user styles from <configdir>/stylelib/,
  # where configdir is ~/.config/matplotlib on Linux and ~/.matplotlib on macOS.
  mplConfigDir = if pkgs.stdenv.isDarwin then ".matplotlib" else ".config/matplotlib";
in
{
  home.file."${mplConfigDir}/stylelib/cudo-paper.mplstyle".source = ./cudo-paper.mplstyle;
  # On PYTHONPATH (see modules/zsh); `import cudo` registers "cudo:<name>" colors.
  home.file."pythonScripts/_modules/cudo.py".source = ./cudo.py;
}
