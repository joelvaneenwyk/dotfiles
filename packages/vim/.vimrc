"
" VIM Configuration
"

set encoding=utf-8
set runtimepath=~/.vim,$VIMRUNTIME        " Use our home directory settings.
set nocompatible                          " Don't bother with old VI compatibility.
set viminfo+=n~/.viminfo                  " Set where to store session info.

set history=50                            " Keep 50 lines of command line history.
set showcmd                               " Display incomplete commands.
set expandtab shiftwidth=3 softtabstop=3  " Use three spaces for tabs by default.
set backspace=indent,eol,start            " Allow backspace to delete
set cinoptions=(0,Ws                      " C-indent customizations.
set incsearch                             " Do incremental searching.
set ignorecase                            " Case-insensitive search.
set hlsearch                              " Highlight search strings.
set nobackup nowritebackup noswapfile     " Don't use backups or swap files.
set selection=inclusive                   " Include the current character in selections.
set nowrap                                " Don't wrap lines.
set nomousehide                           " Don't hide the mouse.
set mouse=nicr                            " Enable mouse interactions.
set scrolloff=5                           " Leave some space when scrolling.
set guioptions-=m                         " Hide menu bar.
set guioptions-=T                         " Hide tool bar.
set background=dark                       " Use the darker background.
set laststatus=2                          " Always show the status bar.
set noshowmode                            " Don't need the default mode line.
set hidden                                " Don't require saving before switching buffers.
set clipboard=unnamed                     " Share clipboard with system.

set wildignore+=*.hi,*.o,*.one,*.pyc,tags.lock,tags,*.litcoffee.html,*.class,*/target/*

autocmd VimEnter * set vb t_vb=           " No beeps or flashes.
autocmd! bufwritepost .vimrc source %     " Auto-reload vimrc.

" File-type specific settings.
autocmd FileType coffee setlocal sw=2 sts=2
autocmd FileType conf setlocal sw=4 sts=4
autocmd FileType css setlocal sw=2 sts=2
autocmd FileType haskell setlocal sw=4 sts=4
autocmd FileType html setlocal sw=2 sts=2
autocmd FileType htmldjango setlocal sw=2 sts=2
autocmd FileType jade setlocal sw=2 sts=2
autocmd FileType java setlocal sw=2 sts=2
autocmd FileType javascript setlocal sw=2 sts=2
autocmd FileType json setlocal sw=2 sts=2
autocmd FileType less setlocal sw=2 sts=2
autocmd FileType litcoffee setlocal sw=2 sts=2
autocmd FileType markdown setlocal wrap linebreak tw=80
autocmd FileType nim setlocal sw=2 sts=2
autocmd FileType python setlocal sw=4 sts=4
autocmd FileType ruby setlocal sw=2 sts=2
autocmd FileType scss setlocal sw=2 sts=2
autocmd FileType tex setlocal wrap linebreak tw=80
autocmd FileType yaml setlocal sw=2 sts=2

" Display control characters
"   For tabs, paint a >--
"   For trailing spaces, paint a -
set list
set lcs=tab:>-,trail:-

" Indent/unindent using tabs.
vmap <Tab> ><CR>gv
vmap <S-Tab> <<CR>gv
imap <S-Tab> <C-D>

" Keep selection after indenting.
vnoremap > ><CR>gv
vnoremap < <<CR>gv

" Mappings for file tabs.
set wildchar=<Tab> wildmenu wildmode=full
set wildcharm=<C-Z>
nnoremap <F3> :b <C-Z>

if has('win32')
   set gfn=Inconsolata-dz_for_Powerline:h11

   " Only use transparency for local sessions (not over remote desktop).
   if !libcallnr("user32.dll", "GetSystemMetrics", 0x1000)
      "autocmd GUIEnter * call libcallnr("vimtweak.dll", "SetAlpha", 245)
      autocmd GUIEnter * call libcallnr("vimtweak.dll", "EnableMaximize", 1)
   endif
elseif has('mac')
   set gfn=Hack:h12
else
   set gfn=Hack\ 10
endif

" Load plugins.
call plug#begin('~/.vim/plugged')

" Generally useful.
Plug 'chriskempson/base16-vim'
Plug 'moll/vim-bbye'
Plug 'scrooloose/nerdtree'
Plug 'majutsushi/tagbar'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'terryma/vim-multiple-cursors'
Plug 'vim-scripts/LargeFile'
Plug 'tpope/vim-fugitive'
Plug 'luochen1990/rainbow'
Plug 'w0rp/ale'
Plug 'mileszs/ack.vim'
Plug 'jez/vim-github-hub'
Plug 'scrooloose/nerdcommenter'
Plug 'prabirshrestha/asyncomplete.vim'
Plug '/usr/local/opt/fzf'

" For web development.
Plug 'jelera/vim-javascript-syntax'
Plug 'tpope/vim-markdown'
Plug 'groenewege/vim-less'
Plug 'digitaltoad/vim-jade'
Plug 'Glench/Vim-Jinja2-Syntax'
Plug 'prettier/vim-prettier', { 'do': 'yarn install' }

" For python.
Plug 'nvie/vim-flake8'
Plug 'ludovicchabant/vim-gutentags'

" For latex.
Plug 'lervag/vimtex'

" For nim.
Plug 'alaviss/nim.nvim'

call plug#end()

" Configure airline.
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tagbar#enabled = 0
let g:airline_powerline_fonts = 1
let g:airline_theme = 'wombat'

" Configure NERDTree.
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTreeType") && b:NERDTreeType == "primary") | q | endif
let NERDTreeRespectWildIgnore=1
map <F2> :NERDTreeToggle<CR>

" Configure tags.
let g:gutentags_ctags_tagfile = '.git/tags'

" Configure ack.
let g:ackprg = 'ag --nogroup --nocolor --column'

" Configure vimtex.
let g:vimtex_view_method = 'skim'
let g:tex_flavor = 'latex'

if has('nvim')
  let g:vimtex_compiler_progname = 'nvr'
endif

" Configure fzf
let $FZF_DEFAULT_COMMAND = 'fd --type f'

let g:fzf_action = {
      \ 'ctrl-s': 'split',
      \ 'ctrl-v': 'vsplit'
      \ }
nnoremap <c-p> :FZF<cr>
augroup fzf
  autocmd!
  autocmd! FileType fzf
  autocmd  FileType fzf set laststatus=0 noshowmode noruler
    \| autocmd BufLeave <buffer> set laststatus=2 showmode ruler
augroup END


" Configure GUI settings.
if filereadable(expand("~/.vimrc_background"))
  let base16colorspace=256
  source ~/.vimrc_background
endif

if has('gui_running')
   set background=dark
   set noshowmode
   set spell
else
   set ttimeoutlen=10
   augroup FastEscape
      autocmd!
      au InsertEnter * set timeoutlen=0
      au InsertLeave * set timeoutlen=1000
   augroup END
endif

" Turn on file plugins and syntax highlighting.
filetype plugin indent on
syntax on

" When editing a file, always jump to the last known cursor position.
" Don't do it when the position is invalid or when inside an event handler
" (happens when dropping a file on gvim).
" Also don't do it when the mark is in the first line, that is the default
" position when opening a file.
function! PositionCursorFromVimInfo()
  if !(bufname("%") =~ '\(COMMIT_EDITMSG\)') && line("'\"") > 1 && line("'\"") <= line("$")
    exe "normal! g`\""
  endif
endfunction
autocmd BufReadPost * call PositionCursorFromVimInfo()

hi Normal guibg=NONE ctermbg=NONE
