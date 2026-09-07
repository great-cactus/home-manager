{ config, pkgs, lib, ... }:

{
  # GPG (pass の前提)
  programs.gpg.enable = true;

  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry-curses;
  };

  # pass (password-store)
  programs.password-store.enable = true;

  # Email account
  accounts.email = {
    maildirBasePath = "Mail";
    accounts.tohoku = {
      primary = true;
      address = "akira.tsunoda.s5@dc.tohoku.ac.jp";
      userName = "akira.tsunoda.s5@dc.tohoku.ac.jp";
      realName = "Akira Tsunoda";
      passwordCommand = "pass mail/tohoku";

      imap = {
        host = "imap.tohoku.ac.jp";
        port = 993;
        tls.enable = true;
      };

      smtp = {
        host = "smtp.tohoku.ac.jp";
        port = 587;
        tls.useStartTls = true;
      };

      mbsync = {
        enable = true;
        create = "maildir";
        expunge = "both";
      };

      msmtp.enable = true;
      notmuch.enable = true;
    };
  };

  # mbsync (IMAP sync)
  programs.mbsync.enable = true;

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

  home.packages = with pkgs; [
    w3m  # notmuch.nvim の HTML メールレンダリング用
  ];
}
