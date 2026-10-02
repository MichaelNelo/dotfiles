;; ktsctl — CLI controller for kak-tree-sitter (grammar fetch/build/install).
;;
;; ktsctl and kak-tree-sitter live in the same Cargo workspace at
;; git.sr.ht/~hadronized/kak-tree-sitter and share Cargo.lock.  Guix already
;; registers that lockfile under 'kak-tree-sitter in (gnu packages rust-crates),
;; so we inherit the source + inputs and only redirect cargo-install-paths at
;; the ktsctl binary.  Bumping upstream: bump kak-tree-sitter in Guix, then
;; version here (or drop this file if ktsctl lands upstream).

(define-module (dotfiles packages ktsctl)
  #:use-module (guix packages)
  #:use-module (gnu packages text-editors)   ;kak-tree-sitter
  #:export (ktsctl))

(define-public ktsctl
  (package
    (inherit kak-tree-sitter)
    (name "ktsctl")
    (arguments
     (list
      #:install-source? #f
      #:cargo-install-paths ''("ktsctl")))
    (synopsis "CLI controller for kak-tree-sitter (fetch/compile/install grammars)")
    (description
     "ktsctl fetches tree-sitter grammar sources declared in
@file{$XDG_CONFIG_HOME/kak-tree-sitter/config.toml}, compiles them, and
installs the resulting shared objects and query files into
@file{$XDG_DATA_HOME/kak-tree-sitter/runtime/}.  Companion tool to the
@code{kak-tree-sitter} server.")))

ktsctl
