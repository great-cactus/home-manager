{ config, pkgs, lib, ... }:

{
  programs.zsh.initContent = lib.mkAfter ''
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

    # ===== PBS client wrappers =====
    # PBS は resvport 認証（特権ポート bind）を使うが、nix-user-chroot の
    # user namespace 内では特権ポートを確保できず認証に失敗する。
    # よって PBS クライアントコマンドはホスト側 (ssh ADb) で実行する。
    # - 引数は printf %q で安全にクォートして転送（空白・特殊文字対策）。
    #   qsub はスクリプトパス・各種オプション等、任意個の引数をそのまま透過する。
    # - cd "$PWD" で実行ディレクトリをホスト側でも合わせる（NFS 共有ホーム前提）。
    #   これにより `qsub job.sh` の相対パスや qsub のデフォルト作業ディレクトリが
    #   手元のカレントと一致する。
    # - stdin は ssh が透過するため `qsub < job.sh` / heredoc もそのまま通る。
    _pbs_host() {
      local cmd=$1; shift
      ssh -o BatchMode=yes ADb "cd $(printf '%q' "$PWD") && $(printf '%q ' "$cmd" "$@")"
    }
    for _c in qstat qsub qdel qhold qrls qalter qmove qselect pbsnodes tracejob; do
      eval "$_c() { _pbs_host $_c \"\$@\"; }"
    done
    unset _c
  '';
}
