{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:

let
  # The prebuilt `liblldb24.0.0git.so` shipped inside the `mojo` PyPI wheel
  # requires the ABI symbol version `NCURSES6_5.0.19991023`, an Ubuntu/conda
  # ABI tag that nixpkgs ncurses (built `--with-versioned-syms` against
  # upstream 6.6's symbol set) does NOT export. The symbol physically is not
  # in the file, so no LD_LIBRARY_PATH against nixpkgs ncurses can satisfy it.
  # The conda-forge ncurses blob below DOES export it, so we pull that binary
  # and expose only its `.so*` files (no headers, no terminfo) so the liblldb
  # load succeeds. Scope is limited to this devenv shell via NIX_LD_LIBRARY_PATH.
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
  packages = with pkgs; [
    cudaPackages_12_9.cudatoolkit
    cudaPackages_12_9.cudnn
  ];

  env = {
    CUDA_PATH = "${pkgs.cudaPackages_12_9.cudatoolkit}";
  };

  # Nix-ld intercepts the uv-installed `mojo`/`mojo-lldb`/`mojo-lsp-server`
  # binaries (their ELF interpreter is /lib64/ld-linux-x86-64.so.2, symlinked
  # to nix-ld system-wide) and routes shared-library lookup through
  # NIX_LD_LIBRARY_PATH. We prepend conda-forge ncurses (which exports the
  # required NCURSES6_5.0.19991023 ABI tag) and libbsd (also missing from the
  # system nix-ld set), then fall back to the system nix-ld library set
  # (libstdc++, libgcc_s, libc, zlib, openssl, dbus, glib, curl).
  env.NIX_LD_LIBRARY_PATH = lib.concatStringsSep ":" [
    "${mojoNcurses}/lib"
    "${pkgs.libbsd}/lib"
    "/run/current-system/sw/share/nix-ld/lib"
  ];

  # Binaries produced by `mojo build` embed glibc's ld.so directly (not
  # nix-ld) and use DT_RUNPATH (not DT_RPATH) — so transitive deps of the
  # linked modular runtime (e.g. libKGENCompilerRTShared.so's need for
  # libstdc++.so.6) are NOT resolved via the executable's RUNPATH. They need
  # LD_LIBRARY_PATH to be set so glibc ld.so finds libstdc++ at load time.
  env.LD_LIBRARY_PATH = lib.makeLibraryPath [
    pkgs.stdenv.cc.cc.lib
    pkgs.cudaPackages_12_9.cudatoolkit
  ];

  # https://devenv.sh/languages/
  languages.python = {
    enable = true;
    uv.enable = true;
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
    git --version # Use packages
  '';

  # https://devenv.sh/tasks/
  # tasks = {
  #   "myproj:setup".exec = "mytool build";
  #   "devenv:enterShell".after = [ "myproj:setup" ];
  # };

  # https://devenv.sh/tests/
  enterTest = ''
    echo "Running tests"
    git --version | grep --color=auto "${pkgs.git.version}"
  '';

  # https://devenv.sh/git-hooks/
  # git-hooks.hooks.shellcheck.enable = true;

  # See full reference at https://devenv.sh/reference/options/
}
