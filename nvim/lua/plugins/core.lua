return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },
  {
    "christoomey/vim-tmux-navigator",
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
      "TmuxNavigatorProcessList",
    },
    keys = {
      { "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>" },
      { "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>" },
      { "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>" },
      { "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>" },
      { "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>" },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      inlay_hints = { enabled = false },
    },
  },
  -- Shim catppuccin bufferline integration API change (get -> get_bufferline)
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    init = function()
      local ok, cb = pcall(require, "catppuccin.groups.integrations.bufferline")
      if ok and cb and not cb.get and type(cb.get_bufferline) == "function" then
        cb.get = cb.get_bufferline
      end
    end,
  },
  -- Safely configure bufferline highlights with catppuccin, avoiding errors if API changes
  {
    "akinsho/bufferline.nvim",
    optional = true,
    opts = function(_, opts)
      local ok, cb = pcall(require, "catppuccin.groups.integrations.bufferline")
      if ok then
        if type(cb.get) == "function" then
          opts.highlights = cb.get()
        elseif type(cb.get_bufferline) == "function" then
          opts.highlights = cb.get_bufferline()
        end
      end
      return opts
    end,
  },
}
