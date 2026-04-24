(define-module (packages micro-plugins fzf)
  #:use-module (guix packages)
  #:use-module (guix build-system copy)
  #:use-module (guix git-download)
  #:use-module (guix licenses)
  #:use-module (guix gexp))

(define-public micro-plugin-fzf
  (package
    (name "micro-plugin-fzf")
    (version "ebc6baa05c3532ccaf9139b1d38a8791d6d5ba7d")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/samdmarshall/micro-fzf-plugin")
             (commit version)))
       (sha256
        (base32 "1any7szjjkwjla45g4xwy00zy04zzx23a955yis19zjw4h302r5n"))))
    (build-system copy-build-system)
    (arguments
     (list
      #:install-plan 
      #~'(("./" "share/"))))
    (synopsis "LSP for micro!")
    (description
     "Provides LSP methods as actions to Micro that can subsequently be mapped to key bindings.")
    (home-page "https://github.com/AndCake/micro-plugin-lsp")
    (license expat)))

micro-plugin-fzf
