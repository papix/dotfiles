" perl
autocmd BufNewFile,BufRead *.psgi set filetype=perl
autocmd BufNewFile,BufRead *.t    set filetype=perl

" javascript
autocmd BufNewFile,BufRead *.ts  set filetype=typescript
autocmd BufNewFile,BufRead *.tsx set filetype=typescript

autocmd FileType javascript :set tabstop=2 shiftwidth=2 softtabstop=2
autocmd FileType typescript :set tabstop=2 shiftwidth=2 softtabstop=2

" go
autocmd FileType go :set tabstop=2 shiftwidth=2 softtabstop=2

" ruby
autocmd FileType ruby :set tabstop=2 shiftwidth=2 softtabstop=2

" html
autocmd BufNewFile,BufRead *.tx set filetype=html
autocmd BufNewFile,BufRead *.tt set filetype=html
autocmd FileType html :set tabstop=2 shiftwidth=2 softtabstop=2

" vim
autocmd FileType vim :set tabstop=2 shiftwidth=2 softtabstop=2

" zsh
autocmd FileType zsh :set tabstop=2 shiftwidth=2 softtabstop=2

" yaml
autocmd FileType yaml :set tabstop=2 shiftwidth=2 softtabstop=2
