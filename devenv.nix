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
  packages = [ pkgs.cudaPackages_12_9.cudatoolkit ];

  # CUDA toolkit location (used by some downstream tools) and ptxas path
  # (REQUIRED for pre-Turing NVIDIA GPUs like the Pascal GTX 1060: Mojo's
  # internal libnvptxcompiler was built against CUDA 13 which dropped
  # pre-Turing support, so Mojo shells out to a system ptxas for sm_61).
  env.CUDA_PATH = "${pkgs.cudaPackages_12_9.cudatoolkit}";
  env.MODULAR_NVPTX_COMPILER_PATH = "${pkgs.cudaPackages_12_9.cudatoolkit}/bin/ptxas";

  # Nix-ld intercepts the uv-installed `mojo`/`mojo-lldb`/`mojo-lsp-server`
  # binaries (their ELF interpreter is /lib64/ld-linux-x86-64.so.2, symlinked
  # to nix-ld system-wide) and routes shared-library lookup through
  # NIX_LD_LIBRARY_PATH. We prepend conda-forge ncurses (which exports the
  # required NCURSES6_5.0.19991023 ABI tag) and libbsd (also missing from the
  # system nix-ld set), then fall back to the system nix-ld library set
  # (libstdc++, libgcc_s, libc, zlib, openssl, dbus, glib, curl). Finally we
  # append /run/opengl-driver/lib so the `mojo` compiler can find
  # libnvidia-ml.so / libcuda.so at comptime to auto-detect the GPU arch.
  env.NIX_LD_LIBRARY_PATH = lib.concatStringsSep ":" [
    "${mojoNcurses}/lib"
    "${pkgs.libbsd}/lib"
    "${pkgs.libxkbcommon}/lib"
    "${pkgs.wayland}/lib"
    "${pkgs.udev}/lib"
    "/run/current-system/sw/share/nix-ld/lib"
    "/run/opengl-driver/lib"
  ];

  # SDL2 (bundled in the pygame-ce wheel) dlopens its display backend at
  # runtime, not at link time, so it only "sees" backends whose client libs
  # are resolvable on the loader path. The wayland client libs + libxkbcommon
  # (above) let SDL's wayland backend load, and libudev (systemd-minimal-libs)
  # supplies the udev_device_get_action symbol SDL's evdev/joystick probe
  # references. We deliberately do NOT set env.SDL_VIDEODRIVER here: pinning it
  # to "wayland" while DISPLAY=:0 is exported by the ambient session breaks
  # SDL's backend selection; leaving it unset lets SDL autoprobe, which under
  # niri (no X11 client libs present) lands on wayland.
  #
  # SDL2 2.32 normally dlopens libdecor-0.so.0 for Wayland window decorations.
  # pygame-ce under the Mojo Python bridge in `mojo run` initializes that code
  # path, then faults SDL's pg_set_mode; plain CPython skips libdecor entirely.
  # We do NOT add libdecor to the loader path (verified: it does not help) but
  # do set SDL_HINT_VIDEO_WAYLAND_ALLOW_LIBDECOR="0" so SDL draws XDG-shell
  # toplevels directly, matching the working Python path (borderless window).
  #
  # Final wrinkle: `mojo run` installs Mojo's fault-printer signal handler,
  # which misfires on SDL's legitimate wayland SIGSEGV and aborts with the
  # misleading "execution crashed" stub; that handler is NOT installed in
  # binaries produced by `mojo build`, so the working invocation is:
  #   mojo build life.mojo -o life && ./life
  env.SDL_VIDEO_WAYLAND_ALLOW_LIBDECOR = "0";

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
