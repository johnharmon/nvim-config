# nvim-config

My Neovim configuration, packaged as a single lazy.nvim plugin. Enabling it
installs every plugin, keymap, option and command I use; lazy.nvim is the only
prerequisite.

## Install

```lua
-- ~/.config/nvim/init.lua

-- Must be set before lazy.setup: plugin specs declare `keys = { "<leader>…" }`,
-- and those are resolved against whatever mapleader is at that moment.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Optional. Anything read inside a plugin spec (paths, extras, model names)
-- has to be set here, before lazy.setup — see "Configuration" below.
vim.g.jharmon = {}

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local out = vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath,
  })
  if vim.v.shell_error ~= 0 then
    error("Error cloning lazy.nvim:\n" .. out)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    {
      "jharmon-istari/nvim-config",
      import = "jharmon.plugins", -- pulls in every plugin spec
      main = "jharmon",           -- so lazy calls require("jharmon").setup()
      opts = {},
      lazy = false,
      priority = 10000,           -- core options/keymaps before other plugins
    },
  },
  install = { colorscheme = { "tokyonight-night" } },
  ui = {
    icons = vim.g.have_nerd_font and {} or {
      cmd = "⌘", config = "🛠", event = "📅", ft = "📂", init = "⚙",
      keys = "🗝", plugin = "🔌", runtime = "💻", require = "🌙",
      source = "📄", start = "🚀", task = "📌", lazy = "💤 ",
    },
  },
})
```

Run `:checkhealth jharmon` afterwards to see which external binaries are
missing.

## Configuration

Set `vim.g.jharmon` **before** `require("lazy").setup(...)`. It is deep-merged
over the defaults in `lua/jharmon/config.lua`. `opts` on the spec is merged too,
but only reaches the `core.*` modules — lazy imports the spec files long before
it calls `setup()`, so anything a spec reads must come from `vim.g.jharmon`.

| Key | Default | What it does |
| --- | --- | --- |
| `silence_deprecations` | `true` | Stubs out `vim.deprecate` |
| `colorscheme` | `"tokyonight-night"` | Applied after the theme's `setup()` |
| `nerd_font` | `false` | Sets `vim.g.have_nerd_font`; drives icons in which-key, mini.statusline, lazy |
| `shell` | `/opt/homebrew/bin/fish` | Only applied when the binary exists |
| `undodir` | `~/.vim/undodir` | |
| `completion` | `"both"` | `"both"` \| `"blink"` \| `"cmp"` |
| `claude_cmd` | `~/.local/bin/claude` | `terminal_cmd` for claudecode.nvim |
| `terraform_path` | `/usr/local/bin/terraform` | Passed to terraform-ls |
| `acm_ls.dir` | `~/git-projects/nvim-acm` | Local LSP checkout; the spec is skipped when absent |
| `acm_ls.cmd` | `<dir>/lsp-server/acm-ls` | |
| `working.root` | `$WORKING_ROOT`, then `~/git/autoshiftv2` | Parent of the `.working` symlink dir |
| `codecompanion.url` / `.proxy` / `.model` | LAN ollama | |
| `extras.floaterm` / `.working` / `.kubectl_kinds` | `true` | Standalone feature modules |
| `treesitter` | 28 parsers | Kept installed and updated |

## Layout

```
lua/jharmon/
├── init.lua        setup(opts)
├── config.lua      defaults + vim.g.jharmon merge
├── health.lua      :checkhealth jharmon
├── core/           options, clipboard, lsp, ui, autocmds, commands, keymaps
├── util/window.lua oil sidebar + smart split resizing
├── extras/         floaterm, working, kubectl_kinds
└── plugins/        one file per group; the `import` target
```

`core/` is loaded in a fixed order by `core/init.lua`. Global keymaps live in
`core/keymaps.lua`; plugin-specific ones stay in each spec's `keys = {}` so they
keep lazy-loading their plugin.

## Keymaps

Leader is `<Space>`.

### Windows and files
| Key | Action |
| --- | --- |
| `<leader>e` | Focus or open the oil sidebar (30 cols, far left) |
| `<leader>E` | Force a fresh oil sidebar |
| `<leader>pv` | Netrw in the current window |
| `<C-h/j/k/l>` | Move focus left/down/up/right |
| `<C-left>` / `<C-right>` | Move the vertical split left/right |
| `t` / `T` | Next tab |

### Editing
| Key | Action |
| --- | --- |
| `jk` (insert) | `<Esc>` |
| `-` / `_` | Move line (normal) or selection (visual) down/up |
| `J` / `K` (visual) | Move selection down/up |
| `J` | Join without moving the cursor |
| `dw` / `dl` | Delete word under cursor / line contents |
| `c"` `c'` `c{` `c(` `c[` | Change inside the pair |
| `<leader>"` / `<leader>'` | Quote the word under the cursor |
| `<leader>s` | `:%s/word//gI` seeded with the word under the cursor |
| `<leader>y` / `<leader>Y` | Yank to system clipboard |
| `<leader>d` (visual) | Delete into the void register |
| `<leader>p` (visual) | Paste over selection, keeping the register |
| `<C-p>` (insert) | Paste and stay in insert |

### Movement
| Key | Action |
| --- | --- |
| `<C-u>` `<C-d>` `<C-]>` `n` `N` | Same, then recentre |
| `<S-j>` | Page down |
| `<S-k>` | Hover documentation |
| `<leader>P` | Toggle page mode (j/k become PageDown/PageUp) |

### Diagnostics and search
| Key | Action |
| --- | --- |
| `<Esc>` | Clear search highlight |
| `<leader>d` | Diagnostic float |
| `<leader>q` | Diagnostics to the location list |
| `<leader>ic` | Toggle ignorecase |
| `<leader>f` | Format buffer (conform) |

### Telescope
`<leader>sh` help · `sk` keymaps · `sf` files · `ss` builtins · `sw` word ·
`sg` grep · `sd` diagnostics · `sr` resume · `s.` recent · `s/` grep open files ·
`sn` nvim config · `<leader><leader>` buffers · `<leader>/` fuzzy in buffer

### LSP (buffer-local on attach)
`gd` definition · `gr` references · `gI` implementation · `gD` declaration ·
`<leader>D` type definition · `<leader>ds` document symbols ·
`<leader>ws` workspace symbols · `<leader>rn` rename · `<leader>ca` code action ·
`<leader>th` toggle inlay hints

### Claude Code / CodeCompanion
`<leader>ac` toggle · `af` focus · `ar` resume · `aC` continue · `am` model ·
`ab` add buffer · `as` send selection / add file · `aa` accept diff · `ad` deny diff ·
`<leader>ch` CodeCompanion chat · `<leader>cca` CodeCompanion actions

### Harpoon / kubectl / iron / colors
`<leader>ha` add · `hq` menu · `hh` prev · `hl` next ·
`<leader>k` kubectl · `<C-r>` or `:KubectlKinds` kind picker ·
`<leader>tc` terraform console · `<leader>sl` / `sv` / `sc` iron send ·
`<leader>cp` colour picker · `<leader>cc` convert colour

### Floating terminals (`extras.floaterm`)
`<C-c>` `<C-x>` `<C-z>` `<C-a>` `<C-s>` open terminals 0–4;
`<leader>ot` / `<leader>tt` / `<leader>fd` and `:Floaterminal [n]` open terminal 0.
Toggling a visible one hides all of them.

### Working set (`extras.working`)
`:Wa <path>` add · `:Wr <name>` remove · `:Ww` wipe · `:Wl` pick and cd ·
`:Wg <name>` cd · `:Wn` next. Same on `<leader>wa/wr/ww/wl/wg/wn`.

### Sessions
`:SessionStart <path>` writes a session there on exit. After `nvim -S foo.vim`
it re-arms itself against `foo.vim` automatically.

## Deliberate changes from the original init.lua

These were bugs or duplicates, not preferences:

1. **Floaterminal**. `<leader>ot`, `<leader>tt`, `<leader>fd` and `:Floaterminal`
   passed a non-number slot (nil from the keymap, an options table from the
   command) and errored on `windows[nil]`. They default to terminal 0 now.
2. **acm-ls**. `dir` pointed at `/Users/jharmon/...` while `cmd` pointed at
   `/Users/johnharmon/...`. Both come from one config key, and the spec is
   skipped when the checkout is absent.
3. **mini.nvim was declared twice**, as `nvim-mini/mini.nvim` and
   `echasnovski/mini.nvim` — the same repo before and after its org move.
   Collapsed to `nvim-mini`.
4. **claudecode.nvim was declared twice**, the second copy nested inside the
   `snacks.nvim` spec table with a conflicting `winhl` value. Collapsed to one.
5. **Dead quickfix maps dropped.** `<C-j>`/`<C-k>` were bound to `cprev`/`cnext`
   (with `<CD>`, itself a typo for `<CR>`) and then overwritten ~300 lines later
   by kickstart's window-focus maps. `<<leader>j`/`<<leader>k` had a stray extra
   `<`. None of them ever fired.
6. **`lua_ls` is now actually started.** The `servers` table and its
   `capabilities` were built but the `mason-lspconfig` handler that consumed
   them was commented out, so nothing used either. It goes through
   `vim.lsp.config`/`enable` now.
7. **`client.supports_method` is guarded.** It became `client:supports_method`
   in 0.12 and the old call errored on attach.
8. **`nvim-web-devicons`** no longer carries a contradictory
   `enabled = vim.g.have_nerd_font` on the telescope dependency while being
   installed unconditionally at top level.
9. **`watch_for_changes` removed from the snacks opts** — it is an oil option
   that had leaked into the wrong table. Oil still sets it.
10. **Colorschemes are lazy.** All 14 non-active themes had an `init` that
    force-loaded them at startup; they use `opts` now and load on
    `:colorscheme`.
11. **`foldlevelstart` is not set in `core/options.lua`.** nvim-origami's `init`
    sets it to 99 and ran after the old top-of-file `= 0`; setting it in core
    would now run *later* than origami and re-fold every buffer.

Behaviour that looked odd but was kept as-is: `<leader>s` is both a standalone
substitute mapping and the Telescope prefix (so it waits for `timeoutlen`), and
`<C-f>` runs `tmux ne tmux-sessionizer`.
