(define-module (home)
  #:use-module (gnu home)
  #:use-module (gnu packages)
  #:use-module (guix packages)
  ;; Package modules (consumed by main-packages / dev-packages)
  #:use-module (gnu packages version-control)
  #:use-module (gnu packages ssh)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages wget)
  #:use-module (gnu packages nss)
  #:use-module (gnu packages shells)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages node)
  #:use-module (gnu packages terminals)
  #:use-module (gnu packages text-editors)
  #:use-module (gnu packages shellutils)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages rust-apps)
  #:use-module (gnu packages less)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages commencement)
  #:use-module (gnu packages cmake)
  #:use-module (gnu packages lsof)
  #:use-module (gnu packages curl)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages llvm)
  ;; Local package modules
  #:use-module (packages omz)
  #:use-module (packages opencode)
  #:use-module (packages nvchad)
  #:use-module (packages mise)
  #:use-module (packages llama-cpp)
  #:use-module (packages claude-code)
  #:use-module (packages ollama)
  #:use-module (packages lazygit)
  #:use-module (packages zellij)
  #:use-module (packages nvr)
  #:use-module (packages yazi)
  ;; Local service modules (each owns its own gnu/home/services imports)
  #:use-module (services dotfiles)
  #:use-module (services activation)
  #:use-module (services shepherd)
  #:use-module (services openssh)
  #:use-module (services channels)
  #:use-module (services zsh)
  #:export (my-home))

(define main-packages
  ;; Terminal tools
  (list less
        (specification->package "file")
        xdg-utils
        ripgrep
        ;; Editors
        micro
        ;; AI Tools
        claude-code
        opencode
        ollama
        llama-cpp-4f13cb
        ;; Editor/Shell Tools
        omz
        nvchad
        (specification->package "neovim")
        lsof
        ;; Compression
        unzip
        (specification->package "zstd")
        ;; Build Tools
        gnu-make
        libtool
        cmake
        gcc-toolchain
        llvm
        glibc
        patchelf
        pkg-config
        glibc-locales
        ;; Networking
        curl
        openssh
        dropbear
        ;; Dev Tools
        git
        mise
        node
        lazygit
        zellij
        nvr
        yazi
        direnv
        zoxide
        fzf
        fzf-tab
        (specification->package "socat")
        (specification->package "jq")
        (specification->package "sqlite")
        (specification->package "man-db")
        (specification->package "octave-cli")
        (specification->package "tree-sitter")
        (specification->package "tree-sitter-cli")))

(define dev-packages
  (if (getenv "TEST")
      (list bash wget nss-certs ncurses libiconv)
      '()))

(define my-home
  (home-environment
    (packages (append main-packages dev-packages))
    (services
     (list %dotfiles-service
           %gcc-activation
           %ssh-host-keys-setup
           %ssh-client-keys-setup
           %ollama-service
           %dopbear-ssh-service
           %openssh-service
           %channels-service
           (zsh-service main-packages)))))

my-home
