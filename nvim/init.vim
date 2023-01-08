call plug#begin("~/.local/share/nvim/plugged/")

	Plug 'morhetz/gruvbox'
	Plug 'christoomey/vim-tmux-navigator'
	Plug 'preservim/nerdtree'
	Plug 'Xuyuanp/nerdtree-git-plugin'
    Plug 'ryanoasis/vim-devicons'
	Plug 'nvim-lua/plenary.nvim'
	Plug 'nvim-telescope/telescope.nvim', { 'tag': '0.1.0' }
	Plug 'nvim-telescope/telescope-file-browser.nvim'
	Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
	Plug 'junegunn/fzf.vim'
	Plug 'nathanaelkane/vim-indent-guides'
	Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
	Plug 'neoclide/coc.nvim', {'branch': 'release'}
	Plug 'APZelos/blamer.nvim'
	Plug 'christoomey/vim-tmux-navigator'
	Plug 'tpope/vim-commentary'
	Plug 'sheerun/vim-polyglot'
    Plug 'CoatiSoftware/vim-sourcetrail'
	Plug 'cespare/vim-toml'
    Plug 'preservim/tagbar'
    Plug 'craigemery/vim-autotag'
    Plug 'stevearc/dressing.nvim'
    Plug 'krady21/compiler-explorer.nvim'
    Plug 'puremourning/vimspector'

call plug#end()

" indent settings
set autoindent expandtab tabstop=4 shiftwidth=4
set autoindent

" Theme
set background=dark
colorscheme gruvbox
set number

" NERDTree Mappings
noremap <silent> <C-b> :NERDTreeToggle<CR>
" " Close window if NERDTree is the last one
autocmd BufEnter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
" " Map to open current file in NERDTree and set size
nnoremap <leader>pv :NERDTreeFind<bar> :vertical resize 45<CR>

" Telescope mappings
nnoremap <leader>ff <cmd>Telescope find_files<cr>
nnoremap <leader>fg <cmd>Telescope live_grep<cr>
nnoremap <leader>gf <cmd>Telescope git_files<cr>
nnoremap <leader>fb <cmd>Telescope buffers<cr>
nnoremap <leader>fh <cmd>Telescope help_tags<cr>
nnoremap <leader>vo <cmd>Telescope vim_options<cr>
nnoremap <leader>mp <cmd>Telescope man_pages<cr>

" Vim spector mapping
func! GotoWindow(id)
    :call win_gotoid(a:id)
endfunction
func! AddToWatch()
    let word = expand("<cexpr>")
    call vimspector#AddWatch(word)
endfunction
func! AddToWatchInput()
    let word = input('Watch var: ')
    call vimspector#AddWatch(word)
endfunction
 let g:vimspector_base_dir = expand('$HOME/.config/vimspector-config')
 let g:vimspector_sidebar_width = 60
 nnoremap <leader>da :call vimspector#Launch()<CR>
 nnoremap <leader>dc :call GotoWindow(g:vimspector_session_windows.code)<CR>
 nnoremap <leader>dv :call GotoWindow(g:vimspector_session_windows.variables)<CR>
 nnoremap <leader>dw :call GotoWindow(g:vimspector_session_windows.watches)<CR>
 nnoremap <leader>ds :call GotoWindow(g:vimspector_session_windows.stack_trace)<CR>
 nnoremap <leader>do :call GotoWindow(g:vimspector_session_windows.output)<CR>
 nnoremap <leader>di :call AddToWatch()<CR>
 nnoremap <leader>du :call AddToWatchInput()<CR>
 nnoremap <leader>dx :call vimspector#Reset()<CR>
 nnoremap <leader>dX :call vimspector#ClearBreakpoints()<CR>
 nnoremap <S-h> :call vimspector#StepOut()<CR>
 nnoremap <S-j> :call vimspector#StepInto()<CR>
 nnoremap <S-l> :call vimspector#StepOver()<CR>
 nnoremap <leader>d_ :call vimspector#Restart()<CR>
 nnoremap <leader>dn :call vimspector#Continue()<CR>
 nnoremap <leader>drc :call vimspector#RunToCursor()<CR>
 nnoremap <leader>dh :call vimspector#ToggleBreakpoint()<CR>
 nnoremap <leader>de :call vimspector#ToggleConditionalBreakpoint()<CR>
 let g:vimspector_sign_priority = {
   \    'vimspectorBP':         998,
   \    'vimspectorBPCond':     997,
   \    'vimspectorBPDisabled': 996,
   \    'vimspectorPC':         999,
   \ } 
 "


" Fuzzy search
nnoremap <C-p> :Files ~/<CR>
nnoremap <C-f> :Files <CR>
let g:fzf_action = {
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-s': 'split',
  \ 'ctrl-v': 'vsplit'
  \}
nmap <Leader>l :BLines<CR>
nmap <Leader>L :Lines<CR>

" vim-indent-guides settings
let g:indent_guides_enable_on_vim_startup = 1

" Git blame toggle
let g:blamer_enabled = 1

" Split Resize
nnoremap <silent> <C-m> :5winc ><CR> 
nnoremap <silent> <C-n> :5winc <<CR> 
nnoremap <leader>r :vertical resize 170<CR> 

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

" autocompletion
" Use tab for trigger completion with characters ahead and navigate.
" Use command ':verbose imap <tab>' to make sure tab is not mapped by other plugin.
" use <tab> to trigger completion and navigate to the next complete item
function! CheckBackspace() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

inoremap <silent><expr> <Tab>
      \ coc#pum#visible() ? coc#pum#next(1) :
      \ CheckBackspace() ? "\<Tab>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

" Use <c-space> to trigger completion.
inoremap <silent><expr> <c-space> coc#refresh()

" Use <cr> to confirm completion, `<C-g>u` means break undo chain at current position.
" Coc only does snippet and additional edit on confirm.
inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"

" Coc settings and mappings
" Use `[c` and `]c` to navigate diagnostics
nmap <silent> [c <Plug>(coc-diagnostic-prev)
nmap <silent> ]c <Plug>(coc-diagnostic-next)

nnoremap <leader>fa <cmd> :lua vim.lsp.buf.code_action() <CR>

" Remap keys for gotos
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
nmap <silent> gv :call CocAction('jumpDefinition', 'vsplit')<CR>
nmap <silent> gs :call CocAction('jumpDefinition', 'split')<CR>

" Tagbar toggle
nnoremap <leader>s <cmd> :TagbarToggle<CR>
nnoremap <leader>p  <cmd> :TagbarTogglePause<CR>

" Remap keys to jum to beginning and end of functions
nnoremap ]] ][
nnoremap ][ ]]
" Use K to show documentation in preview window
nnoremap <silent> K :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
	execute 'h '.expand('<cword>')
  else
	call CocAction('doHover')
  endif
endfunction

" Doxygen Comments
let g:DoxygenToolkit_briefTag_pre="@Synopsis  "
let g:DoxygenToolkit_paramTag_pre="@Param "
let g:DoxygenToolkit_returnTag="@Returns   "
let g:DoxygenToolkit_blockHeader="--------------------------------------------------------------------------"
let g:DoxygenToolkit_blockFooter="----------------------------------------------------------------------------"
let g:DoxygenToolkit_authorName="Kushal Gandhi"
let g:DoxygenToolkit_licenseTag="My own license"

" Commentary 
nnoremap <leader>gc <cmd> :Commentary <CR>

" Compiler Explorer Mappings
nnoremap <leader>I <cmd> :CEFormat<CR>
