# mojonix

A Mojo / MAX learning and exploration sandbox.

## About

`mojonix` is a personal sandbox for learning [Mojo](https://docs.modular.com/mojo/)
and the [MAX SDK](https://docs.modular.com/max/). As a `src`-layout package it
tracks a growing set of language and GPU exercises in three areas:

- **GPU programming** — the MAX intro tutorial (GPU vector addition via
  `TileTensor` and `enqueue_function`) plus a minimal GPU-detection / thread-id
  probe.
- **Game of Life** — a wrap-around `Grid` struct (`gridv1.mojo`) and a pygame
  visualization (`life.mojo`) driven through Python interop.
- **Mojo language** — a collection of focused `.mojo` exercises covering
  language basics, value ownership, parametrization, metaprogramming, pointers,
  self-referential types, complex-number operator overloading, and Mojo
  packaging.

## Reproducible dev environment with Nix + devenv

The whole toolchain — Mojo, MAX, CUDA, pygame-ce, and the host of loader quirks
Nix normally fights — is pinned and provisioned by [devenv](https://devenv.sh)
on top of Nix. `devenv shell` yields the same compiler, GPU stack, and shared
libraries on every machine, so examples run identically without manually setting
`CUDA_PATH`, `LD_LIBRARY_PATH`, or chasing the ncurses/`ptxas` quirks
that Mojo's prebuilt wheels require. All of that lives declaratively in
`devenv.nix`; the README does not restate it. CUDA 12.9 is pinned for NVIDIA GPU
support, and pre-Turing cards (e.g. the Pascal GTX 1060) are supported via a
system `ptxas` since Mojo's internal PTX compiler dropped pre-Turing.
pygame-ce ships its own `libSDL2` that can't resolve the X11 client libs under
nix-ld, so `devenv.nix` also puts those libs on the loader paths and forces
`SDL_VIDEODRIVER=x11` (XWayland); without this the Game of Life window never
appears — `pygame.display.set_mode()` silently succeeds on the `dummy` driver.

## Prerequisites

- [Nix](https://nixos.org) + [devenv](https://devenv.sh)
- [uv](https://docs.astral.sh/uv/)
- An NVIDIA GPU (devenv pins CUDA 12.9)

## Getting started

```sh
devenv shell      # enter the nix-managed shell (sets CUDA_PATH, loader paths, etc.)
uv sync           # install mojo, max[all], pygame-ce, numpy into the venv
```

## Examples

Run the `.mojo` files from the repo root, using their path under `src/`:

```sh
uv run mojo src/mojonix/gpu_programming/mojo-gpu-check.mojo
```

### GPU programming

- **GPU detection** — `mojo-gpu-check.mojo` prints the coordinates of each
  launched thread via `DeviceContext.enqueue_function` and
  `max.gpu.host.DeviceContext`.
- **Vector addition** — `vector_addition.mojo`  implements the MAX intro tutorial: element-wise
  sum of two vectors on the GPU using `TileTensor`,
  `DeviceContext.enqueue_function`, and host↔device buffer copies.

```sh
uv run mojo src/mojonix/gpu_programming/vector_addition.mojo
```

### Conway's Game of Life

The `Grid` struct in `game_of_life/gridv1.mojo` implements wrap-around neighbor
evolution; `game_of_life/life.mojo` renders a random grid with pygame.

```sh
uv run mojo src/mojonix/game_of_life/life.mojo
```

`life.mojo` also contains an `initial_main()` that demonstrates creating a fixed
glider configuration and printing the grid to the terminal.

### Mojo language exercises

Focused single-file exercises under `mojo_lang/`, each runnable the same way:

```sh
uv run mojo src/mojonix/mojo_lang/language-basics.mojo
```

Topics covered:

- `language-basics.mojo` — traits, `@fieldwise_init`, comptime parameters,
  Python interop (NumPy), value vs. reference semantics, `ref` bindings.
- `value_ownership.mojo` — immutable vs. `mut` / `var` argument conventions,
  the `^` transfer sigil, and argument exclusivity.
- `parametrization.mojo` — parametrized types, comptime members/enums,
  SIMD vectors, and a `ParameterizedArray` built on manual allocation.
- `metaprogramming.mojo` — compile-time execution, `comptime` values and loops,
  and compile-time GPU/CPU dispatch.
- `pointers.mojo` — `Pointer` and `OwnedPointer`; dereferencing and single
  ownership semantics (imports `MyPair` from the `mypackage` package).
- `self-referential.mojo` — a `Node` linked list using `Pointer` with
  `MutUntrackedOrigin`, `Optional`, allocation, and manual deallocation.
- `complex.mojo` — a `Complex` struct implementing operators (`+`, `-`, `*`,
  `/`, unary), `Boolable`, `Equatable`, and `Writable` traits.
- `packaging.mojo` — imports `MyPair` from the `mypackage` package (see
  `mojo_lang/mypackage/mymodule.mojo`).

## Project layout

```
src/mojonix/
  __init__.py                   Python stub exposing the `mojonix` console script
  gpu_programming/
    mojo-gpu-check.mojo         GPU detection / thread-id probe via DeviceContext
    vector_addition.mojo        GPU vector addition (MAX intro tutorial)
  game_of_life/
    gridv1.mojo                 Grid struct — Conway's Game of Life evolution
    life.mojo                   pygame visualization of the Game of Life
  mojo_lang/
    language-basics.mojo        traits, fieldwise init, comptime params, NumPy interop
    value_ownership.mojo        argument conventions, transfer sigil, exclusivity
    parametrization.mojo        parametrized types, comptime members, SIMD
    metaprogramming.mojo        comptime execution and dispatch
    pointers.mojo               Pointer / OwnedPointer
    self-referential.mojo       Node linked list with manual allocation
    complex.mojo                Complex struct with operator overloading
    packaging.mojo              uses the `mypackage` example package
    mypackage/
      __init__.mojo             package init
      mymodule.mojo             MyPair struct used by pointers/packaging examples
tests/
  test_quickstart.mojo          Mojo TestSuite quickstart (intentional failure)
devenv.nix                      Nix shell: CUDA, ncurses loader paths, GPU autodetect
devenv.yaml                     devenv inputs (nixpkgs source)
pyproject.toml                  Project metadata, deps, entry point, uv_build backend
uv.lock / devenv.lock           Locked dependency pins
```

## Tests

```sh
uv run mojo tests/test_quickstart.mojo
```

`test_inc_zero` contains an intentional logical error to demonstrate what a
test failure looks like at runtime; `test_inc_one` passes.

## Notes

The CUDA / loader environment quirks
(`CUDA_PATH`, `MODULAR_NVPTX_COMPILER_PATH`, `NIX_LD_LIBRARY_PATH`,
`LD_LIBRARY_PATH`, `SDL_VIDEODRIVER`) are all handled by `devenv.nix`. See the
comments there for the full rationale — the README does not restate them.
