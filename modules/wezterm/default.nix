{ config, lib, ... }:

let
  weztermDir = "/mnt/c/Users/${config.home.username}/.config/wezterm";
in {
  # WSL環境のみ: WezTerm設定をWindows側にコピー
  # (WSL↔NTFS間はシンボリックリンクが使えないためコピー)
  home.activation.installWeztermConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ -d /mnt/c ]; then
      $DRY_RUN_CMD mkdir -p "${weztermDir}"
      $DRY_RUN_CMD cp -f ${./wezterm.lua} "${weztermDir}/wezterm.lua"
      $DRY_RUN_CMD cp -f ${./keybinds.lua} "${weztermDir}/keybinds.lua"
      $DRY_RUN_CMD cp -f ${./workspace.lua} "${weztermDir}/workspace.lua"
    fi
  '';
}
