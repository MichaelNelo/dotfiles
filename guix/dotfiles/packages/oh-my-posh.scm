(define-module (dotfiles packages oh-my-posh)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system trivial)
  #:use-module (guix gexp)
  #:use-module (gnu packages compression)
  #:use-module ((guix licenses)
                #:prefix license:))

(define oh-my-posh-themes-source
  (origin
    (method url-fetch)
    (uri (string-append
          "https://github.com/JanDeDobbeleer/oh-my-posh/releases/download/v"
          "29.14.0/themes.zip"))
    (file-name "oh-my-posh-themes-29.14.0.zip")
    (sha256
     (base32 "1s6s665zkbld4dx8fkdnh6xmgzcvkzdiiz1yp2i7vdic2np51fw6"))))

(define-public oh-my-posh
  (package
    (name "oh-my-posh")
    (version "29.14.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://github.com/JanDeDobbeleer/oh-my-posh/releases/download/v"
             version "/posh-linux-amd64"))
       (sha256
        (base32 "00jy096cpzmrznfz7w70wnf67wsm5dj7and1vqzfkdascy154d3z"))))
    (build-system trivial-build-system)
    (arguments
     (list
      #:modules '((guix build utils))
      #:builder
      #~(begin
          (use-modules (guix build utils))
          (let* ((bin (string-append #$output "/bin"))
                 (themes (string-append #$output "/share/oh-my-posh/themes"))
                 (dst (string-append bin "/oh-my-posh"))
                 (unzip (string-append #+unzip "/bin/unzip")))
            (mkdir-p bin)
            (copy-file #$(package-source this-package) dst)
            (chmod dst #o755)
            (mkdir-p themes)
            (invoke unzip "-q" #$oh-my-posh-themes-source "-d" themes)))))
    (native-inputs (list unzip))
    (home-page "https://ohmyposh.dev/")
    (synopsis "Prompt theme engine for any shell")
    (description
     "Oh My Posh is a prompt theme engine for any shell, written in Go.  It
provides a cross-shell prompt with configurable themes and dynamic
segments (git status, language versions, cloud context, etc.).")
    (license license:expat)))

oh-my-posh
