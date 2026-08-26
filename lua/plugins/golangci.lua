-- golangci-lint v2 errors with "parallel golangci-lint is running" when the
-- langserver and another run (second buffer, gopls-triggered, or DidOpen+change)
-- share the default exclusive lock. Allow parallel runners.
return {
  "AstroNvim/astrolsp",
  optional = true,
  opts = {
    config = {
      golangci_lint_ls = {
        init_options = {
          command = {
            "golangci-lint",
            "run",
            "--output.json.path",
            "stdout",
            "--show-stats=false",
            "--issues-exit-code=1",
            "--allow-parallel-runners",
          },
        },
      },
    },
  },
}