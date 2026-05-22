(define-module (packages opencode)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build utils)
  #:use-module (guix build-system copy)
  #:use-module (guix gexp)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages base)
  #:use-module (gnu packages gcc)
  #:use-module ((guix licenses)
                #:prefix license:)
  #:use-module (gnu packages compression))

(define-public opencode
  (package
    (name "opencode")
    (version "v1.15.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://github.com/anomalyco/opencode/releases/download/"
             version "/opencode-linux-x64.tar.gz"))
       (sha256
        (base32 "1d0n47zgn74rl9ig39qv6fbfj1lyng1w3192ww63pkwnknsvia6s"))))
    (build-system copy-build-system)
    (arguments
     (list
      #:validate-runpath? #f
      #:strip-binaries? #f
      #:install-plan
      #~`(("opencode" "bin/opencode"))
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'install 'patchelf
            (lambda* (#:key inputs outputs #:allow-other-keys)
              (let* ((opencode-out (assoc-ref outputs "out"))
                     (ldd (search-input-file inputs
                                             "/lib/ld-linux-x86-64.so.2"))
                     (patchelf (search-input-file inputs "/bin/patchelf"))
                     (opencode (string-append opencode-out "/bin/opencode")))
                (chmod opencode #o755)
                (invoke patchelf "--set-interpreter" ldd opencode)))))))
    (native-inputs `(("patchelf" ,patchelf)
                     ("glibc" ,glibc)))
    (inputs (list `(,gcc "lib")))
    (home-page "https://opencode.ai")
    (synopsis "The open source coding agent.")
    (description
     "OpenCode is an open source AI coding agent. It’s available as a terminal-based interface, desktop app, or IDE extension.")
    (license license:expat)))

opencode
