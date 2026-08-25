# nvim

Greg's [AstroNvim](https://github.com/AstroNvim/AstroNvim) v6 user config. Used on Debian (Plato) and meant to clone onto the work macOS laptop.

Do **not** copy `~/.local/share/nvim`, `~/.local/state/nvim`, or `~/.cache/nvim` between machines. Lazy and Mason rebuild those per OS.

## macOS: make the clone work

### 1. Tools

Homebrew is already on the work laptop. Install Neovim and the two binaries AstroNvim expects on `$PATH`:

```bash
brew install neovim ripgrep fd git
```

You need **Neovim 0.11+** (AstroNvim v6 dropped 0.10). Plato runs **0.12.4**; prefer 0.12 if Homebrew has it. Confirm with `nvim --version`. If you still have 0.10: `brew upgrade neovim`.

Xcode Command Line Tools should already be present (clang/Go/Python stack). If treesitter or Mason fails to compile something later:

```bash
xcode-select --install
```

### 2. GitHub access

The repo is **private**: `git@github.com:gmgauthier/nvim.git`

If this Mac cannot `ssh -T git@github.com` yet, add a key:

```bash
ssh-keygen -t ed25519 -C "work-mac"
# add ~/.ssh/id_ed25519.pub to GitHub → Settings → SSH keys
ssh -T git@github.com
```

HTTPS + `gh auth login` also works.

### 3. Back up any existing Neovim dirs

```bash
mv ~/.config/nvim ~/.config/nvim.bak 2>/dev/null
mv ~/.local/share/nvim ~/.local/share/nvim.bak 2>/dev/null
mv ~/.local/state/nvim ~/.local/state/nvim.bak 2>/dev/null
mv ~/.cache/nvim ~/.cache/nvim.bak 2>/dev/null
```

### 4. Clone

```bash
git clone git@github.com:gmgauthier/nvim.git ~/.config/nvim
```

### 5. First launch

```bash
nvim
```

Lazy will fetch plugins. Wait until that finishes (status line / `:Lazy`). Then:

```
:checkhealth
```

The C/C++ pack will Mason-install a **darwin** `clangd`. That is expected even though system `clang` is already there. Python/Go/Lua LSPs similarly.

Clipboard uses `pbcopy` / `pbpaste` (built in). No `xclip`.

### 6. Optional

`lua/polish.lua` loads `GITHUB_PERSONAL_ACCESS_TOKEN` from `pass show github/pat` if `pass` is installed. On a machine without `pass`, that is a no-op.

Kitty is not required. iTerm2 or Terminal.app are fine if the terminal has truecolor.

### If something is wrong

- Plugins missing: `:Lazy sync`
- Mason tools missing: `:Mason` and install, or reopen a file of that language
- `clangd` not found: `:LspInfo` and wait for Mason, or `:MasonInstall clangd`
- Stuck on an old config: you cloned over `~/.config/nvim.bak`; this repo is the source of truth
