(define-module (dotfiles packages micro-plugins fzf)
  #:use-module (guix packages)
  #:use-module (guix build-system copy)
  #:use-module (guix git-download)
  #:use-module (guix licenses)
  #:use-module (guix gexp))

(define-public micro-plugin-fzf
  (package
    (name "micro-plugin-fzf")
    (version "v0.2.1")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/MuratovAS/micro-fzfinder")
             (commit version)))
       (sha256
        (base32 "0q6ypcdb4kwv8vgq7m44rw4izqp3gqa8n7ga0x5w4zg5iqlrfqaj"))))
    (build-system copy-build-system)
    (arguments
     (list
      #:install-plan
      #~'(("./" "share/"))))
    (synopsis "FZF for micro!")
    (description
     "The plugin allows you to integrate fzf to select and search for your project files.")
    (home-page "https://github.com/MuratovAS/micro-fzfinder/")
    (license expat)))

micro-plugin-fzf
