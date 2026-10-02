;; tree-sitter-hocon: HOCON (Human-Optimized Config Object Notation) grammar.
;;
;; Not upstream in Guix.  Built with the standard `tree-sitter-grammar`
;; helper so it drops the .so into $out/lib/tree-sitter/libtree-sitter-hocon.so
;; alongside every other tree-sitter grammar in the store — our runtime
;; wrapper (`kak-tree-sitter-runtime-hocon`) picks it up from there.
;;
;; Upstream is unmaintained (last commit 2022-11) but the grammar is stable.
;; Bump `commit`/`sha256` when needed:
;;   git clone https://github.com/antosha417/tree-sitter-hocon /tmp/ts && \
;;     cd /tmp/ts && git rev-parse HEAD && guix hash -rx .

(define-module (dotfiles packages tree-sitter-hocon)
  #:use-module (gnu packages tree-sitter)   ;tree-sitter-json (grammar input)
  #:use-module (guix git-download)          ;git-version
  #:export (tree-sitter-hocon))

;; `tree-sitter-grammar` is defined but not exported by
;; (gnu packages tree-sitter) — reach into it with @@.  This is the same
;; escape hatch Guix's own packagers use when composing from private helpers.
(define tree-sitter-grammar
  (@@ (gnu packages tree-sitter) tree-sitter-grammar))

(define-public tree-sitter-hocon
  ;; HOCON's grammar.js starts with `require("tree-sitter-json/grammar")` —
  ;; it composes the JSON grammar.  Guix's tree-sitter-build-system exposes
  ;; each input's `js` output at build time so `tree-sitter generate` can
  ;; resolve the require.  Without this input, generate fails with
  ;;   Error: Cannot find module 'tree-sitter-json/grammar'
  (let ((commit "c390f10519ae69fdb03b3e5764f5592fb6924bcc")
        (revision "0"))
    (tree-sitter-grammar
     "hocon" "HOCON"
     "0v1hcfnlxphcpqs1md1cpi358mmfsa3yx8zc0rw65xi8i9hkg6pm"
     (git-version "0.0.0" revision commit)
     #:commit commit
     #:repository-url "https://github.com/antosha417/tree-sitter-hocon"
     #:inputs (list tree-sitter-json))))
