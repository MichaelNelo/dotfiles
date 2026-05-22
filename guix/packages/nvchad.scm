(define-module (packages nvchad)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix build-system copy)
  #:use-module (guix gexp)
  #:use-module ((guix licenses)
                #:prefix license:))

(define-public nvchad
  (package
    (name "nvchad")
    (version "e3572e1f5e1c297212c3deeb17b7863139ce663e")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/NvChad/NvChad")
             (commit version)))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0990zl66nydhiphcim5yb5sizgbfnqbalagdq8zf1xjlv7mfpln5"))))
    (build-system copy-build-system)
    (arguments
     '(#:install-plan '(("." "share/nvchad"))))
    (home-page "https://github.com/NvChad/NvChad")
    (synopsis "Enhance your Neovim workflow")
    (description
     "Blazing fast Neovim config providing solid defaults and a beautiful UI")
    (license license:expat)))

nvchad
