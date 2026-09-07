{ config, pkgs, lib, ... }:

let
  mutt-oauth2 = "${pkgs.neomutt}/share/neomutt/oauth2/mutt_oauth2.py";
  tokenFile = "${config.home.homeDirectory}/.cache/mail/oauth2-tohoku.gpg";

  # OAuth2 アクセストークンを取得するラッパー（mbsync/msmtp の PassCmd 用）
  mail-oauth2 = pkgs.writeShellScriptBin "mail-oauth2" ''
    export GPG_TTY=$(tty)
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
        create = "maildir";
        expunge = "both";
        extraConfig.account = {
          AuthMechs = "XOAUTH2";
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

  # msmtp (SMTP send)
  programs.msmtp.enable = true;

  # notmuch (mail indexer)
  programs.notmuch = {
    enable = true;
    new.tags = [ "new" "unread" "inbox" ];
    search.excludeTags = [ "deleted" "spam" ];
  };

  # notmuch.nvim が libnotmuch.so を FFI で読み込むためライブラリパスを追加
  programs.neovim.extraWrapperArgs = [
    "--prefix" "LD_LIBRARY_PATH" ":" "${pkgs.notmuch}/lib"
  ];

  home.packages = [
    mail-oauth2
    mail-oauth2-authorize
    pkgs.w3m  # notmuch.nvim の HTML メールレンダリング用
  ];


  home.activation.createMailOAuth2Dir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "${config.home.homeDirectory}/.cache/mail"
  '';
}
