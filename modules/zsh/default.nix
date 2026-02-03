{ config, pkgs, lib, ... }:

{
  imports = [
    ./aliases.nix
    ./functions.nix
  ];

  programs.zsh = {
    enable = true;

    history = {
      size = 1000;
      save = 1000;
      path = "${config.home.homeDirectory}/.histfile";
      ignoreDups = true;
      share = true;
      extended = true;
    };

    autocd = true;
    defaultKeymap = "viins";

    autosuggestion.enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;

    initContent = lib.mkMerge [
      (lib.mkBefore ''
        # ~/.env から環境変数を読み込み (PROMPT_COLOR, WIN_DEVICE等)
        [ -f ~/.local/bin/import-env.sh ] && . ~/.local/bin/import-env.sh ~/.env
      '')
      ''
        setopt extendedglob nomatch correct no_beep appendhistory

        autoload -U colors; colors
        # PROMPT_COLOR, WIN_DEVICE は import-env.sh で .env から読み込み
        PROMPT="%F{$PROMPT_COLOR}%n@''${WIN_DEVICE}%f:%~
>>"

        autoload -U compinit && compinit

        export LSCOLORS=exfxcxdxbxegedabagacad
        export LS_COLORS='di=34:ln=35:so=32:pi=33:ex=31:bd=46;34:cd=43;34:su=41;30:sg=46;30:tw=42;30:ow=43;30'
        zstyle ':completion*' list-colors 'di=34' 'ln=35' 'so=32' 'ex=31' 'bd=46;34' 'cd=43;34'

        # PATH (Nix管理外ツール)
        export PATH="$HOME/.local/bin:$PATH"
        export PATH="$HOME/.deno/bin:$PATH"
        export PATH="$HOME/.nodejs/bin:$PATH"
        export PATH="$HOME/.cargo/bin:$PATH"
        export PATH="$HOME/.juliaup/bin:$PATH"
        export PATH="$HOME/.npm-global/bin:$PATH"
        export PATH="$HOME/projects/vim/src:$PATH"
        export PATH="$HOME/intelpython3/bin:$PATH"

        export PYTHONPATH="$HOME/pythonScripts/_modules:$PATH"
        export DENO_INSTALL="$HOME/.deno"

        # CUDA
        if [ -d "/usr/local/cuda-12" ]; then
          export CUDA_PATH=/usr/local/cuda-12
          export LD_LIBRARY_PATH=$CUDA_PATH/lib64:$LD_LIBRARY_PATH
          export PATH=$CUDA_PATH/bin:$PATH
        fi

        # Paraview
        [ -f /opt/paraview/bin/paraview ] && export PATH=/opt/paraview/bin:$PATH

        # NVM
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

        # FZF
        [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

        # Cargo
        [ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

        # WSL
        export PULSE_SERVER=/mnt/wslg/PulseServer
      ''
    ];
  };
}
