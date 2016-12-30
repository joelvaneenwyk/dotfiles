"
" VIM Configuration
"

set encoding=utf-8
set runtimepath=~/.vim,$VIMRUNTIME        " Use our home directory settings.
set nocompatible                          " Don't bother with old VI compatibility.
"source $VIMRUNTIME/mswin.vim              " Make VIM windows-friendly.
set viminfo+=n~/.viminfo                  " Set where to store session info.

set history=50                            " Keep 50 lines of command line history.
set ruler                                 " Show the cursor position all the time.
set showcmd                               " Display incomplete commands.
set expandtab shiftwidth=3 softtabstop=3  " Use three spaces for tabs by default.
set cinoptions=(0,Ws                      " C-indent customizations.
set incsearch                             " Do incremental searching.
set ignorecase                            " Case-insensitive search.
set hlsearch                              " Highlight search strings.
set nobackup nowritebackup noswapfile     " Don't use backups or swap files.
set selection=inclusive                   " Include the current character in selections.
set nowrap                                " Don't wrap lines.
set nomousehide                           " Don't hide the mouse.
set scrolloff=5                           " Leave some space when scrolling.
set guioptions-=m                         " Hide menu bar.
set guioptions-=T                         " Hide tool bar.
set background=dark                       " Use the darker background.
set laststatus=2                          " Always show the status bar.
set noshowmode                            " Don't need the default mode line.
set hidden                                " Don't require saving before switching buffers.

set wildignore+=*.hi,*.o,*.one,*.pyc,tags.lock,tags,*.litcoffee.html,*.class,*/target/*

autocmd VimEnter * set vb t_vb=           " No beeps or flashes.
autocmd! bufwritepost .vimrc source %     " Auto-reload vimrc.

" File-type specific settings.
autocmd FileType css setlocal sw=2 sts=2
autocmd FileType less setlocal sw=2 sts=2
autocmd FileType jade setlocal sw=2 sts=2
autocmd FileType java setlocal sw=2 sts=2
autocmd FileType javascript setlocal sw=2 sts=2
autocmd FileType ruby setlocal sw=2 sts=2
autocmd FileType html setlocal sw=2 sts=2
autocmd FileType htmldjango setlocal sw=2 sts=2
autocmd FileType python setlocal sw=4 sts=4
autocmd FileType conf setlocal sw=4 sts=4
autocmd FileType coffee setlocal sw=2 sts=2
autocmd FileType litcoffee setlocal sw=2 sts=2
autocmd FileType haskell setlocal sw=4 sts=4
autocmd FileType yaml setlocal sw=2 sts=2

" Display control characters
"   For tabs, paint a >--
"   For trailing spaces, paint a -
set list
set lcs=tab:>-,trail:-

" For all modes, navigate by words delimited by any special character,
" instead of stopping only at whitespace.
map <C-Left> b
map <C-Right> w
imap <C-S-Left> <C-O><C-S-Left>
imap <C-S-Right> <C-O><C-S-Right>
vmap <C-S-Left> b
vmap <C-S-Right> w
nmap <C-S-Left> gh<C-S-Left>
nmap <C-S-Right> gh<C-S-Right>

" Indent/unindent using tabs.
vmap <Tab> ><CR>gv
vmap <S-Tab> <<CR>gv
imap <S-Tab> <C-D>

" Mappings for file tabs.
map <C-Tab> :bnext<CR>
map <C-S-Tab> :bprevious<CR>
map <C-Backspace> :Bdelete<CR>
map <C-Insert> :tabnew<CR>
map <C-Delete> :tabclose<CR>

" Programming mappings.
map <F5> :make<CR>
map <F8> :TagbarToggle<CR>

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
set rtp+=~/.vim/bundle/vundle/
call vundle#rc()

filetype off

" Generally useful plugins.
Bundle 'chriskempson/base16-vim'
Bundle 'moll/vim-bbye'
Bundle 'ctrlpvim/ctrlp.vim'
Bundle 'scrooloose/nerdtree'
Bundle 'majutsushi/tagbar'
Bundle 'bling/vim-airline'
Bundle 'terryma/vim-multiple-cursors'
Bundle 'vim-scripts/LargeFile'
Bundle 'tpope/vim-fugitive'
Bundle 'ervandew/supertab'

" Plugins for web development.
Bundle 'jelera/vim-javascript-syntax'
Bundle 'tpope/vim-markdown'
Bundle 'kchmck/vim-coffee-script'
Bundle 'groenewege/vim-less'
Bundle 'digitaltoad/vim-jade'

" Plugins for python development.
Bundle 'nvie/vim-flake8'

" Plugins for java/scala development.
Bundle 'derekwyatt/vim-scala'
Bundle 'ensime/ensime-vim'


" Configure airline.
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tagbar#enabled = 0
let g:airline_powerline_fonts = 1
let g:airline_theme = 'wombat'

" Configure CtrlP.
let g:ctrlp_clear_cache_on_exit = 0
let g:ctrlp_working_path_mode = 'ra'

" Configure NERDTree.
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTreeType") && b:NERDTreeType == "primary") | q | endif
let NERDTreeRespectWildIgnore=1
map <F2> :NERDTreeToggle<CR>

" Configure ensime.
autocmd BufWritePost *.scala silent :EnTypeCheck
au FileType scala nnoremap <localleader>t :EnTypeCheck<CR>
au FileType scala nnoremap <localleader>df :EnDeclaration<CR>

" Configure GUI settings.
colorscheme base16-bright

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

