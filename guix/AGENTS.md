# Guix Home Configuration

Configuración declarativa del entorno de usuario con Guix Home. Maneja
paquetes, servicios (shepherd, ssh, ollama, zsh) y el linkeo declarativo de
los dotfiles del repo en `~/.config/`.

## Estructura

```
guix/
├── home.scm                     # Config principal
├── channels.scm                 # Canales adicionales
├── packages/                    # Paquetes custom (no en upstream Guix)
│   ├── claude-code.scm
│   ├── doom.scm                 # Reservado para futuro re-uso, NO importado
│   ├── lazygit.scm
│   ├── llama-cpp.scm
│   ├── mise.scm
│   ├── nvchad.scm
│   ├── nvr.scm                  # neovim-remote (Python pkg via setup.py)
│   ├── ollama.scm
│   ├── omz.scm
│   ├── opencode.scm
│   ├── yazi.scm                 # binary release musl x86_64
│   └── zellij.scm
└── services/
    └── ollama.scm               # Shepherd: ollama serve
```

## Paquetes en `main-packages` (home.scm)

Terminal: `less`, `file`, `xdg-utils`, `ripgrep`, `micro`.
AI tools: `claude-code`, `opencode`, `ollama`, `llama-cpp-4f13cb`.
Editor/Shell: `omz`, `nvchad`, `neovim`, `lsof`.
Compression: `unzip`, `zstd`.
Build: `gnu-make`, `libtool`, `cmake`, `gcc-toolchain`, `llvm`, `glibc`,
`patchelf`, `pkg-config`, `glibc-locales`.
Networking: `curl`, `openssh`, `dropbear`.
Dev: `git`, `mise`, `node`, `lazygit`, `zellij`, `nvr`, `yazi`, `direnv`,
`zoxide`, `fzf`, `fzf-tab`, `sqlite`, `man-db`, `octave-cli`, `tree-sitter`,
`tree-sitter-cli`.

## Servicios en home.scm

- `home-dotfiles-service-type` → symlinkea `../../dotfiles` a `~/.config/`.
  Los symlinks apuntan al store (read-only), por eso para apps que escriben
  su config en runtime usamos env vars (ver abajo).
- `gcc-to-cc-symlink` (`home-activation`) → crea `~/.local/bin/cc → gcc`.
- `ollama-server` (Shepherd) → `ollama serve` con `LD_LIBRARY_PATH` para CUDA
  via WSL.
- `ssh-host-keys-setup` + `ssh-client-keys-setup` (`home-activation`) →
  genera llaves dropbear si no existen, agrega la pubkey a authorized_keys
  con un wrapper que setea PATH a `~/.guix-home/profile/bin` para que
  comandos remotos resuelvan a binarios de Guix.
- `dopbear-ssh-server` (Shepherd) → Dropbear en `:2222` usando el wrapper.
- `home-openssh-service-type` → hosts `me.github.com` y `flush.github.com`.
- `home-zsh-service-type` → snippets condicionales (zoxide, direnv,
  npm-prefix) y env vars (ver abajo).

## Env vars críticos (home-zsh-service-type)

```
ZSH=$omz/share/oh-my-zsh
SHELL=$zsh/bin/zsh
GUIX_LOCPATH=$HOME/.guix-home/profile/lib/locale
CC=$gcc-toolchain/bin/gcc
GIT_SSL_CAPATH=/etc/ssl/certs
EDITOR=nvim
OPENCODE_ENABLE_EXA=1
SSL_CERT_DIR=/etc/ssl/certs
LD_LIBRARY_PATH=/usr/lib/wsl/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
ZELLIJ_CONFIG_DIR=$HOME/dotfiles/.config/zellij   # writable working tree
YAZI_CONFIG_HOME=$HOME/dotfiles/.config/yazi      # writable working tree
PATH=$HOME/.local/bin:$HOME/.npm-global/bin:$PATH
```

`ZELLIJ_CONFIG_DIR` y `YAZI_CONFIG_HOME` apuntan al working tree de
dotfiles, no al `~/.config/` symlinkeado al store. Eso permite que zellij
(Unlock First wizard) y yazi (flavors, cache) escriban estado sin chocar con
los symlinks read-only.

## Canales adicionales

- `rustup` — https://github.com/declantsien/guix-rustup.git
- `guix-science-nonfree` — https://codeberg.org/guix-science/guix-science-nonfree
  (para `cuda-toolkit` y derivados)

## Dotfiles que dependen de este setup

- `~/dotfiles/.config/zellij/` — layout `grs` (yazi-current + yazi-preview +
  lazygit-follow + nvim-listen + yazi-neotree) usa los scripts en
  `scripts/grs-env.sh`, `yazi-{current,preview,neotree,float,ask}.sh`,
  `lazygit-follow.sh`, `nvim-listen.sh`.
- `~/dotfiles/.config/yazi/{current,preview,neotree}/` — config dirs
  role-specific. `yazi.toml` define `[mgr] ratio` y opener; `init.lua`
  hace pub/sub vía DDS (`grs-{hover,cd,reveal}-from-1001`).
- `~/dotfiles/.config/nvim/` — NvChad v2.5; nvim-tree desactivado (el
  sidebar lo provee yazi-neotree).

## Reconfigurar

```
guix home reconfigure ~/dotfiles/guix/home.scm
```
