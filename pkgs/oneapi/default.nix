{
  version ? "2024.0",
  stdenvNoCC, fetchurl, buildFHSEnv,
  ncurses
}:

let
  versions = {
    "2024.0" = {
      basekit = {
        id = "163da6e4-56eb-4948-aba3-debcec61c064";
        version = "2024.0.1.46";
        sha256 = "1sp1fgjv8xj8qxf8nv4lr1x5cxz7xl5wv4ixmfmcg0gyk28cjq1g";
      };
      hpckit = {
        id = "67c08c98-f311-4068-8b85-15d79c4f277a";
        version = "2024.0.1.38";
        sha256 = "06vpdz51w2v4ncgk8k6y2srlfbbdqdmb4v4bdwb67zsg9lmf8fp9";
      };
    };
  };

  installer = buildFHSEnv {
    name = "oneapi-installer";
    targetPkgs = pkgs: with pkgs; [ coreutils zlib ];
    extraBwrapArgs = [ "--bind" "$out" "$out" ];
    runScript = "sh";
  };

  componentString = components:
    if components == null then "--components default"
    else "--components " + (builtins.concatStringsSep ":" components);

  oneapi = stdenvNoCC.mkDerivation rec {
    pname = "oneapi-base";
    inherit version;

    basekit = fetchurl {
      url = "https://registrationcenter-download.intel.com/akdlm/IRC_NAS/${versions.${version}.basekit.id}/"
        + "l_BaseKit_p_${versions.${version}.basekit.version}_offline.sh";
      sha256 = versions.${version}.basekit.sha256;
    };

    hpckit = fetchurl {
      url = "https://registrationcenter-download.intel.com/akdlm/IRC_NAS/${versions.${version}.hpckit.id}/"
        + "l_HPCKit_p_${versions.${version}.hpckit.version}_offline.sh";
      sha256 = versions.${version}.hpckit.sha256;
    };

    phases = [ "installPhase" ];
    nativeBuildInputs = [ ncurses ];

    installPhase = ''
      mkdir -p $out
      ${installer}/bin/oneapi-installer ${basekit} -a --silent --eula accept --install-dir $out/share/intel \
        ${componentString (versions.${version}.basekit.components or null)}
      ${installer}/bin/oneapi-installer ${hpckit} -a --silent --eula accept --install-dir $out/share/intel \
        ${componentString (versions.${version}.hpckit.components or null)}
      ${installer}/bin/oneapi-installer $out/share/intel/modulefiles-setup.sh --output-dir=$out/share/intel/modulefiles \
        --ignore-latest
    '';

    dontFixup = true;
  };

  tools = [
    "ifx" "icx" "icpx"
    "mpirun" "mpiexec"
    "mpiifx" "mpiicx" "mpiicpx"
  ];

in buildFHSEnv {
  name = "oneapi-env";
  targetPkgs = pkgs: [
    oneapi
  ] ++ (with pkgs; [
    zlib
    zlib.dev             # /usr/include/zlib.h (HDF5 などの依存ライブラリ検出用)
    # icx/icpx/ifx は clang ベースで、FHS 標準パス (/usr/lib/gcc/<triple>/<ver>)
    # から GCC インストールを自動検出する。ラッパー版 gcc だけではこのツリーが
    # /usr に現れないため、実体を直接並べて完全な FHS ツールチェインを作る。
    gcc                  # /usr/bin/gcc (configure の CC テスト用)
    gcc-unwrapped        # /usr/lib/gcc/<triple>/<ver>/crtbegin*.o, /usr/include/c++
    gcc-unwrapped.lib    # libstdc++.so, libgcc_s.so
    glibc.dev            # /usr/include (stdio.h など)
    binutils-unwrapped   # /usr/bin/ld
    python3              # ビルドスクリプト用 (Zero-RK 等が find_package(Python3) する)
  ]);
  profile = ''
    source ${oneapi}/share/intel/setvars.sh > /dev/null 2>&1 || true
    # nix ビルドの cmake / pkg-config は /usr を探索しないようパッチされている
    # ため、FHS 内の /usr を明示的に探索対象へ加える (CMake の find_package が
    # zlib 等を見つけられるようにする)
    export CMAKE_PREFIX_PATH="/usr''${CMAKE_PREFIX_PATH:+:''${CMAKE_PREFIX_PATH}}"
    export PKG_CONFIG_PATH="/usr/lib/pkgconfig:/usr/share/pkgconfig''${PKG_CONFIG_PATH:+:''${PKG_CONFIG_PATH}}"
  '';
  runScript = "bash";
  extraInstallCommands = ''
    for tool in ${builtins.concatStringsSep " " tools}; do
      sed -e "s|@ENV@|$out/bin/oneapi-env|g" -e "s|@TOOL@|$tool|g" << 'ENDSCRIPT' > "$out/bin/$tool"
#!/bin/sh
exec "@ENV@" -c 'exec @TOOL@ "$@"' @TOOL@ "$@"
ENDSCRIPT
      chmod +x "$out/bin/$tool"
    done
  '';
}
