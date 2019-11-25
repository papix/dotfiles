let g:plugins_dir = expand($HOME.'/.config/nvim/plugins')

call plug#begin(g:plugins_dir)

" snippets
Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'

" edit
Plug 'cohama/lexima.vim'
Plug 'h1mesuke/vim-alignta'
Plug 'tyru/caw.vim'
Plug 'othree/eregex.vim'

" git
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'

Plug 'itchyny/lightline.vim'
Plug 'thinca/vim-splash'

Plug 'fatih/vim-go',                 { 'for': 'go', 'do': ':GoInstallBinaries' }
Plug 'jelera/vim-javascript-syntax', { 'for': 'js' }
Plug 'vim-perl/vim-perl',            { 'for': 'perl' }
Plug 'leafgarland/typescript-vim',   { 'for': 'typescript' }

call plug#end()

function! s:is_installed(plugin_name)
  let plugins = expand(g:plugins_dir.'/'.a:plugin_name)

  if isdirectory(plugins)
    return 1
  endif

  return 0
endfunction

" set , as <Leader>
let mapleader = ","

" settings
if s:is_installed('ultisnips')
  let g:UltiSnipsExpandTrigger = "<C-o>"

  " kill default mappings for ultisnips
  let g:UltiSnipsJumpForwardTrigger = "<nop>"
  let g:UltiSnipsJumpBackwardTrigger = "<nop>"

  let g:UltiSnipsSnippetsDir = expand($HOME.'/.vim/snippets')
endif

if s:is_installed('lexima.vim')
  inoremap [ []<LEFT>
  inoremap ( ()<LEFT>
  inoremap " ""<LEFT>
  inoremap ' ''<LEFT>
  inoremap ` ``<LEFT>
endif

if s:is_installed('vim-alignta')
  vnoremap <silent> <Space>a= :Alignta =/1<CR>
  vnoremap <silent> <Space>a> :Alignta =>/1<CR>
endif

if s:is_installed('caw.vim')
  nmap <silent> # <Plug>(caw:zeropos:toggle)
  xmap <silent> # <Plug>(caw:zeropos:toggle)
endif

if s:is_installed('eregex.vim')
  let g:eregex_default_enable = 0
endif

if s:is_installed('lightline.vim') && s:is_installed('vim-fugitive')
  let g:lightline = {
    \ 'colorscheme': 'solarized',
    \ 'active': {
    \   'left': [ [ 'mode', 'paste' ], [ 'filename', 'git' ] ]
    \ },
    \ 'component_function': {
    \   'git': 'LightLineGit'
    \ },
    \ 'separator': { 'left': '⮀', 'right': '⮂' },
    \ 'subseparator': { 'left': '⮁', 'right': '⮃' }
    \ }

  function! LightLineGit()
    if exists("*fugitive#head")
      let _ = fugitive#head()
      return strlen(_) ? '⭠ '._ : ''
    endif
    return ''
  endfunction
endif
