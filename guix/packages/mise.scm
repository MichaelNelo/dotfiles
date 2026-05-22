(define-module (packages mise)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build utils)
  #:use-module (guix build-system copy)
  #:use-module (guix gexp)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages base)
  #:use-module (gnu packages gcc)
  #:use-module ((guix licenses)
                #:prefix license:))

(define-public mise
  (package
    (name "mise")
    (version "v2026.1.8")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/jdx/mise/releases/download/"
                           version "/mise-" version "-linux-x64"))
       (sha256
        (base32 "04bfk58ymk8z91ghy3rdxa46afvkwfc9pxbzba1srf0wrnszykj3"))))
    (build-system copy-build-system)
    (arguments
     (list
      #:install-plan
      #~`((,(string-append "mise-"
                           #$version "-linux-x64") "bin/mise"))
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'install 'patchelf
            (lambda* (#:key inputs outputs #:allow-other-keys)
              (let* ((mise-out (assoc-ref outputs "out"))
                     (ldd (search-input-file inputs
                                             "/lib/ld-linux-x86-64.so.2"))
                     (patchelf (search-input-file inputs "/bin/patchelf"))
                     (libgcc (search-input-file inputs "/lib/libgcc_s.so.1"))
                     (librt (search-input-file inputs "/lib/librt.so.1"))
                     (libpthread (search-input-file inputs
                                                    "/lib/libpthread.so.0"))
                     (libm (search-input-file inputs "/lib/libm.so.6"))
                     (libdl (search-input-file inputs "/lib/libdl.so.2"))
                     (libc (search-input-file inputs "/lib/libc.so.6"))
                     (mise (string-append mise-out "/bin/mise")))
                (chmod mise #o755)
                (invoke patchelf
                        "--set-rpath"
                        (string-join (map dirname
                                          (list libgcc
                                                librt
                                                libpthread
                                                libm
                                                libdl
                                                libc)) ":")
                        "--set-interpreter"
                        ldd
                        mise)))))))
    (native-inputs `(("patchelf" ,patchelf)
                     ("glibc" ,glibc)))
    (inputs (list `(,gcc "lib")))
    (home-page "https://mise.jdx.dev")
    (synopsis "The front-end to your dev env")
    (description
     "A tool that manages development packages from different sources/backends")
    (license license:expat)))

mise
