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

The bootstrap uses only what jk_os itself ships: its bash, Python and pip,
GCC, make, autotools, CMake/Ninja, pkg-config, git and curl, and its
libraries' headers. **No apt, no micromamba, no virtual environment.** What
jk_os doesn't have is installed for your user (`scripts/jk-os-deps.sh`):

| Tool | How |
|---|---|
| zsh 5.9.2, universal-ctags 6.2.1, cscope 15.9, wl-clipboard 2.3.0 | built from source into `~/.local/opt/<name>` |
| bat 0.26.1 | built from source with cargo (Rust via rustup, which herdr's plugin needs too) |
| fzf 0.74.4, Node.js 24 LTS | the projects' own Linux release builds (fzf is Go, a single program) |
| pynvim, pre-commit, meson | jk_os's pip, `pip install --user` (into `~/.local`) |
| `xdg-open` | a one-line wrapper around Plasma's `kioclient` |

Each tool's programs are linked into `~/.local/bin`, which `~/.zshenv` puts
first on `PATH`. Every download is checked against a SHA-256 (or, for git, a
commit) pinned in the script; rerunning skips what is already installed at
the pinned version. jk_os already has ripgrep, fd, jq, git, ssh and curl.
Neovim, herdr, Claude and the plugins then come from `install.sh`'s usual
installers. It needs a jk_os image with the build tools and Python (it says
which program is missing otherwise), internet access and some disk space for
the Rust toolchain and the builds. A micromamba environment from an earlier
version of this bootstrap (`~/.local/share/dotfiles`) is removed. The
bootstrap only works on the running system; it does not read or modify the OS
source repository, staged rootfs, build scripts or ISO images.

The **Dotfiles** Konsole profile launches this zsh and selects FiraCode
Nerd Font Mono on a black background (Breeze colors, `Dotfiles.colorscheme`). You can make it the default in Konsole's profile settings, or
launch the shell directly with `~/.local/bin/dotfiles-shell`. No `sudo`,
`/etc/shells` edit or login-shell change is needed. Existing Konsole profiles
are preserved; rerunning regenerates only `Dotfiles.profile` and
`Dotfiles.colorscheme`.

jk-dev's terminal gets the same shell: the bootstrap adds a marked block to
`~/.profile` that starts `dotfiles-shell` in an interactive login shell on a
pseudo-terminal in a graphical session (jk-dev's foot, desktop terminals).
Text consoles (tty1-tty6, serial) and SSH logins keep jk_os's plain shell and
prompt, and scripts and the desktop session keep plain `sh`. You can still run
`~/.local/bin/dotfiles-shell` by hand on a console: it loads the Breeze colors
there and the prompt switches to plain ASCII.

Terminals open with the **J.K. Robotics** banner (`branding/banner`, or jk_os's
own `/usr/share/jk_os/banner` when present), once per window: herdr panes and
subshells inherit `JK_BANNER_SHOWN` and skip it, and so does jk-dev, which
shows the banner itself. `export DOTFILES_NO_BANNER=1` (e.g. in the Konsole
profile's environment) turns it off.

To undo the bootstrap, run `sh ~/dotfiles/uninstall-jk-os.sh`. It removes the
`~/.profile` block, the Dotfiles Konsole profile, `dotfiles-shell` and the
config symlinks, and puts back the files the bootstrap moved aside.
`--purge` also deletes the tools in `~/.local/opt` (and their links), the pip --user packages, oh-my-zsh, the font, Neovim
and its plugins. `~/.zshrc.local` and `~/.dotfiles-backup` are always kept.

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
