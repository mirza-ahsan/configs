# 03 — Editors: Neovim, Zed, VS Code

One principle across all three: **one language server and one formatter per language, no duplicate
diagnostics**, and **no theme settings** (Omarchy drives colors for every editor).

## Language tooling matrix

| Language | LSP | Formatter on save | Notes |
|---|---|---|---|
| Python | pyrefly (types) + ruff (lint) | ruff format (Neovim, Zed); Black (VS Code) | see "Python without duplicate warnings" |
| C / C++ | clangd | clang-format (style from `~/.clang-format`) | clang is the default compiler everywhere |
| Go | gopls | gofmt | |
| Rust | rust-analyzer | rustfmt (LSP) | Neovim only |
| TypeScript / JavaScript | ts_ls (Neovim), built in (Zed) | prettier | |
| Lua | lua_ls | stylua | Neovim only |
| Shell | | shfmt | Neovim only |

System binaries are used wherever possible (`mason = false` in the Neovim config) so Mason copies never shadow
the packages. Mason only holds prettier, shfmt, stylua, ts_ls and lua_ls.

## Neovim (`home/.config/nvim`, on top of Omarchy's LazyVim)

Omarchy ships LazyVim with its theme hot-reload plugin; this repo only adds files next to it. Files that are
**not** here on purpose (Omarchy owns them): `lua/plugins/theme.lua`, `all-themes.lua`,
`omarchy-theme-hotreload.lua`, `lualine-transparent.lua`, `plugin/after/transparency.lua`, `example.lua`,
`lazy-lock.json`.

What the personal files do:

- `options.lua`: Zed-like feel — block cursor, `scrolloff = 8`, 4-space indent, relative numbers, no swap,
  persistent undo, format on save (`vim.g.autoformat = true`). Loads `config/remote_clipboard.lua` first.
- `keymaps.lua`: Space is leader and localleader; `<leader>y` yank to clipboard; `<leader>pv` netrw;
  `<C-S-e>` netrw side panel (Zed's ctrl-shift-e); `J/K` move blocks in visual mode; centered scrolling and
  search; `go` = start of document; `<leader>sv/sh/se/sx` splits; `Ctrl-h/j/k/l` window navigation; snacks
  pickers (`<leader>pf` files, `<leader>fg` grep, `<leader>fb` buffers, `<leader>fh` help); `gl` shows the
  full diagnostic, `[d`/`]d` jump, `<leader>f` formats, `--` code action; `<leader>r` compiles and runs a C
  file with clang or an assembly file in DOSBox, `<leader>d` runs assembly under the AFD debugger (needs
  `nasm`, `dosbox`; see `05`).
- `autocmds.lua`: trims trailing whitespace on save, absolute line numbers in insert mode, no comment
  continuation on new lines, **semantic tokens off** (Treesitter colors win).
- `plugins/personal.lua`: LSP servers and keys, conform formatters, blink.cmp (`super-tab` keymap),
  noice/gitsigns/snacks tweaks, neo-tree and bufferline disabled (netrw instead), Treesitter parsers,
  image.nvim + molten-nvim for Jupyter-style work.
- `snacks-animated-scrolling-off.lua`, `disable-news-alert.lua`: quiet UI.

### Python without duplicate warnings

pyrefly (type checker) and ruff (linter) both report unused imports, undefined names and unused variables,
which showed every problem twice. The fix lives in `personal.lua`:

```lua
ruff = { mason = false, init_options = { settings = { lint = { ignore = { "F401", "F821", "F841" } } } } }
```

pyrefly keeps those three; every other ruff rule (E, W, I, B, project-specific ones) still reports once, and
project `ruff.toml` / `pyproject.toml` settings still apply. pyrefly runs with `typeCheckingMode = "default"`:
the old `"basic"` preset misses plain type errors (wrong return/argument types). `"strict"` adds hundreds of
"missing annotation" errors on ML/notebook code, so it is not used. Same setting is in Zed. Check with a
file containing an unused import, an undefined name and `def f(x: int) -> str: return x`.

### Other deliberate choices

- Inlay hints are **off** (`inlay_hints = { enabled = false }`): no `format:` argument labels inline.
  `<leader>uh` toggles them per buffer.
- flash.nvim's `S` mapping is disabled so Shift-S keeps its built-in meaning (clear the line, keep the
  indent). flash's `s` jump still works.
- LazyVim's `<C-s>` (save) exists but tmux's prefix is Ctrl+S, so use `:w` inside tmux.
- Testing headless: `doautocmd User VeryLazy` first, or keymaps are not defined yet.

## Zed (`home/.config/zed`)

- `settings.json`: Vim mode, relative line numbers, JetBrainsMono Nerd Font 20, AI disabled, quiet chrome (no
  tab bar, minimap off, buttons hidden), `session.trust_all_worktrees`, format on save, per-language servers as
  in the matrix above, pyrefly settings (default preset), auto-install of `charmed-icons`, `pyrefly`, `ruff`.
  The `theme` key is absent: the `omazed` package sets it when the Omarchy theme changes.
- `keymap.json`: ctrl-shift-e toggles the right project dock, `g o` start of document, space-leader file finder,
  splits, format, rename, diagnostics, `- -` code actions, `K` hover.
- Extensions install themselves from `auto_install_extensions`; list in `packages/zed-extensions.txt`.

## VS Code (`home/.config/Code/User/settings.json`)

- Native chrome hidden, JetBrainsMono Nerd Font 18 bold, autosave after 1 s, format on save.
- **AI lockdown:** `chat.disableAIFeatures`, Copilot and inline suggestions off, GitLens AI off.
- Python: Black formatter at line length 120 comes from the project; Jupyter niceties.
- **C/C++:** clangd (`llvm-vs-code-extensions.vscode-clangd`) is the language server and default formatter;
  Microsoft's cpptools IntelliSense is **disabled** (`C_Cpp.intelliSenseEngine = "disabled"` and friends) so the
  two never fight; Code Runner compiles with `clang` / `clang++ -std=c++17`.
- `workbench.colorTheme` is absent; Omarchy writes it (it needs the `local.omarchy-theme` extension that Omarchy
  installs).
- Install extensions from `packages/vscode-extensions.txt`.

## Python formatter configuration

- `home/.config/ruff/ruff.toml` is a global fallback (line length 110, py312, rules E/F/W/I, double quotes).
  Ruff does not merge configs; a project's own `ruff.toml`/`pyproject.toml` replaces it entirely. The owner's ML
  projects use 120 columns.
- Neovim and Zed format with ruff; VS Code uses Black. Both land on near-identical output.
