{ pkgs, ... }:

let
  # matplotlib reads user styles from <configdir>/stylelib/,
  # where configdir is ~/.config/matplotlib on Linux and ~/.matplotlib on macOS.
  mplConfigDir = if pkgs.stdenv.isDarwin then ".matplotlib" else ".config/matplotlib";
in
{
  home.file."${mplConfigDir}/stylelib/cudo-paper.mplstyle".source = ./cudo-paper.mplstyle;
}
