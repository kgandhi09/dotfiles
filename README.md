# dotfiles

My terminal dev setup: **neovim** (vim-plug + coc.nvim) running inside **herdr**.

## New machine

```sh
git clone <this-repo> ~/dotfiles
cd ~/dotfiles
./install.sh
```

Then open a terminal, set its font to **FiraCode Nerd Font**, start `herdr`, and
run this once in a herdr pane to finish the quota sidebar plugin (it needs a
running herdr server):

```sh
~/dotfiles/install.sh --herdr-plugins
```

## What `install.sh` does

1. System packages (apt / dnf / pacman / brew): git, curl, ripgrep, fd, fzf,
   universal-ctags, cscope, clangd, node + npm, xclip / wl-clipboard.
2. neovim — keeps the system one if it's >= 0.10, otherwise installs the latest
   release to `~/.local/opt/nvim`.
3. rust (rustup) — needed to build `herdr-agent-quota`.
4. herdr — via `https://herdr.dev/install.sh`.
5. FiraCode Nerd Font into `~/.local/share/fonts`.
6. Symlinks the configs (existing files are moved to `~/.dotfiles-backup/<timestamp>/`).
7. vim-plug, `:PlugInstall`, and the coc extensions from `nvim/coc-extensions.json`.
8. herdr plugins (`ChmaraX/herdr-nvim`, `levi-qiao/herdr-agent-quota`) and the
   claude / codex integrations if those CLIs are installed.

It's safe to re-run. Flags: `--links-only`, `--no-deps`, `--no-fonts`,
`--herdr-plugins`, `--help`.

## Layout

| Repo path                           | Linked to                              |
| ----------------------------------- | -------------------------------------- |
| `nvim/init.vim`                     | `~/.config/nvim/init.vim`              |
| `nvim/coc-settings.json`            | `~/.config/nvim/coc-settings.json`     |
| `nvim/cscope.vim`                   | `~/.config/nvim/cscope.vim`            |
| `nvim/coc-extensions.json`          | copied to `~/.config/coc/extensions/package.json` |
| `herdr/config.toml`                 | `~/.config/herdr/config.toml`          |
| `herdr/plugin-config/herdr-agent-quota/` | copied to the plugin's config dir |
| `bin/herdr-usage-watch`             | `~/.local/bin/herdr-usage-watch`       |

Because the configs are symlinks, edits on any machine land in this repo —
just commit and push.

## Machine-specific bits

`nvim/coc-settings.json` points clangd at an ARM toolchain
(`/opt/arm-gnu-toolchain-15.2.rel1-x86_64-arm-none-eabi`) and flutter at
`/usr/local/flutter/`. Those aren't installed by the script.
