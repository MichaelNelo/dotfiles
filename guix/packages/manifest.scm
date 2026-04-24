(define-module (packages manifest)
  #:use-module (gnu packages ssh)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages wget)
  #:use-module (gnu packages nss)
  #:use-module (gnu packages version-control)
  #:use-module (gnu packages shells)
  #:use-module (gnu packages emacs)
  #:use-module (gnu packages node)
  #:use-module (gnu packages text-editors)
  #:use-module (gnu packages shellutils)
  #:use-module (gnu packages terminals)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages rust-apps)
  #:use-module (gnu packages less)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages containers)
  #:use-module (packages omz)
  #:use-module (packages claude-code)
  #:use-module (packages micro-plugins lsp)
  #:use-module (packages micro-plugins autofmt)
  #:export (%base-packages
            %dev-packages))

;; Core CLI packages for everyday use
(define %base-packages
  (list less
        ripgrep
        git
        zsh
        omz
        emacs-no-x
        glibc-locales
        fzf
        fzf-tab
        micro
        unzip
        direnv
        zoxide
        patchelf
        openssh
        ncurses  ;; provides clear, tput, etc.
        node
        podman
        micro-plugin-lsp
        micro-plugin-autofmt
        crun
        claude-code))

;; Additional packages for development/testing environments
(define %dev-packages
  (list bash
        wget
        nss-certs
        libiconv))
