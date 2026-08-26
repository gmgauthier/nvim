-- Load secrets from pass when not already in the environment
-- (covers GUI launches / non-interactive shells without .dev sourced).

local function pass_show(entry)
  if vim.fn.executable "pass" ~= 1 then return nil end
  local out = vim.fn.system({ "pass", "show", entry })
  if vim.v.shell_error ~= 0 then return nil end
  local line = vim.split(out, "\n", { plain = true })[1]
  if not line or line == "" then return nil end
  return line
end

local function ensure_env(var, entry)
  local cur = vim.env[var]
  if cur and cur ~= "" then return end
  local val = pass_show(entry)
  if val then vim.env[var] = val end
end

ensure_env("GITHUB_PERSONAL_ACCESS_TOKEN", "github/pat")

-- The `:Lsp*` commands, which AstroNvim v5 on Neovim 0.11+ does not have.
--
-- nvim-lspconfig defines `:LspRestart`, `:LspStart`, `:LspStop`, `:LspInfo` and
-- `:LspLog` in its `plugin/` directory. AstroNvim starts language servers with
-- Neovim's native `vim.lsp.enable()` and uses nvim-lspconfig only as a *library* of
-- server configs (the `lsp/*.lua` files on the runtimepath) -- so the plugin is never
-- loaded, `plugin/lspconfig.lua` never runs, and none of those commands exist.
--
-- Measured: a Python buffer with basedpyright attached (`#vim.lsp.get_clients() == 1`)
-- while `vim.fn.exists ":LspRestart"` returns 0 and `package.loaded.lspconfig` is nil.
-- Not a broken plugin and not a missing dependency: the commands simply live in code
-- that is deliberately not loaded.

local function client_names(bufnr)
  local names, seen = {}, {}
  for _, client in ipairs(vim.lsp.get_clients { bufnr = bufnr }) do
    if not seen[client.name] then
      seen[client.name], names[#names + 1] = true, client.name
    end
  end
  return names
end

--- Is this client one `vim.lsp.enable` actually manages?
---
--- none-ls registers `null-ls` as an LSP client without going through
--- `vim.lsp.config`, so disabling and re-enabling that name does nothing at all --
--- measured: `:LspRestart` on a buffer whose only client was `null-ls` stopped it and
--- left it stopped. Servers its own plugin owns are left to it.
local function managed(name) return (vim.lsp.config._configs or {})[name] ~= nil end

--- Stop every client for `names`, having first disabled them so nothing restarts one
--- underneath us.
local function stop(names, force)
  for _, name in ipairs(names) do
    vim.lsp.enable(name, false)
    for _, client in ipairs(vim.lsp.get_clients { name = name }) do
      client:stop(force)
    end
  end
end

--- Which loaded buffers currently have `name` attached.
local function buffers_with(name)
  local bufs = {}
  for _, client in ipairs(vim.lsp.get_clients { name = name }) do
    for buf, _ in pairs(client.attached_buffers or {}) do
      if vim.api.nvim_buf_is_loaded(buf) then bufs[#bufs + 1] = buf end
    end
  end
  return bufs
end

--- Attach `name` to buffers that are already loaded.
---
--- **This is the part `vim.lsp.enable` does not do**, and leaving it out is why a naive
--- restart stops a server and never brings it back. Measured on Neovim 0.12.5:
--- enabling *before* opening a file attaches, while enabling with the buffer already
--- loaded does not, because attachment is driven by `FileType`.
---
--- The obvious fix -- re-firing `FileType` on every buffer -- is too blunt. Measured:
--- restarting basedpyright that way also started `pyrefly`, `ruff` and `ty`, none of
--- which had been running. So this starts the one config for the one set of buffers
--- instead of asking the whole filetype to reconsider.
local function attach_to(name, bufs)
  local config = vim.lsp.config[name]
  if not config then return end
  for _, buf in ipairs(bufs) do
    if vim.api.nvim_buf_is_loaded(buf) then vim.lsp.start(config, { bufnr = buf }) end
  end
end

vim.api.nvim_create_user_command("LspRestart", function(info)
  local requested = #info.fargs > 0 and info.fargs or client_names(0)
  local names, skipped = {}, {}
  for _, name in ipairs(requested) do
    if managed(name) then
      names[#names + 1] = name
    else
      skipped[#skipped + 1] = name
    end
  end
  if #skipped > 0 then
    vim.notify(
      ("not restartable here (owned by their own plugin, not vim.lsp.enable): %s")
        :format(table.concat(skipped, ", ")),
      vim.log.levels.WARN
    )
  end
  if #names == 0 then
    vim.notify("no restartable language server attached to this buffer", vim.log.levels.WARN)
    return
  end
  -- Record where each server was attached *before* stopping it, so it can be put
  -- back exactly there.
  local was_attached = {}
  for _, name in ipairs(names) do
    was_attached[name] = buffers_with(name)
  end
  stop(names, info.bang)
  -- Re-enable only once the clients have actually exited: enabling while one is still
  -- shutting down leaves it disabled with nothing attached.
  vim.defer_fn(function()
    for _, name in ipairs(names) do
      vim.lsp.enable(name)
      attach_to(name, was_attached[name])
    end
    vim.notify("LSP restarted: " .. table.concat(names, ", "))
  end, 500)
end, {
  desc = "Restart the language servers attached to this buffer",
  nargs = "*",
  bang = true,
  complete = function(arg)
    return vim.tbl_filter(function(n) return n:sub(1, #arg) == arg end, client_names(nil))
  end,
})

vim.api.nvim_create_user_command("LspStop", function(info)
  local names = #info.fargs > 0 and info.fargs or client_names(0)
  stop(names, info.bang)
  vim.notify("LSP stopped: " .. table.concat(names, ", "))
end, { desc = "Stop the language servers attached to this buffer", nargs = "*", bang = true })

vim.api.nvim_create_user_command("LspStart", function(info)
  local names = info.fargs
  if #names == 0 then
    -- Everything configured for this filetype, which is what `vim.lsp.enable` wants.
    for name, _ in pairs(vim.lsp.config._configs or {}) do
      local filetypes = (vim.lsp.config[name] or {}).filetypes
      if filetypes and vim.tbl_contains(filetypes, vim.bo.filetype) then names[#names + 1] = name end
    end
  end
  if #names == 0 then
    vim.notify("no language server configured for this filetype", vim.log.levels.WARN)
    return
  end
  for _, name in ipairs(names) do
    vim.lsp.enable(name)
    attach_to(name, { 0 })
  end
  vim.notify("LSP started: " .. table.concat(names, ", "))
end, { desc = "Enable and launch a language server", nargs = "*" })

vim.api.nvim_create_user_command("LspInfo", "checkhealth vim.lsp", {
  desc = "Alias to :checkhealth vim.lsp, which is where LSP status lives on 0.11+",
})

vim.api.nvim_create_user_command("LspLog", function()
  vim.cmd("tabnew " .. vim.lsp.log.get_filename())
end, { desc = "Open the Neovim LSP client log" })
