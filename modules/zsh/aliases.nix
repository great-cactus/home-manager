{ config, pkgs, lib, ... }:

{
  programs.zsh.shellAliases = {
    ls = "ls --color";
    ll = "ls -lrthG";
    vi = "nvim";

    # Git
    gst = "git status";
    ga = "git add";
    gl = "git log --oneline";
    gc = "git commit";
    gpom = "git push origin main";
    gd = "git diff";

    # Rsync
    mysync = "rsync -ahvu --progress";

    # Cantera
    cjob = "nohup python cf_auto.py &";
    fjob = "nohup python free_auto.py &";
    mjob = "nohup python main.py &";

    # NAS
    mnt = ''sudo mount -t cifs -o "username=admin,uid=1000,gid=1000,iocharset=utf8" ${NAS_PATH}/Public /mnt/nas'';
    uGmnt = ''sudo mount -t cifs -o "username=admin,uid=1000,gid=1000,iocharset=utf8" ${NAS_PATH}/Microgravity_Experiment /mnt/uG'';

    # oneAPI
    Act1AIP = "source /opt/intel/oneapi/setvars.sh";
  };
}
