(define-module (packages omz)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix build-system copy)
  #:use-module (guix gexp)
  #:use-module ((guix licenses) #:prefix license:))

(define-public omz
  (package
   (name "oh-my-zsh")
   (version "35068db8373917a23eb9e3dabeb6596348e6534c")
   (source (origin
            (method git-fetch)
            (uri (git-reference
                  (url "https://github.com/ohmyzsh/ohmyzsh")
                  (commit version)))
            (file-name (git-file-name name version))
            (sha256
             (base32
              "0lmja67byssqxvgd6qs1fibpqw1b03lpdjikwnihaphx3277dllz"))))
   (build-system copy-build-system)
   (arguments
    '(#:install-plan
      '(("." "share/oh-my-zsh"
         #:include-regexp (".*")))))
   (home-page "https://ohmyz.sh/")
   (synopsis "Framework for managing zsh configuration")
   (description "Oh My Zsh is a framework for managing your zsh configuration.")
   (license license:expat)))

omz
