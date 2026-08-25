# nvim

Greg's [AstroNvim](https://github.com/AstroNvim/AstroNvim) v6 user config (Debian Plato and macOS).

Do not copy `~/.local/share/nvim` between machines. Lazy and Mason rebuild per OS.

## macOS

```shell
brew install neovim ripgrep fd git
```

If `~/.config/nvim` already exists:

```shell
mv ~/.config/nvim ~/.config/nvim.bak
mv ~/.local/share/nvim ~/.local/share/nvim.bak 2>/dev/null
mv ~/.local/state/nvim ~/.local/state/nvim.bak 2>/dev/null
mv ~/.cache/nvim ~/.cache/nvim.bak 2>/dev/null
```

```shell
git clone git@github.com:gmgauthier/nvim.git ~/.config/nvim
nvim
```

First launch fetches plugins. `:checkhealth` when Lazy is done. C/C++ will Mason-install a darwin `clangd`.

`lua/polish.lua` loads `GITHUB_PERSONAL_ACCESS_TOKEN` from `pass` if that exists; otherwise it is a no-op.
