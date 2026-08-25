-- Neovim only maps lowercase .bat/.cmd to dosbatch. DOS 8.3 names are uppercase.
---@type LazySpec
return {
  "AstroNvim/astrocore",
  opts = {
    filetypes = {
      extension = {
        BAT = "dosbatch",
        CMD = "dosbatch",
      },
    },
  },
}
