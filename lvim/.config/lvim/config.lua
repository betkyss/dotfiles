-- /home/q/dotfiles/lvim/.config/lvim/config.lua
--[[
  Single-file structured configuration for LunarVim.
  All settings are organized into logical sections for clarity.
]]

-- ======================================================================
-- LSP (Language Server Protocol) & Diagnostics
-- ======================================================================

-- Полностью отключаем все diagnostics (виртуальный текст, знаки в гуттере, подчёркивания)
vim.diagnostic.config({
  virtual_text = false,
  signs = false,
  underline = false,
  update_in_insert = false,
})

-- Ещё раз закрепляем через LSP‑хэндлер, если что-то переписывает настройки
vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
  vim.lsp.diagnostic.on_publish_diagnostics, {
    virtual_text = false,
    signs = false,
    underline = false,
    update_in_insert = false,
  }
)

-- Патчим функцию make_position_params, чтобы не вываливалось предупреждение
do
  local orig = vim.lsp.util.make_position_params
  vim.lsp.util.make_position_params = function(opts)
    if type(opts) ~= "table" then
      opts = {}
    end
    opts.position_encoding = opts.position_encoding or "utf-16"
    return orig(opts)
  end
end

-- ======================================================================
-- General Editor Options
-- ======================================================================

vim.opt.relativenumber = true
vim.opt.termguicolors = true
lvim.colorscheme = "onedark"

-- ======================================================================
-- Autocommands
-- ======================================================================

local augroup = vim.api.nvim_create_augroup

-- Сохранение/восстановление складок
local save_fold = augroup("Persistent Folds", { clear = true })
vim.api.nvim_create_autocmd("BufWinLeave", {
  pattern = "*.*",
  callback = function() vim.cmd.mkview() end,
  group = save_fold,
})
vim.api.nvim_create_autocmd("BufWinEnter", {
  pattern = "*.*",
  callback = function() vim.cmd.loadview({ mods = { emsg_silent = true } }) end,
  group = save_fold,
})

-- Возврат курсора на последнее месте
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Подсветка строки курсора только в нормальном режиме
vim.api.nvim_create_autocmd({ "InsertLeave", "WinEnter" }, {
  callback = function()
    local ok, cl = pcall(vim.api.nvim_win_get_var, 0, "auto-cursorline")
    if ok and cl then
      vim.wo.cursorline = true
      vim.api.nvim_win_del_var(0, "auto-cursorline")
    end
  end,
})
vim.api.nvim_create_autocmd({ "InsertEnter", "WinLeave" }, {
  callback = function()
    local cl = vim.wo.cursorline
    if cl then
      vim.api.nvim_win_set_var(0, "auto-cursorline", cl)
      vim.wo.cursorline = false
    end
  end,
})

-- ======================================================================
-- LunarVim Built-in Modules Configuration
-- ======================================================================

-- Полностью отключаем линии отступов (бывший indent-blankline)
lvim.builtin.indentlines.active = false
-- Если нужна защита от бага с Treesitter-indent, раскомментируй строку ниже
lvim.builtin.treesitter.indent = { enable = false }

-- ======================================================================
-- Plugins
-- ======================================================================

lvim.plugins = {
  { "betkyss/nvim_onedark_theme" },
  { "mattn/emmet-vim" },
  { "powerman/vim-plugin-ruscmd" },
  { "iamcco/markdown-preview.nvim", build = "cd app && yarn install" },
  {
    "kevinhwang91/rnvimr",
    build = "make",
    config = function()
      vim.g.rnvimr_ex_enable = 1
      vim.keymap.set("n", "<Space>r", ":RnvimrToggle<CR>", { silent = true, noremap = true })
    end,
  },
  -- вот наша новая запись:
  {
    "RRethy/vim-illuminate",
    config = function()
      require("illuminate").configure({
        -- оставляем провайдеры LSP + RegEx, убираем treesitter
        providers = { "lsp", "regex" },
      })
    end,
  },
}

-- ======================================================================
-- Keymaps
-- ======================================================================

