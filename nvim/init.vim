call plug#begin()
    Plug 'michaeldyrynda/carbon'
    Plug 'startup-nvim/startup.nvim'
    Plug 'ttibsi/pre-commit.nvim'
    Plug 'nvim-lua/plenary.nvim'
    Plug 'nvim-lua/popup.nvim'
    Plug 'MattesGroeger/vim-bookmarks'
    Plug 'nvim-telescope/telescope.nvim', { 'tag': '0.1.8' }
    Plug 'LinArcX/telescope-ports.nvim'
    Plug 'tom-anders/telescope-vim-bookmarks.nvim'
    Plug 'nvim-telescope/telescope-file-browser.nvim'
    Plug 'fannheyward/telescope-coc.nvim'
    Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
    Plug 'junegunn/fzf.vim'
    Plug 'neoclide/coc.nvim', {'branch': 'release'}
    Plug 'APZelos/blamer.nvim'
    Plug 'christoomey/vim-tmux-navigator'
    Plug 'tpope/vim-commentary'
    Plug 'sheerun/vim-polyglot'
    Plug 'cespare/vim-toml'
    Plug 'preservim/tagbar'
    Plug 'craigemery/vim-autotag'
    Plug 'stevearc/dressing.nvim'
    Plug 'vim-airline/vim-airline'
    Plug 'vim-airline/vim-airline-themes'
    Plug 'dart-lang/dart-vim-plugin'
    Plug 'mtikekar/vim-bsv'
    Plug 'nyoom-engineering/oxocarbon.nvim'
    Plug 'mikesmithgh/borderline.nvim'
    Plug 'kdheepak/lazygit.nvim'
    Plug 'rcarriga/nvim-notify'
    Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
    Plug 'lukas-reineke/indent-blankline.nvim'
    Plug 'MunifTanjim/nui.nvim'
    Plug 'folke/noice.nvim'
    Plug 'williamboman/mason.nvim'
    Plug 'uga-rosa/ccc.nvim'
    Plug 'simeji/winresizer'
    Plug 'David-Kunz/gen.nvim'
    Plug 'xiyaowong/transparent.nvim'
    Plug 'AckslD/nvim-neoclip.lua'
    Plug 'VonHeikemen/searchbox.nvim'
    Plug 'nacro90/numb.nvim'
    Plug 'nvim-tree/nvim-web-devicons'
    Plug 'mhartington/formatter.nvim'
    Plug 'vim-autoformat/vim-autoformat'
    Plug 'theHamsta/nvim-semantic-tokens'
call plug#end()

" ❯
"
" indent settings
set autoindent expandtab tabstop=4 shiftwidth=4
set autoindent

set mouse=a

set number
set cursorline
highlight CursorLine guibg=#222222

" Airline settings
let g:airline_powerline_fonts = 1
let g:airline_theme='wombat'

syntax on
hi Visual cterm=none ctermbg=darkgrey ctermfg=white

" Floating border highlight settings
autocmd VimEnter * highlight FloatBorder guifg=#25c2a0 guibg=NONE

" Make the inactive window a little dimmer
autocmd WinEnter * setlocal winhighlight=Normal:Normal,NormalNC:NormalDim
autocmd WinLeave * setlocal winhighlight=Normal:NormalDim

highlight NormalDim guibg=#0c0c0c guifg=NONE

" Window seperator border color
" highlight WinSeparatorActive guifg=#78a9ff guibg=NONE
autocmd WinEnter * highlight WinSeparator guifg=#3c4048 guibg=NONE

" Theme
" let g:gruvbox_contrast_dark = 'hard'
" set background=dark
colorscheme oxocarbon

" To expand your window size toward upper using upper arrow (instead of k)
let g:winresizer_keycode_up = "\<UP>"
" To expand your window size toward lower using down arrow (instead of j)
let g:winresizer_keycode_down = "\<DOWN>"
" To expand your window size toward left using left arrow (instead of h)
let g:winresizer_keycode_left = "\<LEFT>"
" To expand your window size toward right using right arrow (instead of l)
let g:winresizer_keycode_right = "\<RIGHT>"

" Greeter
lua << EOF
require("startup").setup({theme = "dashboard"})
EOF

nnoremap <leader>pc :Precommit<CR>

" Copy to clipboard
set clipboard=unnamedplus
vnoremap <leader>y "+y

" augroup dynamic_highlight
"     autocmd!
"     autocmd CursorMoved,TextChanged * call clearmatches()
" augroup END

let g:lsc_auto_map = v:true

" Borderline
lua << EOF
require('borderline').setup({
        --  ...
    })
EOF

lua << EOF
require("notify").setup({
    background_colour = "#000000", -- Use the background color of Normal highlight group
})
EOF

" Map for no highlight
nnoremap <leader>nh :nohlsearch<CR>

" numb settings
lua << EOF
require('numb').setup()
EOF

" web devicons settings
lua << EOF
require('nvim-web-devicons').setup()
EOF

" semantics tokens settings
lua << EOF
require("nvim-semantic-tokens").setup {
  preset = "default",
  -- highlighters is a list of modules following the interface of nvim-semantic-tokens.table-highlighter or
  -- function with the signature: highlight_token(ctx, token, highlight) where
  --        ctx (as defined in :h lsp-handler)
  --        token  (as defined in :h vim.lsp.semantic_tokens.on_full())
  --        highlight (a helper function that you can call (also multiple times) with the determined highlight group(s) as the only parameter)
  highlighters = { require 'nvim-semantic-tokens.table-highlighter'}
}
EOF

" Telescopes settings
autocmd VimEnter * highlight TelescopeBorder guifg=#78a9ff guibg=#000000
autocmd VimEnter * highlight TelescopePromptBorder guifg=#78a9ff guibg=#000000
autocmd VimEnter * highlight TelescopeNormal guibg=#000000
autocmd VimEnter * highlight TelescopePromptNormal guibg=#000000
autocmd VimEnter * highlight TelescopePromptPrefix guifg=#000000 guibg=#000000
lua << EOF
local actions = require("telescope.actions")  -- Import actions
require('telescope').setup{

  defaults = {
    border = true,
    winblend = 0,  -- Optional: Adds slight transparency
    borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" }, -- Customize border style
    prompt_prefix = " 🔍 ",
    selection_caret = "➜ ",
    border = true,
    -- Custom highlight groups
    results_title = false,
    preview_title = false,
    prompt_title = false,
    layout_config = {
      scroll_speed = 1,
      prompt_position = "bottom",
    },
    mappings = {
      i = {
        -- map actions.which_key to <C-h> (default: <C-/>)
        -- actions.which_key shows the mappings for your picker,
        -- e.g. git_{create, delete, ...}_branch for the git_branches picker
        ["<C-h>"] = "which_key",
        ["dd"] = actions.delete_buffer,
        ["<ScrollWheelUp>"]   = require('telescope.actions').preview_scrolling_up,
        ["<ScrollWheelDown>"] = require('telescope.actions').preview_scrolling_down,
      },
      n = {
        ["<ScrollWheelUp>"]   = require('telescope.actions').preview_scrolling_up,
        ["<ScrollWheelDown>"] = require('telescope.actions').preview_scrolling_down,
      }
    }
  },
  pickers = {
    -- Default configuration for builtin pickers goes here:
    -- picker_name = {
    --   picker_config_key = value,
    --   ...
    -- }
    -- Now the picker_config_key will be applied every time you call this
    -- builtin picker
  },
  extensions = {
    -- Your extension configuration goes here:
    -- please take a look at the readme of the extension you want to configure
    file_browser = {
      theme = "ivy",  -- Optional: Set "ivy" for bottom-aligned layout
      hijack_netrw = true,
      grouped = true,
      display_stat = false,
      mappings = {},
      layout_strategy = "vertical",   -- Use vertical layout
      layout_config = {
        width = 0.3,    -- 30% of the screen width
        height = 0.9,   -- 90% of the screen height
        prompt_position = "top",
        mirror = true, -- Keep it left-aligned
        anchor = "W"    -- Anchor it to the west (left side)
      }
    }

  }
}
require('telescope').load_extension('coc')
require('telescope').load_extension('ports')
require('telescope').load_extension('vim_bookmarks')
require('telescope').load_extension('file_browser')
EOF
nnoremap <leader>ff :lua require('telescope.builtin').find_files({ border = true })<CR>
nnoremap <leader>fl <cmd>Telescope current_buffer_fuzzy_find<cr>
nnoremap <leader>fg <cmd>Telescope live_grep<cr>
nnoremap <leader>gf <cmd>Telescope git_files<cr>
nnoremap <leader>fb <cmd>Telescope buffers<cr>
nnoremap <leader>fh <cmd>Telescope help_tags<cr>
nnoremap <leader>vo <cmd>Telescope vim_options<cr>
nnoremap <leader>mp <cmd>Telescope man_pages<cr>
nnoremap <leader>fk <cmd>Telescope keymaps<cr>
nnoremap <leader>fd <cmd>Telescope coc diagnostics<cr>
nnoremap <leader>fc <cmd>Telescope neoclip<cr>
nnoremap <leader>pv <cmd>Telescope file_browser path=%:p:h<cr>
nnoremap <C-t>      <cmd>Telescope file_browser path=<root-directly><cr>
nnoremap ma <cmd>Telescope vim_bookmarks current_file<cr>

" Formatter settings
lua << EOF
-- Utilities for creating configurations
local util = require "formatter.util"

-- Provides the Format, FormatWrite, FormatLock, and FormatWriteLock commands
require("formatter").setup {
  -- Enable or disable logging
  logging = true,
  -- Set the log level
  log_level = vim.log.levels.WARN,
  -- All formatter configurations are opt-in
  filetype = {
    -- Lua formatter (stylua)
    lua = {
      require("formatter.filetypes.lua").stylua,
      function()
        if util.get_current_buffer_file_name() == "special.lua" then
          return nil
        end
        return {
          exe = "stylua",
          args = {
            "--search-parent-directories",
            "--stdin-filepath",
            util.escape_path(util.get_current_buffer_file_path()),
            "--",
            "-",
          },
          stdin = true,
        }
      end,
    },

    -- C++ formatter (clang-format)
    c = {
      require("formatter.filetypes.c").clangformat,
      function()
        return {
          exe = "clang-format",
          args = { "--style=file", "--assume-filename=" .. vim.api.nvim_buf_get_name(0) },
          stdin = true,
        }
      end,
    },
    -- C++ formatter (clang-format)
    cpp = {
      require("formatter.filetypes.cpp").clangformat,
      function()
        return {
          exe = "clang-format",
          args = { "--style=file", "--assume-filename=" .. vim.api.nvim_buf_get_name(0) },
          stdin = true,
        }
      end,
    },

    -- Python formatter (black)
    python = {
      require("formatter.filetypes.python").black,
      function()
        return {
          exe = "black",
          args = { "--quiet", "-" },
          stdin = true,
        }
      end,
    },

    -- Use the special "*" filetype for defining formatter configurations on any filetype
    ["*"] = {
      require("formatter.filetypes.any").remove_trailing_whitespace,
    },
  }
}
EOF
augroup FormatAutogroup
  autocmd!
  autocmd BufWritePost * FormatWrite
augroup END

" Lazygit settings
nnoremap <leader>lg :LazyGit<CR>

" Change the background of the scrollbar
autocmd VimEnter * highlight Satellite guifg=NONE guibg=#161616

" searchbox settings
lua << EOF
require('searchbox').setup({
  defaults = {
    reverse = false,
    exact = false,
    prompt = ' ',
    modifier = 'disabled',
    confirm = 'off',
    clear_matches = true,
    show_matches = false,
  },
  popup = {
    relative = 'win',
    position = {
      row = '5%',
      col = '50%',
    },
    size = 40,
    border = {
      style = 'rounded',
      text = {
        top = ' Search ',
        top_align = 'center',
      },
    },
    win_options = {
      winhighlight = 'Normal:Normal,FloatBorder:FloatBorder',
    },
  },
  hooks = {
    before_mount = function(input)
      -- code
    end,
    after_mount = function(input)
      -- code
    end,
    on_done = function(value, search_type)
      -- code
    end
  }
})
EOF
nnoremap <leader>s :SearchBoxReplace<CR>

" Neoclip settings
lua << EOF
require('neoclip').setup({
  history = 1000,
  enable_persistent_history = false,
  length_limit = 1048576,
  continuous_sync = false,
  db_path = vim.fn.stdpath("data") .. "/databases/neoclip.sqlite3",
  filter = nil,
  preview = true,
  prompt = nil,
  default_register = { '"', '+' },
  default_register_macros = 'q',
  enable_macro_history = true,
  content_spec_column = false,
  disable_keycodes_parsing = false,
  dedent_picker_display = false,
  initial_mode = 'insert',
  on_select = {
	move_to_front = false,
	close_telescope = true,
  },
  on_paste = {
	set_reg = false,
	move_to_front = false,
	close_telescope = true,
  },
  on_replay = {
	set_reg = false,
	move_to_front = false,
	close_telescope = true,
  },
  on_custom_action = {
	close_telescope = true,
  },
  keys = {
	telescope = {
	  i = {
		select = '<cr>',
		paste = '<c-p>',
		paste_behind = '<c-k>',
		replay = '<c-q>',  -- replay a macro
		delete = '<c-d>',  -- delete an entry
		edit = '<c-e>',  -- edit an entry
		custom = {},
	  },
	  n = {
		select = '<cr>',
		paste = 'p',
		--- It is possible to map to more than one key.
		-- paste = { 'p', '<c-p>' },
		paste_behind = 'P',
		replay = 'q',
		delete = 'd',
		edit = 'e',
		custom = {},
	  },
	},
	fzf = {
	  select = 'default',
	  paste = 'ctrl-p',
	  paste_behind = 'ctrl-k',
	  custom = {},
	},
  },
})
EOF

" Treesitter configuration
lua << EOF
require'nvim-treesitter.configs'.setup {
  -- A list of parser names, or "all" (the listed parsers MUST always be installed)
  ensure_installed = { "c", "cpp", "cmake", "lua", "vim", "vimdoc", "query", "markdown", "markdown_inline" },

  -- Install parsers synchronously (only applied to `ensure_installed`)
  sync_install = false,

  -- Automatically install missing parsers when entering buffer
  -- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
  auto_install = true,

  -- List of parsers to ignore installing (or "all")
  ignore_install = { "javascript" },

  ---- If you need to change the installation directory of the parsers (see -> Advanced Setup)
  -- parser_install_dir = "/some/path/to/store/parsers", -- Remember to run vim.opt.runtimepath:append("/some/path/to/store/parsers")!

  highlight = {
    enable = true,

    -- NOTE: these are the names of the parsers and not the filetype. (for example if you want to
    -- disable highlighting for the `tex` filetype, you need to include `latex` in this list as this is
    -- the name of the parser)
    -- list of language that will be disabled
    -- Or use a function for more flexibility, e.g. to disable slow treesitter highlight for large files
    disable = function(lang, buf)
        local max_filesize = 100 * 1024 -- 100 KB
        local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
        if ok and stats and stats.size > max_filesize then
            return true
        end
    end,

    -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
    -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
    -- Using this option may slow down your editor, and you may see some duplicate highlights.
    -- Instead of true it can also be a list of languages
    additional_vim_regex_highlighting = false,
  },
}
EOF

" Indent Blankline settings
lua << EOF
require("ibl").setup { scope = { enabled = false} }
EOF

" Noice settings
lua << EOF
require("noice").setup({
  lsp = {
    -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
    override = {
      ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
      ["vim.lsp.util.stylize_markdown"] = true,
      ["cmp.entry.get_documentation"] = true, -- requires hrsh7th/nvim-cmp
    },
  },
  -- you can enable a preset for easier configuration
  presets = {
    bottom_search = true, -- use a classic bottom cmdline for search
    command_palette = true, -- position the cmdline and popupmenu together
    long_message_to_split = true, -- long messages will be sent to a split
    inc_rename = false, -- enables an input dialog for inc-rename.nvim
    lsp_doc_border = false, -- add a border to hover docs and signature help
  },
  routes = {
    {
      filter = { event = "msg_show", kind = "", find = "NERDTree" },
      opts = { skip = true },  -- Prevent Noice from capturing the message
    },
  },
})
EOF

" Mason settings
lua << EOF
require("mason").setup()
EOF

" CCC settings
lua << EOF
require("ccc").setup()
EOF
nnoremap <leader>ccc :CccPick<CR>

" Fuzzy search
nnoremap <C-p> :Files ~/<CR>
let g:fzf_action = {
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-x': 'split',
  \ 'ctrl-v': 'vsplit'
  \}
nmap <Leader>l :BLines<CR>
nmap <Leader>L :Lines<CR>

" vim-indent-guides settings
let g:indent_guides_enable_on_vim_startup = 1

" Git blame toggle
let g:blamer_enabled = 1

nnoremap <leader>sr :SourcetrailRefresh<CR>
nnoremap <leader>sc :SourcetrailActivateToken<CR>

" Vim Navigate splits mapping
" Use ctrl-[hjkl] to select the active split!
nmap <silent> <c-k> :wincmd k<CR>
nmap <silent> <c-j> :wincmd j<CR>
nmap <silent> <c-h> :wincmd h<CR>
nmap <silent> <c-l> :wincmd l<CR>

" Tag file generation
let g:autotagTagsFile="~/.tags"

" Cpp Setup
syntax on
filetype plugin indent on

source $HOME/.config/nvim/plug-config/coc.vim

" Flutter Mapping
" nnoremap <leader>fr <cmd> :CocCommand flutter.run<CR>
" nnoremap <leader>fa <cmd> :CocCommand flutter.attach<CR>
" nnoremap <leader>fd <cmd> :CocCommand flutter.doctor<CR>
" nnoremap <leader>fdr <cmd> :CocCommand flutter.dev.hotReload<CR>
" nnoremap <leader>fdx <cmd> :CocCommand flutter.dev.hotRestart<CR>

" Tagbar toggle
nnoremap <leader>x <cmd> :TagbarToggle<CR>
nnoremap <leader>p  <cmd> :TagbarTogglePause<CR>

" Remap keys to jum to beginning and end of functions
nnoremap ]] ][
nnoremap ][ ]]

" Commentary
nnoremap <leader>gc <cmd> :Commentary <CR>

" Chat with Ollama models
lua << EOF
require("gen").setup {
        vim.keymap.set({ 'n', 'v' }, '<leader>a', ':Gen<CR>'),
        model = "llama3.1", -- The default model to use.
        quit_map = "q", -- set keymap for close the response window
        retry_map = "<c-r>", -- set keymap to re-send the current prompt
        accept_map = "<c-cr>", -- set keymap to replace the previous selection with the last result
        host = "localhost", -- The host running the Ollama service.
        port = "11434", -- The port on which the Ollama service is listening.
        display_mode = "horizontal-split", -- The display mode. Can be "float" or "split" or "horizontal-split".
        show_prompt = true, -- Shows the prompt submitted to Ollama.
        show_model = true, -- Displays which model you are using at the beginning of your chat session.
        no_auto_close = false, -- Never closes the window automatically.
        hidden = false, -- Hide the generation window (if true, will implicitly set `prompt.replace = true`), requires Neovim >= 0.10
        init = function(options) pcall(io.popen, "ollama serve > /dev/null 2>&1 &") end,
        -- Function to initialize Ollama
        command = function(options)
            local body = {model = options.model, stream = true}
            return "curl --silent --no-buffer -X POST http://" .. options.host .. ":" .. options.port .. "/api/chat -d $body"
        end,
        -- The command for the Ollama service. You can use placeholders $prompt, $model and $body (shellescaped).
        -- This can also be a command string.
        -- The executed command must return a JSON object with { response, context }
        -- (context property is optional).
        -- list_models = '<omitted lua function>', -- Retrieves a list of model names
        debug = false -- Prints errors and the command which is run.
    }
EOF
