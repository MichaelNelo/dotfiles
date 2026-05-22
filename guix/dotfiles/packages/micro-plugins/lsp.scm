(define-module (dotfiles packages micro-plugins lsp)
  #:use-module (guix packages)
  #:use-module (guix build-system copy)
  #:use-module (guix git-download)
  #:use-module (guix licenses)
  #:use-module (guix gexp))

(define-public micro-plugin-lsp
  (package
    (name "micro-plugin-lsp")
    (version "v0.6.3")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/AndCake/micro-plugin-lsp")
             (commit version)))
       (sha256
        (base32 "1xlhran7kq9s7j5d85j91mhlih790n6m7jk10j4xc64gsp1mb7xd"))))
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

micro-plugin-lsp
