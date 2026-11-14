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
  `/usr/lib/rustup/bin/rust-analyzer`, the rustup proxy). `node`/`npm` and `gh` come from pacman (`nodejs`, `npm`,
  `github-cli`), not mise; see "Slow GitHub release downloads" below.
- mise: Omarchy 4.5 ships `/etc/mise/conf.d/omarchy-tools.toml` (package `omarchy-settings`) that declares about
  thirty tools as **lazy** (claude, codex, gh, node, opencode, ...). The first time you run one of those names, a mise
  command wrapper in `~/.local/share/mise/command-wrappers/bin` downloads and installs it without asking, and the agent
  CLIs then self-update at most every four hours (`auto_update = "4h"`, `minimum_release_age = "0s"`). The wrapper
  directory comes first in `PATH` (set by Omarchy's `env-bootstrap`), so it also shadows a native `~/.local/bin/claude`.
  The system file is overridable per tool in `~/.config/mise/config.toml`.
  The owner disabled every lazy tool, `gh` and `node` included, with `disable_tools` in
  `home/.config/mise/config.toml` (deployed to `~/.config/mise/config.toml`), so `mise up` (run by `omarchy update`)
  has nothing to download. After deploying, run `mise reshim` and delete `~/.local/share/mise/installs/{gh,node}`
  and `mise cache clear`. `claude`, `codex` and `grok` still go through Omarchy's account-switch
  wrapper (`/etc/mise/conf.d/omarchy-agent-accounts.toml`), which now falls through to the native
  `~/.local/bin/claude` and fails with "not a valid shim" for the others instead of installing them. Delete leftover
  installs and the `~/.local/bin/kimi` stub that Omarchy created; the stub runs `mise use -g` and would add itself
  to the global config.

### Slow GitHub release downloads

On the owner's connection GitHub **release assets** (`release-assets.githubusercontent.com`, also
`raw.githubusercontent.com`; Fastly, IPv4 only) are throttled to about 30 KB/s **per connection**, on all four
Fastly addresses. github.com itself, `git clone` and `codeload` tarballs are fast (3-5 MB/s, a different network),
as are the Arch mirror (~9 MB/s) and nodejs.org (~16 MB/s). That is why `gh` and `node` come from pacman: mise
downloads `gh` from GitHub releases. AUR `-bin` packages (`pdfcraft-bin`, `vesktop-bin`) still download from
GitHub releases. The throttle is per connection (16 parallel connections measured ~550 KB/s), so AUR builds
download those with aria2c over 16 connections:

- `home/.config/pacman/makepkg.conf` (makepkg reads `~/.config/pacman/makepkg.conf` after `/etc/makepkg.conf`)
  replaces only the `http`/`https` entries of `DLAGENTS` with `~/.local/bin/makepkg-dlagent %o %u`.
- `home/.local/bin/makepkg-dlagent` sends `github.com/*/releases/download/*`, `objects.githubusercontent.com`,
  `release-assets.githubusercontent.com` and `raw.githubusercontent.com` URLs to `aria2c -x16 -s16`, falls back to
  curl if aria2c fails, and runs makepkg's stock curl command for every other URL. Needs `aria2` (pacman.txt).
- yay and `omarchy pkg aur add` build through makepkg, so both use it. Measured: a 15 MB release tarball in 70 s
  instead of ~7 min. Undo by deleting the two files.

Check the throttle with `curl -4 -o /dev/null -r 0-2999999 -w '%{speed_download}\n' -L <release-url>` before
assuming it is the network.
