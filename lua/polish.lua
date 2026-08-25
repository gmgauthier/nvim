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
