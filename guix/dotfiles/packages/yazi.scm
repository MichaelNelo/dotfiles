(define-module (dotfiles packages yazi)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system copy)
  #:use-module (guix gexp)
  #:use-module ((guix licenses)
                #:prefix license:)
  #:use-module (gnu packages compression)
  #:use-module (srfi srfi-1)
  #:export (yazi
            make-yazi-package))

(define (yazi-completions-spec completions)
  "Return install-plan entries for the given COMPLETIONS list.
COMPLETIONS is a list of symbols: 'bash, 'zsh, 'fish, or empty."
  (append
   (cond ((member 'bash completions)
          '(("completions/yazi.bash" "share/bash-completion/completions/yazi")
            ("completions/ya.bash" "share/bash-completion/completions/ya")))
         (else '()))
   (cond ((member 'zsh completions)
          '(("completions/_yazi" "share/zsh/site-functions/_yazi")
            ("completions/_ya" "share/zsh/site-functions/_ya")))
         (else '()))
   (cond ((member 'fish completions)
          '(("completions/yazi.fish" "share/fish/vendor_completions.d/yazi.fish")
            ("completions/ya.fish" "share/fish/vendor_completions.d/ya.fish")))
         (else '()))))

(define* (make-yazi-package
          #:key
          (completions '(bash zsh fish))
          (version "26.5.6"))
  "Create a Yazi package with optional COMPLETIONS.
COMPLETIONS is a list of symbols: 'bash, 'zsh, 'fish.
Pass '() to install no completions."
  (package
    (name "yazi")
    (version version)
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://github.com/sxyazi/yazi/releases/download/v" version
             "/yazi-x86_64-unknown-linux-musl.zip"))
       (sha256
        (base32 "1zqvd242n7mka084hc2wrss5rh97s9hncnhr6wak0lyhc0js0c8h"))))
    (build-system copy-build-system)
    (arguments
     (list
      #:install-plan
      #~(append
         '(("yazi" "bin/yazi")
           ("ya" "bin/ya")
           ("LICENSE" "share/doc/yazi/LICENSE")
           ("README.md" "share/doc/yazi/README.md"))
         #$@(yazi-completions-spec completions))
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'install 'make-executable
            (lambda* (#:key outputs #:allow-other-keys)
              (let ((bin (string-append (assoc-ref outputs "out") "/bin")))
                (chmod (string-append bin "/yazi") #o755)
                (chmod (string-append bin "/ya") #o755)))))))
    (native-inputs (list unzip))
    (home-page "https://github.com/sxyazi/yazi")
    (synopsis "Blazing fast terminal file manager written in Rust")
    (description
     "Yazi is an async terminal file manager with image preview, fzf
integration, a Lua plugin system, and a built-in package manager (ya).
This package ships the upstream statically-linked musl release binary.")
    (license license:expat)))

(define-public yazi
  (make-yazi-package #:completions '()))

yazi
