(define-module (packages doom)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix build-system copy)
  #:use-module (guix gexp)
  #:use-module ((guix licenses)
                #:prefix license:))

(define-public doom
  (package
    (name "doom-emacs")
    (version "3e15fb36d7f94f0a218bda977be4d3f5da983a71")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/doomemacs/doomemacs")
             (commit version)))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0fd5vma846cjby87ysm33fdkfnnp73xnyj931x0xq554zpvfvgs0"))))
    (build-system copy-build-system)
    (arguments
     '(#:install-plan '(("." "share/doom-emacs"))))
    (home-page "https://github.com/doomemacs/doomemacs")
    (synopsis "Framework for managing emacs packages and configuration")
    (description "An Emacs framework for the stubborn martian hacker")
    (license license:expat)))

doom
