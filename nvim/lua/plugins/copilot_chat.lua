return {
  -- Copilot Chat (requires copilot.lua from LazyVim extra: lazyvim.plugins.extras.ai.copilot)
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    dependencies = {
      "zbirenbaum/copilot.lua",
      "nvim-lua/plenary.nvim",
    },
    opts = {
      -- You can configure model/window/options here. Minimal setup for now.
      -- Example: model = "gpt-4o",
    },
    config = function(_, opts)
      require("CopilotChat").setup(opts)
    end,
    keys = {
      { "<leader>cc", "<cmd>CopilotChat<cr>", desc = "CopilotChat: Open" },
      { "<leader>cx", "<cmd>CopilotChatClose<cr>", desc = "CopilotChat: Close" },
      {
        "<leader>ce",
        function()
          require("CopilotChat").ask("Explain this code")
        end,
        mode = { "n", "v" },
        desc = "CopilotChat: Explain",
      },
      {
        "<leader>cf",
        function()
          require("CopilotChat").ask("Fix the issue in this code")
        end,
        mode = { "n", "v" },
        desc = "CopilotChat: Fix",
      },
      {
        "<leader>ct",
        function()
          require("CopilotChat").ask("Write unit tests for this code")
        end,
        mode = { "n", "v" },
        desc = "CopilotChat: Tests",
      },
    },
  },
}
