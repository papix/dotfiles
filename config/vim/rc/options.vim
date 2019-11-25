" ########################################
" # General
" ########################################
set encoding=utf-8
set fileencoding=utf-8
set fileencodings=utf-8,iso-2022-jp,euc-jp,ucs-2le,ucs-2,cp932

set fileformat=unix
set fileformats=unix,dos,mac

set updatetime=100

" use OS native clipboard
if has('clipboard')
  set clipboard=unnamed
endif

" reload files when it changed outeside of Vim
set autoread

" backup
set backupdir=~/.config/nvim/backup
set directory=~/.config/nvim/swap

" undo
set undodir=~/.config/nvim/undo
set undolevels=500

" modernize the function of backspace
set backspace=indent,eol,start

" Modernize moving the cursor
set whichwrap=b,s,h,l,<,>,[,]

" maximum width of text
set textwidth=0

" ########################################
" # Appearance
" ########################################

syntax enable on
set t_Co=256

" show 2 status lines
set laststatus=2

" jump to the matching brace briefly when insert one
set showmatch

" prevent multibyte characters layout from collapsing
if exists('&ambiwidth')
  set ambiwidth=double
endif

" ########################################
" # Indent
" ########################################

set autoindent

" use soft tab
set expandtab

" 1 tab = 4 spaces
set tabstop=4
set shiftwidth=4
set softtabstop=4
set shiftround
set smarttab

augroup HighlightTrailingSpaces
  autocmd!
  autocmd VimEnter,WinEnter,ColorScheme * highlight TrailingSpaces term=underline guibg=Red ctermbg=Red
  autocmd VimEnter,WinEnter * match TrailingSpaces /\s\+$/
augroup END

" ########################################
" # Search
" ########################################

set incsearch
set hlsearch

" case sensitive search
set ignorecase

" `set noignorecase` if a pattern contans an uppercase letter
set smartcase

" wrap around to the beginning when `search next` reaches end of file
set wrapscan

set completeopt+=noselect

" ########################################
" # Sound
" ########################################

set noerrorbells
set novisualbell
