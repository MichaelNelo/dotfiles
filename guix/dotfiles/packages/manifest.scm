(define-module (dotfiles packages manifest)
  #:use-module (gnu packages ssh)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages wget)
  #:use-module (gnu packages curl)
  #:use-module (gnu packages nss)
  #:use-module (gnu packages version-control)
  #:use-module (gnu packages shells)
  #:use-module ((dotfiles packages nushell) #:select (nushell-0.104.0))
  #:use-module (gnu packages emacs)
  #:use-module (gnu packages node)
  #:use-module (gnu packages text-editors)
  #:use-module (gnu packages shellutils)
  #:use-module (gnu packages terminals)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages image-viewers)
  #:use-module (gnu packages rust-apps)
  #:use-module (gnu packages less)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages commencement)
  #:use-module (gnu packages containers)
  #:use-module ((gnu packages dns) #:select (isc-bind))  ;bind:utils for dig/host/nslookup
  #:use-module (dotfiles packages omz)
  #:use-module (dotfiles packages oh-my-posh)
  #:use-module (dotfiles packages fzfcolored)
  #:use-module (dotfiles packages claude-code)
  #:use-module (dotfiles packages jadx)
  #:use-module (dotfiles packages piknik)
  #:use-module (dotfiles packages powerline-kak)
  #:use-module (dotfiles packages onepassword-cli)
  #:use-module (dotfiles packages zellij)
  #:use-module (dotfiles packages yazi)
  #:use-module (dotfiles packages kakoune-lsp)
  #:use-module (dotfiles packages kakoune-tree-sitter-themes)
  #:use-module (dotfiles packages ktsctl)
  #:use-module (dotfiles packages lazygit)
  #:use-module (dotfiles packages scala-cli)
  #:use-module (gnu packages file)                ;file(1) — MIME detection for yazi
  #:use-module ((gnu packages text-editors) #:select (kak-tree-sitter editorconfig-core-c))
  #:use-module (dotfiles packages micro-plugins lsp)
  #:use-module (dotfiles packages micro-plugins autofmt)
  #:use-module (dotfiles packages micro-plugins fzf)
  #:export (%base-packages %dev-packages))

;; Core CLI packages for everyday use
(define %base-packages
  (list less
        ripgrep
        bash                   ;direnv shells out to bash for .envrc
        git
        zsh
        omz
        nushell-0.104.0
        emacs-no-x
        glibc-locales
        glibc                  ;ldd, getconf, getent, iconv, locale
        fzf
        fzf-tab
        micro
        unzip
        direnv
        zoxide
        patchelf
        openssh
        curl
        ncurses ;provides clear, tput, etc.
        node
        podman
        fzfcolored
        micro-plugin-lsp
        micro-plugin-autofmt
        micro-plugin-fzf
        crun
        git-crypt
        `(,isc-bind "utils")   ;dig, host, nslookup — DNS diagnostics
        jadx                   ;dex→java decompiler (Android APKs) — brings openjdk21 too
        piknik                 ;E2E-encrypted clipboard relay
        onepassword-cli        ;`op` — 1Password CLI (nonguix)
        oh-my-posh             ;prompt renderer (sourced from nushell config.nu)
        zellij                 ;terminal multiplexer (plugins wired in home.scm)
        yazi                   ;terminal file manager
        file                   ;used by yazi for file-type detection on open
        kakoune                ;modal text editor
        kakoune-lsp            ;LSP client for kakoune (`kak-lsp`)
        kak-tree-sitter        ;tree-sitter server for kakoune
        ktsctl                 ;companion CLI for kak-tree-sitter
        kakoune-tree-sitter-themes ;ts_* faces for :colorscheme (night-owl et al.)
        powerline-kak          ;powerline modeline plugin for kakoune
        editorconfig-core-c    ;`editorconfig` CLI — consumed by kak's :editorconfig-load
        ;; JDK: no explicit entry — `jadx` propagates openjdk@21.0.2, which is
        ;; enough for Metals/Bloop/scala-cli (they need >=11).  Declaring
        ;; `openjdk` here would install openjdk@25 and conflict with jadx's
        ;; propagated 21.0.2 — Guix refuses two versions of the same package
        ;; in one profile.
        lazygit                ;grs layout `lazygit-follow.sh` needs this on PATH
        scala-cli
        claude-code
        chafa))

;; Additional packages for development/testing environments
(define %dev-packages
  (list bash wget nss-certs libiconv))
