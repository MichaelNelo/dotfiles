(define-module (dotfiles packages scala-cli)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system copy)
  #:use-module (guix gexp)
  #:use-module ((guix licenses)
                #:prefix license:)
  #:use-module (gnu packages base)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages elf))

(define-public scala-cli
  (package
    (name "scala-cli")
    (version "1.17.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/Virtuslab/scala-cli/releases/download/v"
                           version
                           "/scala-cli-x86_64-pc-linux.gz"))
       (sha256
        (base32 "1cwfhl44xh7mprcn5gzwm9dva77crlpdz6wksfzpy2ajcnnbz1j1"))))
    (build-system copy-build-system)
    (native-inputs (list gzip zlib patchelf))
    (arguments
     (list
      #:install-plan
      #~'(("scala-cli" "bin/scala-cli"))
      #:phases
      #~(modify-phases %standard-phases
          (replace 'unpack
            (lambda* (#:key source #:allow-other-keys)
              ;; gzip refuses to decompress a hard-linked file in-place;
              ;; the store deduplicates by hard-linking so `source` always
              ;; has siblings.  Copy to the build dir first.
              (copy-file source "scala-cli.gz")
              (invoke #$(file-append gzip "/bin/gzip") "-d" "scala-cli.gz")))
          (add-after 'install 'patch-zlib
            (lambda* (#:key inputs outputs #:allow-other-keys)
              (let* ((out (assoc-ref outputs "out"))
                     (scala-cli (string-append out "/bin/scala-cli"))
                     (ld-so (search-input-file inputs"/lib/ld-linux-x86-64.so.2"))
                     (libz (search-input-file inputs "/lib/libz.so")))
                (chmod scala-cli #o755)
                (invoke #$(file-append patchelf "/bin/patchelf")
                        "--add-rpath" (dirname libz) scala-cli
                        "--set-interpreter" ld-so)))))))
    (home-page "https://github.com/Virtuslab/scala-cli")
    (synopsis "CLI to run and compile scala programs")
    (description "Scala CLI combines all of the features you need to learn and use Scala in your scripts, playgrounds and (single-module) projects.")
    (license license:asl2.0)))

scala-cli
