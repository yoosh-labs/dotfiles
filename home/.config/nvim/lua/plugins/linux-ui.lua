-- linux-patch: statusline and indent guides (added by install.sh)
return {
  {
    'nvim-lualine/lualine.nvim',
    event = 'VeryLazy',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    opts = { options = { theme = 'rose-pine', globalstatus = true } },
  },
  {
    -- snacks.nvim is already installed by navigation.lua; lazy merges these opts
    'folke/snacks.nvim',
    opts = { indent = { enabled = true } },
  },
}
