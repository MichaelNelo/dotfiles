;; tree-sitter-nu: Nushell grammar.
;;
;; Not upstream in Guix.  Same @@-escape hatch as tree-sitter-hocon to reuse
;; Guix's private `tree-sitter-grammar` helper.

(define-module (dotfiles packages tree-sitter-nu)
  #:use-module (guix git-download)          ;git-version
  #:export (tree-sitter-nu))

(define tree-sitter-grammar
  (@@ (gnu packages tree-sitter) tree-sitter-grammar))

(define-public tree-sitter-nu
  (let ((commit "64613ef22f4116862d7997939c8d1794ceb1f856")
        (revision "0"))
    (tree-sitter-grammar
     "nu" "Nushell"
     "0yy8gj7aq5376zjvhpbkb673gv5y3l2jq3cwwyip5cq9hw9jcy60"
     (git-version "0.0.0" revision commit)
     #:commit commit
     #:repository-url "https://github.com/nushell/tree-sitter-nu")))
