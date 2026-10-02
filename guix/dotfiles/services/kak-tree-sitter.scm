;; kak-tree-sitter home service.
;;
;; Wires kak-tree-sitter into the user profile:
;;
;;   1. Every runtime-grammar package's `.so` is symlinked to
;;      `~/.local/share/kak-tree-sitter/runtime/grammars/<lang>.so`.
;;
;;   2. Every runtime-grammar's `queries/<lang>/` directory is symlinked to
;;      `~/.local/share/kak-tree-sitter/runtime/queries/<lang>/`.
;;
;;   3. A minimal `~/.config/kak-tree-sitter/config.toml` is written enabling
;;      highlighting + text_objects.  ktsctl-driven per-language sources are
;;      not declared here — Guix packages provide the grammars, kak-tree-sitter
;;      just consumes the runtime tree.  So `ktsctl sync` is a no-op path
;;      (the packages already provide everything).
;;
;; Not wired here (belongs to kakrc): the `eval %sh{ kak-tree-sitter -dks
;; --init $kak_session }` snippet that boots the daemon and connects the
;; running kak session.

(define-module (dotfiles services kak-tree-sitter)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (gnu services)
  #:use-module (gnu home services)
  #:use-module (dotfiles packages kak-tree-sitter-grammars)
  #:use-module (dotfiles packages kakoune-tree-sitter-themes)
  #:export (kak-tree-sitter-service
            %kak-tree-sitter-config-toml
            %kak-tree-sitter-colorscheme-files))

;; Trim the "kak-tree-sitter-runtime-" prefix off a runtime package's name to
;; get the <lang> tag it should be linked under.
(define (runtime-pkg->lang pkg)
  (let ((prefix "kak-tree-sitter-runtime-")
        (name   (package-name pkg)))
    (substring name (string-length prefix))))

(define (runtime-pkg->files pkg)
  "Return a list of home-xdg-data-files entries for the runtime grammar PKG:
one for the .so, one for the queries directory."
  (let ((lang (runtime-pkg->lang pkg)))
    (list
     ;; Grammar shared object.
     (list (string-append "kak-tree-sitter/runtime/grammars/" lang ".so")
           (file-append pkg
                        "/share/kak-tree-sitter/runtime/grammars/"
                        lang ".so"))
     ;; Queries directory — file-append a directory path, home service will
     ;; symlink the whole dir.
     (list (string-append "kak-tree-sitter/runtime/queries/" lang)
           (file-append pkg
                        "/share/kak-tree-sitter/runtime/queries/"
                        lang)))))

;; Colorscheme .kak files must land under ~/.config/kak/colors/ — kakoune only
;; searches (a) that path, and (b) the fixed share/kak/colors/ under its own
;; binary's install prefix.  It does NOT search ~/.guix-home/profile/share/kak/
;; even though profile merging puts our .kak files there.  So we point
;; home-xdg-configuration-files at the individual files from the themes
;; package to force them into ~/.config/kak/colors/.
(define %kak-tree-sitter-colorscheme-files
  (map
   (lambda (scheme)
     (list (string-append "kak/colors/" scheme ".kak")
           (file-append kakoune-tree-sitter-themes
                        "/share/kak/colors/" scheme ".kak")))
   '("night-owl"
     "catppuccin_latte"
     "catppuccin_macchiato"
     "catppuccin_mocha")))

;; TOML block for a single language: overrides the default (Source::Git,
;; which resolves to $XDG_DATA_HOME/kak-tree-sitter/{grammars,queries}/<lang>/
;; <pin>/) with Source::Local pointing straight at our Guix package's store
;; paths.  Without this, the server never finds our grammars because it looks
;; at a `<pin>`-bucketed path that ktsctl would populate.
(define (grammar-toml-block pkg lang)
  (list "\n[grammar." lang ".source.local]\npath = \""
        (file-append pkg "/share/kak-tree-sitter/runtime/grammars/"
                     lang ".so")
        "\"\n\n"
        "[language." lang ".queries.source.local]\npath = \""
        (file-append pkg "/share/kak-tree-sitter/runtime/queries/" lang)
        "\"\n"))

(define %kak-tree-sitter-config-toml
  (apply
   mixed-text-file
   "kak-tree-sitter-config.toml"
   "# Managed by dotfiles/guix/dotfiles/services/kak-tree-sitter.scm.
# Each [grammar.<lang>.source.local] + [language.<lang>.queries.source.local]
# block points straight at the store path of the corresponding Guix package
# (see (dotfiles packages kak-tree-sitter-grammars)).  This overrides the
# server's default Source::Git resolution, which expects files under
# $XDG_DATA_HOME/kak-tree-sitter/{grammars,queries}/<lang>/<pin>/ — a layout
# only produced by `ktsctl sync`.

[features]
highlighting = true
text_objects = true

# kak-tree-sitter only emits highlight ranges for capture names in this list.
# The upstream default omits `property`, `boolean`, `number`, `character`,
# `character.special` — but multiple grammars (editorconfig, yaml, css)
# use those.  Without listing them, the server silently drops the captures
# and their tokens render as `default`.  Extend the list to cover them.
[highlight]
groups = [
  # --- upstream defaults ---
  \"attribute\",
  \"comment\", \"comment.block\", \"comment.line\", \"comment.unused\",
  \"constant\", \"constant.builtin\", \"constant.builtin.boolean\",
  \"constant.character\", \"constant.character.escape\", \"constant.macro\",
  \"constant.numeric\", \"constant.numeric.float\", \"constant.numeric.integer\",
  \"constructor\",
  \"diff.plus\", \"diff.minus\", \"diff.delta\", \"diff.delta.moved\",
  \"embedded\", \"error\",
  \"function\", \"function.builtin\", \"function.macro\", \"function.method\",
  \"function.method.private\", \"function.special\",
  \"hint\", \"include\", \"info\",
  \"keyword\", \"keyword.conditional\",
  \"keyword.control\", \"keyword.control.conditional\", \"keyword.control.except\",
  \"keyword.control.exception\", \"keyword.control.import\", \"keyword.control.repeat\",
  \"keyword.control.return\",
  \"keyword.directive\", \"keyword.function\", \"keyword.operator\", \"keyword.special\",
  \"keyword.storage\", \"keyword.storage.modifier\", \"keyword.storage.modifier.mut\",
  \"keyword.storage.modifier.ref\", \"keyword.storage.type\",
  \"label\", \"load\",
  \"markup.bold\", \"markup.heading\", \"markup.heading.1\", \"markup.heading.2\",
  \"markup.heading.3\", \"markup.heading.4\", \"markup.heading.5\", \"markup.heading.6\",
  \"markup.heading.marker\", \"markup.italic\",
  \"markup.link.label\", \"markup.link.text\", \"markup.link.url\", \"markup.link.uri\",
  \"markup.list.checked\", \"markup.list.numbered\", \"markup.list.unchecked\",
  \"markup.list.unnumbered\",
  \"markup.quote\", \"markup.raw\", \"markup.raw.block\", \"markup.raw.inline\",
  \"markup.strikethrough\",
  \"namespace\", \"operator\",
  \"punctuation\", \"punctuation.bracket\", \"punctuation.delimiter\", \"punctuation.special\",
  \"special\",
  \"string\", \"string.escape\", \"string.regexp\", \"string.special\",
  \"string.special.path\", \"string.special.symbol\", \"string.symbol\",
  \"tag\", \"tag.error\", \"text\",
  \"type\", \"type.builtin\", \"type.enum.variant\", \"type.enum.variant.builtin\",
  \"type.parameter\",
  \"variable\", \"variable.builtin\", \"variable.other.member\",
  \"variable.other.member.private\", \"variable.parameter\",
  \"warning\",
  # --- extras that upstream misses but grammars use ---
  \"property\",              # editorconfig, css, yaml
  \"boolean\",               # editorconfig, yaml, json
  \"number\",                # editorconfig, generic
  \"character\",             # editorconfig
  \"character.special\",     # editorconfig (wildcards)
  # Short-form names used by older grammars (scala, some yaml, etc.).
  # nvim-treesitter's convention is the shorter form; upstream kts uses
  # the hierarchical form.  Declare both so grammars that stuck with
  # legacy names still emit ranges.
  \"conditional\",           # if/then/else/match — scala
  \"exception\",             # try/catch/throw
  \"repeat\",                # for/while
  \"function.call\",         # invocation vs definition
  \"method\",                # method definition
  \"method.call\",           # method invocation
  \"parameter\",             # function parameter (alt to variable.parameter)
  \"float\",                 # numeric literal (alt to constant.numeric.float)
  \"keyword.return\",        # return keyword
  \"type.definition\",       # type X = ...
  \"type.qualifier\",        # const, mutable, etc.
  \"storageclass\",          # val, var, lazy in scala
]
"
   (apply append
          (map (lambda (pkg)
                 (grammar-toml-block pkg (runtime-pkg->lang pkg)))
               %kak-tree-sitter-runtime-grammars))))

(define* (kak-tree-sitter-service #:key (grammars %kak-tree-sitter-runtime-grammars))
  "Return a list of home services that install kak-tree-sitter runtime
grammars + config.  GRAMMARS is a list of runtime-grammar packages (see
`(dotfiles packages kak-tree-sitter-grammars)`).  Compose this list into
`home-environment.services` alongside the other dotfiles services."
  (list
   ;; Runtime tree under ~/.local/share/kak-tree-sitter/.
   (simple-service 'kak-tree-sitter-runtime
                   home-xdg-data-files-service-type
                   (apply append (map runtime-pkg->files grammars)))
   ;; config.toml under ~/.config/kak-tree-sitter/, plus colorscheme .kak
   ;; files under ~/.config/kak/colors/ so `:colorscheme <name>` finds them.
   (simple-service 'kak-tree-sitter-config
                   home-xdg-configuration-files-service-type
                   (cons `("kak-tree-sitter/config.toml"
                           ,%kak-tree-sitter-config-toml)
                         %kak-tree-sitter-colorscheme-files))))
