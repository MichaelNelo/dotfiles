(define-module (dotfiles packages kakoune-lsp)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system copy)
  #:use-module (guix gexp)
  #:use-module ((guix licenses)
                #:prefix license:)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages elf))

(define-public kakoune-lsp
  (package
    (name "kakoune-lsp")
    (version "21.0.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://github.com/kakoune-lsp/kakoune-lsp/releases/download/v"
             version
              "/kakoune-lsp-v"
             version
             "-x86_64-unknown-linux-musl.tar.gz"))
       (sha256
        (base32 "0i96w241nnrm65w96knladz5w0550wj74fyz5lzsgkjba0cinh7l"))))
    (build-system copy-build-system)
    (arguments
     (list
      #:install-plan
      #~'(("kak-lsp" "bin/"))))
    (native-inputs (list patchelf))
    (inputs (list glibc bash))
    (home-page "https://github.com/kakoune-lsp/kakoune-lsp")
    (synopsis
     "Kakoune Language Server Protocol Client")
    (description "This is a Language Server Protocol client for the Kakoune editor (version v2021.11.08 or higher).")
    (license license:expat)))

kakoune-lsp
