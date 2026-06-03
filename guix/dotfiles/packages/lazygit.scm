(define-module (dotfiles packages lazygit)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system copy)
  #:use-module (guix gexp)
  #:use-module ((guix licenses)
                #:prefix license:)
  #:use-module (gnu packages compression))

(define-public lazygit
  (package
    (name "lazygit")
    (version "0.50.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://github.com/jesseduffield/lazygit/releases/download/v"
             version "/lazygit_" version "_Linux_x86_64.tar.gz"))
       (sha256
        (base32 "10cq2xl5ga9whfiydrswhbw4cpjrl5pqman5a337h9hyifnc0axv"))))
    (build-system copy-build-system)
    (arguments
     (list
      #:install-plan
      #~'(("lazygit" "bin/lazygit"))
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'install 'make-executable
            (lambda* (#:key outputs #:allow-other-keys)
              (let ((bin (string-append (assoc-ref outputs "out")
                                        "/bin/lazygit")))
                (chmod bin #o755)))))))
    (native-inputs (list gzip))
    (home-page "https://github.com/jesseduffield/lazygit")
    (synopsis "Simple terminal UI for git commands")
    (description
     "Lazygit is a simple terminal UI for git commands, written in Go with the
gocui library. It provides an intuitive interface for common git operations.")
    (license license:expat)))

lazygit
