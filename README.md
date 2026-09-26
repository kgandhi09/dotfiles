# dotfiles

My terminal dev setup: **zsh** (oh-my-zsh + powerlevel10k), **neovim** (vim-plug + coc.nvim), and **herdr**.

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

1. System packages (apt / dnf / pacman / brew): zsh, git, curl, ripgrep, fd, fzf,
   bat, universal-ctags, cscope, clangd, node + npm, xclip / wl-clipboard.
2. oh-my-zsh, powerlevel10k, and the fzf-tab / autosuggestions /
   syntax-highlighting / sshinfo plugins; sets zsh as your login shell.
3. neovim — keeps the system one if it's >= 0.10, otherwise installs the latest
   release to `~/.local/opt/nvim`.
4. rust (rustup) — needed to build `herdr-agent-quota`.
5. herdr — via `https://herdr.dev/install.sh`.
6. FiraCode Nerd Font into `~/.local/share/fonts`.
7. Symlinks the configs (existing files are moved to `~/.dotfiles-backup/<timestamp>/`).
8. vim-plug, `:PlugInstall`, and the coc extensions from `nvim/coc-extensions.json`.
9. herdr plugins (`ChmaraX/herdr-nvim`, `levi-qiao/herdr-agent-quota`) and the
   claude / codex integrations if those CLIs are installed.

It's safe to re-run. Flags: `--links-only`, `--no-deps`, `--no-fonts`,
`--herdr-plugins`, `--help`.

## Layout

| Repo path                           | Linked to                              |
| ----------------------------------- | -------------------------------------- |
| `zsh/zshrc`                         | `~/.zshrc`                             |
| `zsh/zshenv`                        | `~/.zshenv`                            |
| `zsh/p10k.zsh`                      | `~/.p10k.zsh`                          |
| `zsh/zshrc.local.example`           | copied to `~/.zshrc.local` if missing  |
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

**Secrets and per-machine env never go in this repo.** `~/.zshrc` sources
`~/.zshrc.local` (git-ignored, chmod 600) for API keys, toolchain PATHs,
`LD_LIBRARY_PATH`, `PYTHONHOME`, SDK locations, etc. On a new machine it starts
as a copy of `zsh/zshrc.local.example`; copy over the keys you need by hand.


`nvim/coc-settings.json` points clangd at an ARM toolchain
(`/opt/arm-gnu-toolchain-15.2.rel1-x86_64-arm-none-eabi`) and flutter at
`/usr/local/flutter/`. Those aren't installed by the script.
