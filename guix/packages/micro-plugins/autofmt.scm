(define-module (packages micro-plugins autofmt)
  #:use-module (guix packages)
  #:use-module (guix build-system copy)
  #:use-module (guix git-download)
  #:use-module (guix licenses)
  #:use-module (guix gexp))

(define-public micro-plugin-autofmt
  (package
    (name "micro-plugin-autofmt")
    (version "3.0.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/a11ce/micro-autofmt")
             (commit version)))
       (sha256
        (base32 "1ynwfq8n6wdaibq9xyzim54sk0hz0fnqavnph1dnw5a78rv7s06h"))))
    (build-system copy-build-system)
    (arguments
     (list
      #:install-plan
      #~'(("./" "share/"))))
    (synopsis "Multilingual formatter for Micro")
    (description "Multi-language formatting plugin for the Micro editor")
    (home-page "https://github.com/a11ce/micro-autofmt")
    (license expat)))

micro-plugin-autofmt
