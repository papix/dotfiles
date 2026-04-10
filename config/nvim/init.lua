-- Neovim専用設定
-- 共通設定は既存のvimrcを読み込んで再利用する
vim.cmd([[source ~/.vimrc]])

require("core.bootstrap")
require("core.options")
require("core.providers")
require("core.clipboard")
