;; kak-tree-sitter runtime grammars.
;;
;; Guix already packages the tree-sitter grammar shared objects
;; (@file{$out/lib/tree-sitter/libtree-sitter-<lang>.so}) but kak-tree-sitter
;; expects a different layout:
;;
;;   $XDG_DATA_HOME/kak-tree-sitter/runtime/
;;     ├── grammars/<lang>.so                 ; note: NO libtree-sitter- prefix
;;     └── queries/<lang>/{highlights,injections,textobjects}.scm
;;
;; This module provides:
;;
;;   - kak-tree-sitter-runtime-grammar : (helper) builds a runtime layout
;;     package from an existing Guix tree-sitter-<lang> package + its source.
;;
;;   - Concrete runtime packages for javascript, typescript, tsx, rust,
;;     markdown, markdown-inline, scheme.  The dotfiles home service
;;     (`services/kak-tree-sitter.scm`) unions their share/ trees into
;;     ~/.local/share/kak-tree-sitter/runtime/.
;;
;; About "guix" language: Guix files are Scheme, so we ship tree-sitter-scheme
;; and let it match kakoune's default `scheme` filetype.  If you later want a
;; distinct `guix` filetype in kakoune, add a second runtime package here
;; that mirrors the scheme .so under the name `guix.so` + queries dir.

(define-module (dotfiles packages kak-tree-sitter-grammars)
  #:use-module (guix packages)
  #:use-module (guix build-system trivial)
  #:use-module (guix gexp)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages tree-sitter)
  #:use-module (dotfiles packages tree-sitter-hocon)
  #:use-module (dotfiles packages tree-sitter-nu)
  #:use-module (dotfiles packages tree-sitter-editorconfig)
  #:export (kak-tree-sitter-runtime-grammar
            kak-tree-sitter-runtime-javascript
            kak-tree-sitter-runtime-typescript
            kak-tree-sitter-runtime-tsx
            kak-tree-sitter-runtime-rust
            kak-tree-sitter-runtime-markdown
            kak-tree-sitter-runtime-markdown-inline
            kak-tree-sitter-runtime-scheme
            kak-tree-sitter-runtime-scala
            kak-tree-sitter-runtime-yaml
            kak-tree-sitter-runtime-json
            kak-tree-sitter-runtime-toml
            kak-tree-sitter-runtime-nix
            kak-tree-sitter-runtime-hcl
            kak-tree-sitter-runtime-jsonnet
            kak-tree-sitter-runtime-kdl
            kak-tree-sitter-runtime-ini
            kak-tree-sitter-runtime-ninja
            kak-tree-sitter-runtime-xml
            kak-tree-sitter-runtime-dtd
            kak-tree-sitter-runtime-hocon
            kak-tree-sitter-runtime-sh
            kak-tree-sitter-runtime-python
            kak-tree-sitter-runtime-go
            kak-tree-sitter-runtime-c
            kak-tree-sitter-runtime-cpp
            kak-tree-sitter-runtime-lua
            kak-tree-sitter-runtime-nu
            kak-tree-sitter-runtime-editorconfig
            %kak-tree-sitter-runtime-grammars))

(define* (kak-tree-sitter-runtime-grammar
          grammar
          #:key
          ;; The `<lang>` the .so + queries dir should end up named as.
          ;; Defaults to `tree-sitter-<lang>` package name suffix; override
          ;; when the upstream grammar name differs from kakoune's filetype
          ;; (e.g. tsx → tsx, markdown-inline → markdown_inline).
          (lang #f)
          ;; Where inside the grammar source repo queries live.  Most repos
          ;; use `queries/`.  Multi-grammar repos (markdown, typescript) use
          ;; `<sub>/queries/`.
          (queries-subdir "queries")
          ;; Where inside the grammar output the .so lives.  Guix
          ;; tree-sitter-build-system always installs to lib/tree-sitter/.
          (grammar-so-name #f))
  "Return a package that assembles a kak-tree-sitter runtime layout
(@file{share/kak-tree-sitter/runtime/{grammars,queries}/<lang>/}) from
GRAMMAR (an existing Guix tree-sitter-<lang> package)."
  (let* ((upstream-name (package-name grammar))
         (lang* (or lang
                    (if (string-prefix? "tree-sitter-" upstream-name)
                        (substring upstream-name (string-length "tree-sitter-"))
                        upstream-name)))
         (so-name (or grammar-so-name
                      (string-append "libtree-sitter-" lang* ".so"))))
    (package
      (name (string-append "kak-tree-sitter-runtime-" lang*))
      (version (package-version grammar))
      (source (package-source grammar))
      (build-system trivial-build-system)
      (native-inputs `(("grammar" ,grammar)))
      (arguments
       (list
        #:modules '((guix build utils))
        #:builder
        #~(begin
            (use-modules (guix build utils))
            (let* ((out (assoc-ref %outputs "out"))
                   (runtime (string-append out "/share/kak-tree-sitter/runtime"))
                   (gdir (string-append runtime "/grammars"))
                   (qdir (string-append runtime "/queries/" #$lang*))
                   (grammar-src (assoc-ref %build-inputs "source"))
                   (grammar-so
                    (string-append (assoc-ref %build-inputs "grammar")
                                   "/lib/tree-sitter/" #$so-name))
                   (queries-src
                    (string-append grammar-src "/" #$queries-subdir)))
              (mkdir-p gdir)
              (copy-file grammar-so
                         (string-append gdir "/" #$lang* ".so"))
              (mkdir-p qdir)
              (when (file-exists? queries-src)
                (copy-recursively queries-src qdir))))))
      (home-page (package-home-page grammar))
      (synopsis
       (string-append "kak-tree-sitter runtime layout for the `" lang*
                      "` grammar"))
      (description
       (string-append "This package repackages the Guix @code{"
                      upstream-name
                      "} grammar (and its query files) under the file layout
expected by @code{kak-tree-sitter}: shared object as
@file{grammars/" lang* ".so} and queries under @file{queries/" lang* "/}."))
      (license (package-license grammar)))))

;; ---------------------------------------------------------------------------
;; Concrete runtime packages
;; ---------------------------------------------------------------------------

(define-public kak-tree-sitter-runtime-javascript
  (kak-tree-sitter-runtime-grammar tree-sitter-javascript))

(define-public kak-tree-sitter-runtime-typescript
  ;; tree-sitter-typescript repo has two grammars under sub-dirs
  ;; (typescript/ and tsx/); each has its own queries/ dir.  Guix installs
  ;; both .so's to lib/tree-sitter/.  We select `typescript` here.
  (kak-tree-sitter-runtime-grammar
   tree-sitter-typescript
   #:lang "typescript"
   #:queries-subdir "typescript/queries"
   #:grammar-so-name "libtree-sitter-typescript.so"))

(define-public kak-tree-sitter-runtime-tsx
  (kak-tree-sitter-runtime-grammar
   tree-sitter-typescript
   #:lang "tsx"
   #:queries-subdir "tsx/queries"
   #:grammar-so-name "libtree-sitter-tsx.so"))

(define-public kak-tree-sitter-runtime-rust
  (kak-tree-sitter-runtime-grammar tree-sitter-rust))

(define-public kak-tree-sitter-runtime-markdown
  ;; tree-sitter-markdown repo hosts markdown + markdown-inline.  Guix builds
  ;; both.  Queries are under `tree-sitter-markdown/queries/`.
  (kak-tree-sitter-runtime-grammar
   tree-sitter-markdown
   #:lang "markdown"
   #:queries-subdir "tree-sitter-markdown/queries"
   #:grammar-so-name "libtree-sitter-markdown.so"))

(define-public kak-tree-sitter-runtime-markdown-inline
  (kak-tree-sitter-runtime-grammar
   tree-sitter-markdown
   #:lang "markdown_inline"
   #:queries-subdir "tree-sitter-markdown-inline/queries"
   #:grammar-so-name "libtree-sitter-markdown_inline.so"))

(define-public kak-tree-sitter-runtime-scheme
  ;; Covers Guix .scm files: they're Scheme, kakoune detects them as
  ;; `scheme` filetype by default.
  (kak-tree-sitter-runtime-grammar tree-sitter-scheme))

(define-public kak-tree-sitter-runtime-scala
  (kak-tree-sitter-runtime-grammar tree-sitter-scala))

;; --- Configuration languages ---

(define-public kak-tree-sitter-runtime-yaml
  (kak-tree-sitter-runtime-grammar tree-sitter-yaml))

(define-public kak-tree-sitter-runtime-json
  (kak-tree-sitter-runtime-grammar tree-sitter-json))

(define-public kak-tree-sitter-runtime-toml
  (kak-tree-sitter-runtime-grammar tree-sitter-toml))

(define-public kak-tree-sitter-runtime-nix
  (kak-tree-sitter-runtime-grammar tree-sitter-nix))

(define-public kak-tree-sitter-runtime-hcl
  ;; Covers HCL and Terraform (.tf) files — kakoune detects `.tf` as `hcl`.
  (kak-tree-sitter-runtime-grammar tree-sitter-hcl))

(define-public kak-tree-sitter-runtime-jsonnet
  (kak-tree-sitter-runtime-grammar tree-sitter-jsonnet))

(define-public kak-tree-sitter-runtime-kdl
  (kak-tree-sitter-runtime-grammar tree-sitter-kdl))

(define-public kak-tree-sitter-runtime-ini
  (kak-tree-sitter-runtime-grammar tree-sitter-ini))

(define-public kak-tree-sitter-runtime-ninja
  (kak-tree-sitter-runtime-grammar tree-sitter-ninja))

(define-public kak-tree-sitter-runtime-xml
  ;; tree-sitter-xml repo hosts two grammars under sub-dirs (xml/ and dtd/);
  ;; Guix builds both into lib/tree-sitter/.
  (kak-tree-sitter-runtime-grammar
   tree-sitter-xml
   #:lang "xml"
   #:queries-subdir "xml/queries"
   #:grammar-so-name "libtree-sitter-xml.so"))

(define-public kak-tree-sitter-runtime-dtd
  (kak-tree-sitter-runtime-grammar
   tree-sitter-xml
   #:lang "dtd"
   #:queries-subdir "dtd/queries"
   #:grammar-so-name "libtree-sitter-dtd.so"))

(define-public kak-tree-sitter-runtime-hocon
  ;; HOCON — Guix has no upstream package, we ship one under
  ;; (dotfiles packages tree-sitter-hocon).
  (kak-tree-sitter-runtime-grammar tree-sitter-hocon))

;; --- Shell / general-purpose ---

(define-public kak-tree-sitter-runtime-sh
  ;; tree-sitter-bash but installed as `sh` — kakoune's built-in filetype
  ;; detector sets `sh` for .sh/.bash/.zsh/.envrc (with an added hook), so
  ;; kak-tree-sitter resolves the language name to `sh` directly.
  (kak-tree-sitter-runtime-grammar
   tree-sitter-bash
   #:lang "sh"
   #:grammar-so-name "libtree-sitter-bash.so"))

(define-public kak-tree-sitter-runtime-python
  (kak-tree-sitter-runtime-grammar tree-sitter-python))

(define-public kak-tree-sitter-runtime-go
  (kak-tree-sitter-runtime-grammar tree-sitter-go))

(define-public kak-tree-sitter-runtime-c
  (kak-tree-sitter-runtime-grammar tree-sitter-c))

(define-public kak-tree-sitter-runtime-cpp
  (kak-tree-sitter-runtime-grammar tree-sitter-cpp))

(define-public kak-tree-sitter-runtime-lua
  (kak-tree-sitter-runtime-grammar tree-sitter-lua))

(define-public kak-tree-sitter-runtime-nu
  ;; Nushell — Guix has no upstream package, we ship one under
  ;; (dotfiles packages tree-sitter-nu).  Kakoune has no built-in filetype
  ;; for .nu; a hook in kakrc sets `filetype=nu` on BufCreate.
  (kak-tree-sitter-runtime-grammar tree-sitter-nu))

(define-public kak-tree-sitter-runtime-editorconfig
  ;; .editorconfig files.  Kakoune's built-in editorconfig.kak sets
  ;; filetype=ini for .editorconfig; a hook in kakrc overrides that to
  ;; `editorconfig` so this dedicated grammar engages.
  ;;
  ;; Upstream ships queries under `queries/editorconfig/` (nested by lang
  ;; name), not the more common `queries/` — point queries-subdir at the
  ;; inner directory so kak-tree-sitter finds highlights.scm directly.
  (kak-tree-sitter-runtime-grammar
   tree-sitter-editorconfig
   #:queries-subdir "queries/editorconfig"))

(define %kak-tree-sitter-runtime-grammars
  ;; Convenience aggregate — reference this from a home service to link
  ;; every grammar's runtime tree into ~/.local/share/kak-tree-sitter/runtime/.
  (list kak-tree-sitter-runtime-javascript
        kak-tree-sitter-runtime-typescript
        kak-tree-sitter-runtime-tsx
        kak-tree-sitter-runtime-rust
        kak-tree-sitter-runtime-markdown
        kak-tree-sitter-runtime-markdown-inline
        kak-tree-sitter-runtime-scheme
        kak-tree-sitter-runtime-scala
        ;; Config languages
        kak-tree-sitter-runtime-yaml
        kak-tree-sitter-runtime-json
        kak-tree-sitter-runtime-toml
        kak-tree-sitter-runtime-nix
        kak-tree-sitter-runtime-hcl
        kak-tree-sitter-runtime-jsonnet
        kak-tree-sitter-runtime-kdl
        kak-tree-sitter-runtime-ini
        kak-tree-sitter-runtime-ninja
        kak-tree-sitter-runtime-xml
        kak-tree-sitter-runtime-dtd
        kak-tree-sitter-runtime-hocon
        ;; Shell / general-purpose
        kak-tree-sitter-runtime-sh
        kak-tree-sitter-runtime-python
        kak-tree-sitter-runtime-go
        kak-tree-sitter-runtime-c
        kak-tree-sitter-runtime-cpp
        kak-tree-sitter-runtime-lua
        kak-tree-sitter-runtime-nu
        kak-tree-sitter-runtime-editorconfig))
