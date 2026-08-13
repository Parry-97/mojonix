{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:

let
  # Mojo's liblldb requires the ABI symbol `NCURSES6_5.0.19991023`, which
  # nixpkgs ncurses does NOT export. The conda-forge blob below does, so we
  # pull only its `.so*` files and expose them via NIX_LD_LIBRARY_PATH.
  mojoNcurses = pkgs.stdenv.mkDerivation {
    pname = "mojo-ncurses";
    version = "6.5-conda";
    src = pkgs.fetchurl {
      url = "https://conda.anaconda.org/conda-forge/linux-64/ncurses-6.5-h2d0b736_3.conda";
      sha256 = "sha256-P94pMjL6P8qYY14RZ95rfH/ag8ryS51skeye77T01YY=";
    };
    nativeBuildInputs = [
      pkgs.unzip
      pkgs.zstd
    ];
    dontConfigure = true;
    dontBuild = true;
    unpackPhase = ''
      unzip -o $src
      tar --zstd -xf pkg-*.tar.zst
      rm pkg-*.tar.zst
    '';
    installPhase = ''
      mkdir -p $out/lib
      cp lib/libncurses*.so* $out/lib/
      cp lib/libtinfo*.so*   $out/lib/
      cp lib/libpanel*.so*   $out/lib/
    '';
  };
in
{
  # https://devenv.sh/basics/
  env.GREET = "devenv";

  # https://devenv.sh/packages/
  packages = [ pkgs.cudaPackages_12_9.cudatoolkit ];

  # CUDA toolkit + ptxas path. REQUIRED for pre-Turing GPUs (e.g. Pascal GTX
  # 1060 / sm_61): Mojo's internal libnvptxcompiler targets CUDA 13 and dropped
  # pre-Turing, so Mojo shells out to a system ptxas.
  env.CUDA_PATH = "${pkgs.cudaPackages_12_9.cudatoolkit}";
  env.MODULAR_NVPTX_COMPILER_PATH = "${pkgs.cudaPackages_12_9.cudatoolkit}/bin/ptxas";

  # nix-ld routes shared-library lookup for the uv-installed `mojo`/`mojo-lldb`/
  # `mojo-lsp-server` binaries through NIX_LD_LIBRARY_PATH. We prepend
  # conda-forge ncurses (ABI tag, above) and libbsd (missing from system
  # nix-ld), then fall back to the system nix-ld set. /run/opengl-driver/lib
  # is appended so the `mojo` compiler can find libnvidia-ml.so / libcuda.so
  # at comptime for GPU arch auto-detection.
  env.NIX_LD_LIBRARY_PATH = lib.concatStringsSep ":" [
    "${mojoNcurses}/lib"
    "${pkgs.libbsd}/lib"
    "/run/current-system/sw/share/nix-ld/lib"
    "/run/opengl-driver/lib"
  ];

  # Binaries produced by `mojo build` embed glibc's ld.so directly (not
  # nix-ld) and use DT_RUNPATH (not DT_RPATH) — so transitive deps of the
  # linked modular runtime (e.g. libKGENCompilerRTShared.so's need for
  # libstdc++.so.6) are NOT resolved via the executable's RUNPATH. They need
  # LD_LIBRARY_PATH to be set so glibc ld.so finds libstdc++ at load time.
  # /run/opengl-driver/lib is appended so the built binary can load
  # libcuda.so at runtime (for DeviceContext / host-side GPU calls).
  env.LD_LIBRARY_PATH =
    lib.makeLibraryPath [
      pkgs.stdenv.cc.cc.lib
      pkgs.cudaPackages_12_9.cudatoolkit
    ]
    + ":/run/opengl-driver/lib";

  # https://devenv.sh/languages/
  languages.python = {
    enable = true;
    uv.enable = true;
    uv.sync.enable = true;
    venv.enable = true;
  };

  # https://devenv.sh/processes/
  # processes.dev.exec = "${lib.getExe pkgs.watchexec} -n -- ls -la";

  # https://devenv.sh/services/
  # services.postgres.enable = true;

  # https://devenv.sh/scripts/
  scripts.hello.exec = ''
    echo hello from $GREET
  '';

  # https://devenv.sh/basics/
  enterShell = ''
    hello         # Run scripts directly
  '';

  # https://devenv.sh/tasks/
  # tasks = {
  #   "myproj:setup".exec = "mytool build";
  #   "devenv:enterShell".after = [ "myproj:setup" ];
  # };

  # https://devenv.sh/tests/
  enterTest = ''
    echo "Running tests"
  '';

  # https://devenv.sh/git-hooks/
  # git-hooks.hooks.shellcheck.enable = true;

  # See full reference at https://devenv.sh/reference/options/
}
