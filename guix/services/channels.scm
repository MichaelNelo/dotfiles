(define-module (services channels)
  #:use-module (gnu home services guix)
  #:use-module (guix channels)
  #:use-module (gnu services)
  #:export     (%channels-service))

(define %channels-service
  (simple-service 'my-channels-service-type home-channels-service-type
                  (cons* (channel
                           (name 'rustup)
                           (url
                            "https://github.com/declantsien/guix-rustup.git"))
                          (channel
                           (name 'guix-science-nonfree)
                           (url
                            "https://codeberg.org/guix-science/guix-science-nonfree.git")
                           (introduction
                            (make-channel-introduction
                             "58661b110325fd5d9b40e6f0177cc486a615817e"
                             (openpgp-fingerprint
                              "CA4F 8CF4 37D7 478F DA05  5FD4 4213 7701 1A37 8446"))))
                          %default-channels)))
