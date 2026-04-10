-- SSH + tmux環境ではOSC52を優先してコピー連携を安定化
if vim.env.SSH_CONNECTION and vim.env.TMUX then
    vim.g.clipboard = "osc52"
end
