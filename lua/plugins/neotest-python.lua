-- Prefer the in-project Poetry venv when running pytest via neotest.
return {
  "nvim-neotest/neotest-python",
  opts = {
    runner = "pytest",
    python = function()
      local pyproject = vim.fs.find("pyproject.toml", { upward = true, path = vim.uv.cwd() })[1]
      if pyproject then
        local py = vim.fs.joinpath(vim.fs.dirname(pyproject), ".venv", "bin", "python")
        if vim.uv.fs_stat(py) then return py end
      end
      local py3 = vim.fn.exepath "python3"
      return py3 ~= "" and py3 or "python"
    end,
  },
}