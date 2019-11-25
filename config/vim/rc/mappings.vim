" ESC
inoremap jj <ESC>

" moving cursor
nnoremap j gj
nnoremap k gk
vnoremap j gj
vnoremap k gk

" indent
vnoremap > >gv
vnoremap < <gv

" move
nnoremap <S-j> 10j
nnoremap <S-k> 10k

" clean white space
function! s:CleanSpace()
    let cursor = getpos(".")
    %s/\s\+$//ge
    call setpos(".", cursor)
    unlet cursor
endfunction

nnoremap <silent> <Space>ss :<C-u>call <SID>CleanSpace()<CR>