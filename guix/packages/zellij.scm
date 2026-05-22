(define-module (packages zellij)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system copy)
  #:use-module (guix gexp)
  #:use-module ((guix licenses)
                #:prefix license:)
  #:use-module (gnu packages compression))

(define-public zellij
  (package
    (name "zellij")
    (version "0.44.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://github.com/zellij-org/zellij/releases/download/v"
             version "/zellij-x86_64-unknown-linux-musl.tar.gz"))
       (sha256
        (base32 "0lfpr8768jr6z0wsf8n89zrcycw6fqbnaa9819n50zv2i1kk8z0g"))))
    (build-system copy-build-system)
    (arguments
     (list
      #:install-plan
      #~'(("zellij" "bin/zellij"))
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'install 'make-executable
            (lambda* (#:key outputs #:allow-other-keys)
              (let ((bin (string-append (assoc-ref outputs "out")
                                        "/bin/zellij")))
                (chmod bin #o755)))))))
    (native-inputs (list gzip))
    (home-page "https://github.com/zellij-org/zellij")
    (synopsis "Terminal workspace with batteries included")
    (description
     "Zellij is a terminal workspace with a rich set of features.
Some of the main features are:
- Terminal multiplexer with easy-to-use TUI
- Persistent sessions
- Plugins and themes support
- Share your terminal session with your team via SSH
- Smart keys - interact with elements in the screen without a mouse")
    (license license:expat)))

zellij
