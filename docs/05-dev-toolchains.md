# 05 — Development toolchains

## C / C++ (clang first)

- **clang is the default compiler** in every editor integration: Neovim `<leader>r` (C), VS Code Code Runner
  (`clang`, `clang++ -std=c++17`), clangd as language server. gcc is installed (Omarchy) but not used by any
  mapping.
- `home/.clang-format` (copied to `~/.clang-format`): Google base, 4-space indent, Allman braces, 110 columns,
  C++17, pointer alignment left, `SortIncludes` on with `IncludeBlocks: Preserve`, no short functions on one
  line. clangd, Neovim (conform), VS Code and Zed all pick it up by searching upward from the file.
- clangd runs with `--header-insertion=never` in Neovim so it does not add includes by itself.
- VS Code: Microsoft cpptools IntelliSense is turned **off** in settings so it does not conflict with clangd.
- OpenMP: package `openmp`; compile with `clang -fopenmp file.c -o file`.

### Assembly (16-bit DOS exercises)

- Packages: `nasm`, `dosbox` (pacman list). The AFD debugger is expected inside the DOSBox mount.
- Neovim: `<leader>r` on an `.asm` file assembles to a `.com` with nasm and runs it in DOSBox fullscreen;
  `<leader>d` runs it under `afd`. Both are defined in `home/.config/nvim/lua/config/keymaps.lua`.

## Python (uv)

- Everything uses `uv`; projects live in their own `.venv`. `requires-python >= 3.12`.
- Global ruff fallback: `home/.config/ruff/ruff.toml` (110 columns); projects override it.
- Notebooks: VS Code Jupyter or Neovim molten (`:MoltenInit AI`, kernel named `AI`). Packages `python-ipykernel`,
  `python-jupyter-client`, `python-pynvim` support molten.

### GPU PyTorch and TensorFlow

Reference: `python/uv-gpu-pyproject.example.toml`. Key points:

- PyTorch comes from the CUDA wheel index through `[[tool.uv.index]]` named `pytorch`
  (`https://download.pytorch.org/whl/cu126`, `explicit = true`) and `[tool.uv.sources]` for `torch`,
  `torchvision`, `torchaudio`. `index-strategy = "unsafe-best-match"` lets uv mix PyPI and the PyTorch index.
  Pick the CUDA tag (cu126, cu128, ...) that the installed NVIDIA driver supports (`nvidia-smi` shows the
  maximum).
- TensorFlow uses the pip extra `tensorflow[and-cuda]`. The wheel does not search
  `site-packages/nvidia/*/lib`, so it silently falls back to CPU. `python/_tf_cuda_preload.py` plus
  `python/_tf_cuda_preload.pth` fix that: copy both into the venv's `site-packages`
  (`<project>/.venv/lib/python3.X/site-packages/`). The `.pth` file imports the module on interpreter start; it
  installs an import hook that preloads the pip CUDA libraries just before `import tensorflow`. Nothing else is
  affected. Redo this after recreating the venv.
- Verify:

  ```bash
  uv run python -c "import torch; print(torch.cuda.is_available(), torch.version.cuda)"
  uv run python -c "import tensorflow as tf; print(tf.config.list_physical_devices('GPU'))"
  ```

  Both must report the GPU. `uv sync` in each project creates the venv.
- Large datasets stay out of git (the owner moved big data to a different machine; some repos use Git LFS:
  `git lfs install`, then `git lfs pull`).

## Go, Rust, JavaScript

- `go` + `gopls` (pacman), `rustup` (run `rustup default stable`; Neovim's config points rust-analyzer at
  `/usr/lib/rustup/bin/rust-analyzer`, the rustup proxy), Node and
  npm come with Omarchy (mise manages `node` and `gh`).
- mise: `~/.config/mise/config.toml` only keeps `gh` and `node`. Claude Code and Codex are intentionally **not**
  installed through mise (native Claude Code is in `~/.local/bin`).
