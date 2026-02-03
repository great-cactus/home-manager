{ config, pkgs, lib, ... }:

{
  programs.zsh.initExtra = lib.mkAfter ''
    spsync() {
      rsync -ahvum --progress --include="*/" --include="$1" --exclude="*" "$2" "$3"
    }

    targz() {
      if [[ "$1" == *.tar.gz ]]; then
        tar -xvf "$1"
      else
        tar -zcvf "$1.tar.gz" "$1"
      fi
    }

    tarxz() {
      if [[ "$1" == *.tar.xz ]]; then
        tar -xvf "$1"
      else
        tar -Jcvf "$1.tar.xz" "$1"
      fi
    }

    thumbnailing() {
      ffmpeg -ss 0 -i "$1" -frames:v 1 -q:v 2 "$2"
    }
  '';
}
