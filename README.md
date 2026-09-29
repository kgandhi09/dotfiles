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

## jk_os with KDE Plasma

On the **booted, installed OS**, copy or clone this repository into your home
directory, then run as your desktop user:

```sh
cd ~/dotfiles
sh ./bootstrap-jk-os.sh
konsole --profile Dotfiles
```

Use `sh` for the first run: jk_os ships BusyBox ash, and the original installer
requires Bash. The bootstrap installs Bash and the other missing dependencies
using [micromamba](https://mamba.readthedocs.io/en/latest/installation/micromamba-installation.html)
and conda-forge, in `~/.local/share/dotfiles/env`. It uses the OS's C/C++
toolchain, Git/curl and glibc; no distro package manager or systemd is needed.
Both x86_64 and aarch64 are supported by the bootstrap. Internet access with a
working CA certificate store and writable home directory are required. Allow
disk space for the package cache, environment, Rust toolchain and plugin builds.
Live-session installs disappear on reboot unless your home is persistent.

The package list is in `packages/jk-os.txt`. Wayland clipboard utilities and
cscope are built locally; Neovim, Rust, herdr, Claude and plugins use the normal
installer. The bootstrap only works on the running system; it does not read or
modify the OS source repository, staged rootfs, build scripts or ISO images.

The **Dotfiles** Konsole profile launches the private zsh and selects FiraCode
Nerd Font Mono on a black background (Breeze colors, `Dotfiles.colorscheme`). You can make it the default in Konsole's profile settings, or
launch the shell directly with `~/.local/bin/dotfiles-shell`. No `sudo`,
`/etc/shells` edit or login-shell change is needed. Existing Konsole profiles
are preserved; rerunning regenerates only `Dotfiles.profile` and
`Dotfiles.colorscheme`.

Text-console logins get the same shell: the bootstrap adds a marked block to
`~/.profile` that starts `dotfiles-shell` when you log in interactively on
tty1, tty2 or a serial console (scripts and the desktop session keep plain
`sh`). On the Linux text console the shell loads the same Breeze colors on
black, and the prompt switches to plain ASCII because the console's bitmap
font has no Nerd Font icons. On a serial line the terminal on the other end
draws the text, so the full prompt is kept; the shell upgrades getty's
`vt100` to `xterm-256color` and asks the terminal for its size at login (run
`exec ~/.local/bin/dotfiles-shell` after resizing that window).

If a new terminal shows the old plain prompt, launch
`~/.local/bin/dotfiles-shell` or select the **Dotfiles** Konsole profile: the
bootstrap leaves your default login shell unchanged. To repair a missing or
half-installed oh-my-zsh or Powerlevel10k theme, or the shell config links,
without reinstalling other tools:

```sh
sh ~/dotfiles/bootstrap-jk-os.sh --zsh-only
exec ~/.local/bin/dotfiles-shell
```

After starting `herdr`, finish the quota plugin in one of its panes:

```sh
sh ~/dotfiles/bootstrap-jk-os.sh --herdr-plugins
```

`--links-only` relinks configs without downloads (after the first bootstrap).
`--no-deps` reuses an existing private environment; `--no-fonts` skips the font.
The `fcc` and `fpc` shortcuts use `wl-copy` in Wayland and `xclip` in X11;
Neovim detects the same clipboard tools automatically. The sshinfo plugin is
enabled only when `ssh`, `dig`, and `nc` are available; jk_os does not ship `dig`.

## What `install.sh` does

1. System packages (apt / dnf / pacman / brew): zsh, git, curl, ripgrep, fd, fzf,
   bat, universal-ctags, cscope, clangd, node + npm, python3 + pynvim, cmake,
   ninja, pre-commit, xclip / wl-clipboard, ssh / dig / nc (for the sshinfo
   plugin), xdg-utils (for web-search).
2. oh-my-zsh, powerlevel10k, and the fzf-tab / autosuggestions /
   syntax-highlighting / sshinfo plugins; sets zsh as your login shell.
3. neovim — keeps the system one if it's >= 0.10, otherwise installs the latest
   release to `~/.local/opt/nvim`.
4. rust (rustup) — needed to build `herdr-agent-quota`.
5. herdr — via `https://herdr.dev/install.sh`.
6. Claude Code CLI — via `https://claude.ai/install.sh` (run `claude` once to log in).
7. FiraCode Nerd Font into `~/.local/share/fonts`.
8. Symlinks the configs (existing files are moved to `~/.dotfiles-backup/<timestamp>/`).
9. vim-plug, `:PlugInstall`, and the coc extensions from `nvim/coc-extensions.json`.
10. herdr plugins (`ChmaraX/herdr-nvim`, `levi-qiao/herdr-agent-quota`) and the
   claude / codex integrations if those CLIs are installed.

It's safe to re-run. Flags: `--links-only`, `--no-deps`, `--no-fonts`,
`--no-chsh`, `--herdr-plugins`, `--help`.

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
| `bin/dotfiles-copy`                 | `~/.local/bin/dotfiles-copy`           |

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
