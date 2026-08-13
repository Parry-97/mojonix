# mojonix

A Mojo / MAX learning and exploration sandbox.

## About

`mojonix` is a personal sandbox for learning [Mojo](https://docs.modular.com/mojo/)
and the [MAX SDK](https://docs.modular.com/max/). It covers GPU kernel basics
(vector addition via `TileTensor` and `enqueue_function`), struct design (a
wrap-around `Grid` for Conway's Game of Life), and Python interop (a pygame
visualization of the Game of Life).

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

## Prerequisites

- [Nix](https://nixos.org) + [devenv](https://devenv.sh)
- [uv](https://docs.astral.sh/uv/)
- An NVIDIA GPU (devenv pins CUDA 12.9)

## Getting started

```sh
devenv shell      # enter the nix-managed shell (sets CUDA_PATH, loader paths, etc.)
uv sync           # install mojo, max[all], pygame-ce into the venv
```

## Examples

### GPU detection

```sh
uv run mojo mojo-gpu-check.mojo
```

Prints the name of the attached GPU via `max.gpu.host.DeviceContext`.

### Vector addition on the GPU

```sh
uv run mojo mojo-addition.mojo
```

The MAX intro tutorial: element-wise sum of two vectors on the GPU using
`TileTensor`, `DeviceContext.enqueue_function`, and host↔device buffer copies.

### Conway's Game of Life

The `Grid` struct in `gridv1.mojo` implements wrap-around neighbor evolution;
`life.mojo` renders a random grid with pygame.

```sh
uv run mojo life.mojo
```

## Project layout

```
mojo-gpu-check.mojo         GPU detection via DeviceContext
mojo-addition.mojo          GPU vector addition (MAX intro tutorial)
gridv1.mojo                 Grid struct — Conway's Game of Life evolution
life.mojo                   pygame visualization of the Game of Life grid
src/mojonix/__init__.py     Python stub exposing the `mojonix` console script
tests/test_quickstart.mojo  Mojo TestSuite quickstart (contains an intentional failure)
devenv.nix                  Nix shell: CUDA, ncurses loader paths, GPU autodetect
pyproject.toml              Project metadata, deps (max[all], mojo, pygame-ce), entry point
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
`LD_LIBRARY_PATH`) are all handled by `devenv.nix`. See the comments there for
the full rationale — the README does not restate them.