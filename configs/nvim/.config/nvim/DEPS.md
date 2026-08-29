# DEPS — external dependencies for this Neovim config

Everything Neovim itself cannot install. Lua plugins are handled by
`lazy.nvim` (pinned in `lazy-lock.json`); LSP servers, formatters and linters
are handled by `mason.nvim` (declared in `lua/sybil/plugins/lsp/mason.lua`).
The lists below are the *system* packages those two need in order to work.

Package names are Arch (`pacman` unless marked **AUR**). Tested on Arch with
Neovim 0.12.4.

---

## 1. Required

| Dependency | Package | Needed by |
|---|---|---|
| Neovim **≥ 0.11** | `neovim` | `nvim-treesitter` main branch, native `vim.treesitter.foldexpr()`, `vim.lsp` config style |
| git | `git` | `lazy.nvim` bootstrap + clone, `vim-fugitive`, `gitsigns.nvim`, `snacks.git` |
| curl | `curl` | mason downloads, `sniprun` install script, `typst-preview` binary fetch |
| wget | `wget` | mason fallback downloader |
| unzip, tar, gzip | `unzip`, `tar`, `gzip` | mason package extraction |
| C compiler + make | `base-devel` (gcc, make) | tree-sitter grammar compilation, `LuaSnip` → `make install_jsregexp` |
| tree-sitter CLI | `tree-sitter-cli` | `nvim-treesitter` **main** branch generates parsers with it |
| Nerd Font | `ttf-jetbrains-mono-nerd`, `ttf-nerd-fonts-symbols` | `mini.icons`, `lualine`, `neo-tree`, diagnostic signs, `which-key` |
| ripgrep | `ripgrep` | `snacks.picker`, `telescope.nvim`, `todo-comments.nvim` |
| fd | `fd` | `snacks.picker` / `telescope` file finding |
| clipboard bridge | `wl-clipboard` (Wayland) or `xclip` (X11) | `"+`/`"*` registers, `pastify.nvim` |

### mason toolchain bootstrap

`mason` installs its own tools, but each backend needs a host runtime present:

| Runtime | Package | Installs |
|---|---|---|
| Node.js + npm | `nodejs`, `npm` | `pyright`, `css-lsp`, `html-lsp`, `prettier`, `eslint_d`, `emmet_ls`, `graphql`, `cssmodules_ls` |
| Python + pip | `python`, `python-pip` | `isort`, `black`, `pylint` |
| Rust / cargo | `rustup` (or `rust`) | `stylua`, `taplo`, and a source build of `sniprun` |
| Go | `go` | occasional Go-based tools |
| Perl + modules | `perl-file-homedir`, `perl-yaml-tiny` | runtime deps of `latexindent` (see §3) |

`clangd` is configured explicitly in `lspconfig.lua`; install `clang` so it is
available even when mason has not run.

Optional but referenced by this repo: `.config/package.json` pins `pyright` and
`tree-sitter-cli` locally — run `yarn install` in `configs/nvim/.config/` if
you prefer them vendored instead of mason/system-wide (`yarn`).

---

## 2. Feature-specific

### Git integration
- `lazygit` — `<leader>gg` via `Snacks.lazygit()`
- `xdg-utils` — `Snacks.gitbrowse()` opens the remote in a browser

### Images and inline math (`snacks.image`, enabled with `doc` + `math`)
- `imagemagick` — image conversion (`magick`)
- `ghostscript` — PDF → raster for the LaTeX math path
- `texlive-latex`, `texlive-latexextra`, `texlive-mathscience` — the
  `standalone` class and `amsmath`/`amssymb`/`amsfonts`/`amscd`/`mathtools`
  packages named in the math template
- `typst` — the Typst math template. This is the path markdown math takes by
  default: `$ .. $` in `.md` is injected as Typst, not LaTeX (see
  `queries/markdown_inline/injections.scm`), so `typst` is required, not
  optional, for inline math in notes. `:MdMath latex` puts a single buffer back
  on the TeX Live path above, and `.ipynb` markdown cells take that path by
  default (Jupyter renders them with MathJax) — both toolchains stay in use.
- A terminal speaking the **Kitty graphics protocol**: `kitty`, `ghostty` or
  `wezterm` (this repo ships kitty and ghostty configs)
- *Optional alternative:* `tectonic` (**AUR**) instead of a full TeX Live

### LaTeX
- `texlive-basic`, `texlive-latex`, `texlive-latexrecommended`,
  `texlive-latexextra`, `texlive-binextra`, `texlive-fontsrecommended`,
  `texlive-mathscience` — the set this machine already carries
- `latexindent` — ships in `texlive-binextra`; the conform.nvim `tex` formatter.
  Needs `perl-file-homedir` and `perl-yaml-tiny`. Local rules live in
  `.latexindent.yaml`
- `zathura` + `zathura-pdf-poppler` — PDF viewer (the commented-out `vimtex`
  block uses it as `vimtex_view_method`)
- `latexmk` — in `texlive-binextra`; `vimtex`'s compiler when re-enabled
- `texpresso` (**AUR**: `texpresso-git`) — required binary for
  `let-def/texpresso.vim`

### Typst
- `typst` — compiler
- `tinymist` — LSP/preview server; `typst-preview.nvim` downloads its own copy
  on first run (needs network + `curl`)
- A browser for the preview window

### Markdown
- `yarn` + `nodejs` — `markdown-preview.nvim` build step (`cd app && yarn install`)
- `firefox` — hardcoded as `vim.g.mkdp_browser`

### AI
- `claude-code` (**AUR**) — the `claude` CLI. CodeCompanion talks to it over
  ACP (`adapters.acp.claude_code`), so an authenticated subscription session is
  required. No `ANTHROPIC_API_KEY` is used; for headless auth run
  `claude setup-token`
- `copilot.lua` — Node.js ≥ 18 plus a GitHub Copilot subscription
  (`:Copilot auth`)

### Code execution
- `sniprun` — `sh install.sh` fetches a prebuilt binary; a local build
  (`sh install.sh 1`) needs Rust ≥ 1.65
- `compiler.nvim` / `overseer.nvim` — shells out to whatever toolchain the
  buffer's language needs: `gcc`/`g++`, `make`, `cmake`, `python`, `cargo`, `go`,
  `nasm`

### Jupyter notebooks (`ipynb.nvim`)
- `python-jupyter-client` — the kernel bridge (`python/kernel_bridge.py`) imports
  it. Without it every `:Notebook*` kernel command fails; editing, folding,
  highlighting and LSP still work.
- `python-ipykernel` — the `python3` kernel itself, so
  `:NotebookKernelStart` has something to start. Other languages need their own
  kernel (`ir` for R, `IJulia` for Julia, …).
- The `ipynb` tree-sitter parser is *not* a system package and is deliberately
  absent from `ensure_installed`: the plugin ships the grammar in
  `tree-sitter-ipynb/` and compiles it on first load.
- `:checkhealth ipynb` reports the whole list.

### Binary editing
- `xxd` — `hex.nvim` (`:HexToggle`); provided by `vim`

### tmux
- `tmux` — `vim-tmux-navigator` pane movement
- `tmux-sessionizer`, `tmux-attacher` — custom scripts bound to `<C-f>f` /
  `<C-f>s` in `lua/sybil/maps.lua`; sourced from `dotfiles/utils/tmuxscripts`

### Image pasting
- `pastify.nvim` — needs a clipboard reader (`wl-paste` from `wl-clipboard`)
  and, for uploads, an imgbb API key set in
  `lua/sybil/plugins/text_objects/pastify.lua`

---

## 3. Non-package prerequisites

These are paths and state, not software — the config references them directly:

- `~/orgfiles/` — `orgmode` agenda root (`refile.org`, `work.org`,
  `school.org`, `important.org`)
- `~/Documents/Projects/orgblocks` — `orgblocks.nvim` is loaded from this local
  checkout (`lua/sybil/plugins/viewers/orgblocks.lua`), not from a remote
- `catppuccin-frappe` colorscheme is set at startup in `lua/sybil/lazy.lua`;
  plugin-managed, listed only because a failed plugin sync makes startup error

---

## 4. Install

```sh
# repos
sudo pacman -S --needed \
  neovim base-devel git curl wget unzip tar gzip \
  tree-sitter-cli ripgrep fd fzf lazygit xdg-utils \
  nodejs npm yarn python python-pip rustup go clang cmake \
  wl-clipboard vim tmux firefox \
  imagemagick ghostscript typst \
  python-jupyter-client python-ipykernel \
  zathura zathura-pdf-poppler \
  perl-file-homedir perl-yaml-tiny \
  texlive-basic texlive-latex texlive-latexrecommended texlive-latexextra \
  texlive-binextra texlive-fontsrecommended texlive-mathscience \
  ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols ttf-nerd-fonts-symbols-mono

# AUR
yay -S --needed claude-code texpresso-git

# then, inside nvim
:Lazy sync
:MasonToolsInstall
:TSUpdate
:checkhealth
```
