;; Facade for (dotfiles secrets ...) submodules.
;;
;; Guile has no `index.js`-style auto-import: a consumer who
;; `(use-module (dotfiles secrets))` gets whatever THIS file re-exports,
;; nothing more.  The convention: keep the folder's public API surface
;; here so callers don't need to know how the internals are split.
;;
;; Actual definitions live under (dotfiles secrets record),
;; (dotfiles secrets nushell), (dotfiles secrets piknik) — see those
;; files.

(define-module (dotfiles secrets)
  #:use-module (dotfiles secrets record)
  #:use-module (dotfiles secrets nushell)
  #:use-module (dotfiles secrets piknik)
  #:re-export (;; record.scm
               <secret>
               secret
               secret?
               secret-name
               secret-path
               secret-type
               secret-source
               secret-mode
               secret-owner
               secret-on-missing
               secret->wait-loop-gexp

               ;; nushell.scm
               secret->nushell-provisioner
               secrets->nushell-config

               ;; piknik.scm
               <piknik-source>
               piknik-source
               piknik-source?
               piknik-source-vault
               piknik-source-item
               piknik-source-fields
               piknik-source-listen
               piknik-source-connect))
