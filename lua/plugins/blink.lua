-- blink.cmp only downloads its Rust fuzzy .so when the plugin is on a git *tag*.
-- Lazy's plugin dirs here have no .git (pkg cache), so git describe never finds
-- a tag and `prefer_rust*` still emits the "Press ENTER" error. Lua skips that.
return {
  "saghen/blink.cmp",
  opts = {
    fuzzy = {
      implementation = "lua",
    },
  },
}
