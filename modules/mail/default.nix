{ config, pkgs, lib, ... }:

let
  mutt-oauth2 = "${pkgs.neomutt}/share/neomutt/oauth2/mutt_oauth2.py";
  tokenFile = "${config.home.homeDirectory}/.cache/mail/oauth2-tohoku.gpg";

  # OAuth2 アクセストークンを取得するラッパー（mbsync/msmtp の PassCmd 用）
  mail-oauth2 = pkgs.writeShellScriptBin "mail-oauth2" ''
    export GPG_TTY="''${GPG_TTY:-$(tty)}"
    exec ${pkgs.python3}/bin/python3 ${mutt-oauth2} ${tokenFile}
  '';

  saslPath = "${pkgs.cyrus-sasl-xoauth2}/lib/sasl2:${pkgs.cyrus_sasl.out}/lib/sasl2";

  # mbsync を XOAUTH2 SASL プラグイン付きでラップ
  isync-xoauth2 = pkgs.symlinkJoin {
    name = "isync-xoauth2";
    paths = [ pkgs.isync ];
    buildInputs = [ pkgs.makeBinaryWrapper ];
    postBuild = ''
      wrapProgram $out/bin/mbsync --set SASL_PATH "${saslPath}"
    '';
  };

  # WSL 起動後の初回用: GPG パスフレーズを入力してキャッシュし、即時同期を起動する
  mail-unlock = pkgs.writeShellScriptBin "mail-unlock" ''
    ${mail-oauth2}/bin/mail-oauth2 >/dev/null || exit 1
    systemctl --user start mbsync.service && echo "mbsync started"
  '';

  # 初回認可用スクリプト（対話的に実行）
  mail-oauth2-authorize = pkgs.writeShellScriptBin "mail-oauth2-authorize" ''
    mkdir -p "$(dirname ${tokenFile})"
    exec ${pkgs.python3}/bin/python3 ${mutt-oauth2} \
      --verbose \
      --authorize \
      --provider google \
      --authflow localhostauthcode \
      --client-id "''${1:?Usage: mail-oauth2-authorize <client-id> <client-secret>}" \
      --client-secret "''${2:?Usage: mail-oauth2-authorize <client-id> <client-secret>}" \
      --email akira.tsunoda.e7@tohoku.ac.jp \
      ${tokenFile}
  '';
in
{
  # GPG (pass の前提)
  programs.gpg.enable = true;

  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry-curses;
    defaultCacheTtl = 86400;      # 24h
    maxCacheTtl = 86400;          # 24h
    extraConfig = ''
      allow-loopback-pinentry
    '';
  };

  # pass (password-store)
  programs.password-store = {
    enable = true;
    settings.PASSWORD_STORE_DIR = "$XDG_DATA_HOME/password-store";
  };

  # Email account
  accounts.email = {
    maildirBasePath = "Mail";
    accounts.tohoku = {
      primary = true;
      address = "akira.tsunoda.e7@tohoku.ac.jp";
      userName = "akira.tsunoda.e7@tohoku.ac.jp";
      realName = "Akira Tsunoda";
      passwordCommand = "${mail-oauth2}/bin/mail-oauth2";

      imap = {
        host = "imap.gmail.com";
        port = 993;
        tls.enable = true;
      };

      smtp = {
        host = "smtp.gmail.com";
        port = 587;
        tls.useStartTls = true;
      };

      mbsync = {
        enable = true;
        extraConfig.account = {
          AuthMechs = "XOAUTH2";
        };
        # 2 チャンネル構成:
        # - main: Inbox・ラベル・送信済みを通常同期（フラグ・削除も双方向）
        # - archive: 「すべてのメール」は新着取込のみ (Sync New)。
        #   全複製 (約 4 万通) のフラグ照合を毎回行わないため高速。
        #   副作用: Gmail 側で削除したメールはローカルに残る
        groups.tohoku.channels = {
          main = {
            patterns = [ "*" "![Gmail]*" "[Gmail]/送信済みメール" ];
            extraConfig = {
              Create = "Near";
              Expunge = "Both";
              SyncState = "*";
            };
          };
          archive = {
            farPattern = "[Gmail]/すべてのメール";
            nearPattern = "[Gmail]/すべてのメール";
            extraConfig = {
              Create = "Near";
              Sync = "New";
              SyncState = "*";
            };
          };
        };
      };

      msmtp = {
        enable = true;
        extraConfig = {
          auth = "xoauth2";
        };
      };

      notmuch.enable = true;
    };
  };

  # mbsync (IMAP sync)
  programs.mbsync = {
    enable = true;
    package = isync-xoauth2;
  };

  # 5 分毎に systemd user timer で同期し、続けて notmuch new を実行する。
  # WSL 起動直後は GPG 未キャッシュのため失敗し続ける → `mail-unlock` を一度実行する
  services.mbsync = {
    enable = true;
    package = isync-xoauth2;
    frequency = "*:0/5";
  };

  systemd.user.services.mbsync.Service = {
    # systemd user 環境の PATH には nix profile が無いため、
    # mutt_oauth2.py が呼ぶ gpg と notmuch hook の基本コマンドを明示する
    Environment = [
      "PATH=${lib.makeBinPath [ config.programs.gpg.package pkgs.coreutils ]}"
      "NOTMUCH_CONFIG=${config.xdg.configHome}/notmuch/default/config"
    ];
    # ExecStopPost は mbsync が途中で失敗しても走る（Gmail の帯域制限で
    # 切断された場合など）→ 取込済みの分だけでも索引する
    ExecStopPost = "${config.programs.notmuch.package}/bin/notmuch new";
  };

  # msmtp (SMTP send)
  programs.msmtp.enable = true;

  # notmuch (mail indexer)
  programs.notmuch = {
    enable = true;
    new.tags = [ "new" "unread" ];
    search.excludeTags = [ "deleted" "spam" ];

    # Gmail のフォルダ構成を notmuch タグに反映する
    # - Inbox フォルダにある物だけ inbox（Gmail 側でアーカイブすると外れる）
    # - ラベル（サブフォルダ）は同名タグ。Inbox と [Gmail] は除外
    # フォルダ名は実行時に走査するため、ラベル追加時の編集は不要
    hooks.postNew = ''
      maildir="${config.accounts.email.accounts.tohoku.maildir.absPath}"

      notmuch tag +inbox -- tag:new and folder:tohoku/Inbox
      notmuch tag -inbox -- tag:inbox and not folder:tohoku/Inbox

      for dir in "$maildir"/*/; do
        name=$(basename "$dir")
        case "$name" in Inbox|"[Gmail]") continue ;; esac
        notmuch tag "+$name" -- tag:new and "folder:tohoku/$name"
        notmuch tag "-$name" -- "tag:$name" and not "folder:tohoku/$name"
      done

      notmuch tag -new -- tag:new
    '';
  };

  # notmuch.nvim が libnotmuch.so を FFI で読み込むためライブラリパスを追加
  programs.neovim.extraWrapperArgs = [
    "--prefix" "LD_LIBRARY_PATH" ":" "${pkgs.notmuch}/lib"
  ];

  home.packages = [
    mail-oauth2
    mail-oauth2-authorize
    mail-unlock
    pkgs.w3m     # notmuch.nvim の HTML メールレンダリング用
    pkgs.pandoc  # notmuch.nvim の Office 添付プレビュー用
    pkgs.unzip   # notmuch.nvim の ZIP 添付一覧用
  ];


  home.activation.createMailOAuth2Dir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "${config.home.homeDirectory}/.cache/mail"
  '';
}
