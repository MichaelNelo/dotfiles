;; tree-sitter-editorconfig: grammar for `.editorconfig` files.
;;
;; Not in Guix.  Same @@-escape hatch as tree-sitter-hocon / tree-sitter-nu
;; to reuse Guix's private `tree-sitter-grammar` helper.

(define-module (dotfiles packages tree-sitter-editorconfig)
  #:use-module (guix gexp)                  ;plain-file, computed-file
  #:use-module (guix git-download)          ;git-version
  #:use-module (guix packages)              ;package inherit
  #:use-module (ice-9 match)
  #:export (tree-sitter-editorconfig))

(define tree-sitter-grammar
  (@@ (gnu packages tree-sitter) tree-sitter-grammar))

;; The upstream queries/editorconfig/highlights.scm uses `#lua-match?`, a
;; predicate that only exists in Neovim (nvim-treesitter, Lua-side).
;; kak-tree-sitter uses the standard Rust tree-sitter runtime, which only
;; understands `#match?` (regex-based).  Loading the grammar fails with:
;;
;;   ERROR: cannot lazy load language 'editorconfig'; cannot parse queries:
;;   unknown predicate #lua-match?
;;
;; The two predicates are semantically equivalent for our use case (both do a
;; regex match on the capture text).  Rewrite via origin snippet so every
;; downstream consumer (kak-tree-sitter, Helix, Emacs treesit-mode) sees the
;; portable form.
(define-public tree-sitter-editorconfig
  (let ((commit "1882c3f165aa6b56c4c7af91388d97b00ca1afe3")
        (revision "0"))
    (tree-sitter-grammar
     "editorconfig" "editorconfig"
     "1j3fhkjk0rhm41b72nb4nq8bdimsrs00jlplhcag6wydwjvna64j"
     (git-version "0.0.0" revision commit)
     #:commit commit
     #:repository-url "https://github.com/ValdezFOmar/tree-sitter-editorconfig")))

;; Post-process the grammar's queries to make them work with kak-tree-sitter's
;; standard tree-sitter runtime.  Two rewrites:
;;
;; 1. `#lua-match?` → `#match?`.  The former is a Neovim-only predicate
;;    (nvim-treesitter, Lua side); the standard runtime only understands
;;    the regex-based `#match?`.  Semantically equivalent for our uses.
;;
;; 2. Helper captures `@_key` (used only as anchors for `#eq?`/`#any-of?`
;;    predicates on the `indent_style`/`indent_size`/etc. property keys)
;;    → `@property`.  nvim-treesitter treats capture names starting with
;;    `_` as hidden (query-only, no highlight emitted).  kak-tree-sitter
;;    doesn't respect that convention and instead applies `_key` as a
;;    normal capture — but `_key` isn't in the `[highlight] groups` list,
;;    so the capture is silently discarded, PISANDO the base
;;    `(property) @property` rule for the same node.  Net effect: the key
;;    that matches a specialization query (e.g. `indent_style`) ends up
;;    with no face.  Renaming to `@property` both stops the discard and
;;    re-affirms the base rule.
(define-public tree-sitter-editorconfig
  (let* ((base tree-sitter-editorconfig)
         (base-source (package-source base)))
    (package
      (inherit base)
      (source
       (origin
         (inherit base-source)
         (modules '((guix build utils)))
         (snippet
          #~(begin
              (use-modules (guix build utils))
              (substitute* "queries/editorconfig/highlights.scm"
                (("#lua-match\\?") "#match?")
                (("@_key") "@property")))))))))
