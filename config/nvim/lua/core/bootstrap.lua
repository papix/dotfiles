local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazy_repo = "https://github.com/folke/lazy.nvim.git"
    local result = vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "--branch=stable",
        lazy_repo,
        lazypath,
    })

    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
            { "lazy.nvim bootstrap failed:\n", "ErrorMsg" },
            { result, "WarningMsg" },
        }, true, {})
    end
end

if (vim.uv or vim.loop).fs_stat(lazypath) then
    vim.opt.rtp:prepend(lazypath)

    local ok, lazy = pcall(require, "lazy")
    if ok then
        lazy.setup("plugins", {
            checker = {
                enabled = false,
            },
        })
    else
        vim.api.nvim_echo({
            { "lazy.nvim load failed:\n", "WarningMsg" },
            { tostring(lazy), "WarningMsg" },
        }, true, {})
    end
end
