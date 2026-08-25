;; -*- mode: scheme; -*-
;; 1Password CLI package for Guix

(define-module (dotfiles packages onepassword-cli)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix build-system copy)
  #:use-module (nonguix licenses)
  #:use-module (gnu packages compression)
  #:export (onepassword-cli))

(define-public onepassword-cli
  (package
    (name "onepassword-cli")
    (version "2.34.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://cache.agilebits.com/dist/1P/op2/pkg/v"
                           version "/op_linux_amd64_v" version ".zip"))
       (sha256
        (base32 "09j2ff3n3figbsk5syr56z4b0ycr8ln2ckjsrrw2g5x0z7f0b2qr"))))
    (build-system copy-build-system)
    (arguments
     '(#:install-plan '(("op" "bin/"))))
    (native-inputs (list unzip))
    (home-page "https://developer.1password.com/docs/cli/")
    (synopsis "1Password command-line interface")
    (description
     "1Password CLI brings 1Password to your terminal.  You can use it to
sign in to your 1Password account, manage items in your vaults,
provision team members, groups, and vaults, and automate your secrets
workflows.")
    (license (nonfree "https://1password.com/legal/terms-of-service/"))))

onepassword-cli
