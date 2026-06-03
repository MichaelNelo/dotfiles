(define-module (dotfiles packages pi)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system copy)
  #:use-module (guix gexp)
  #:use-module ((guix licenses)
                #:prefix license:)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages elf))

(define-public pi-coding-agent
  (package
    (name "pi-coding-agent")
    (version "0.78.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://github.com/earendil-works/pi/releases/download/v"
             version "/pi-linux-x64.tar.gz"))
       (sha256
        (base32 "1k472dgil5vzaypzwd3bwhlji23b5prmf88px03828p1s51k7h4a"))))
    (build-system copy-build-system)
    (arguments
     (list
      #:validate-runpath? #f
      #:strip-binaries? #f
      #:install-plan
      #~'(("pi" "lib/pi/")
          ("package.json" "lib/pi/")
          ("photon_rs_bg.wasm" "lib/pi/")
          ("node_modules" "lib/pi/node_modules")
          ("export-html" "lib/pi/export-html")
          ("docs" "lib/pi/docs")
          ("assets" "lib/pi/assets")
          ("theme" "lib/pi/theme"))
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'install 'patch-and-wrap
            (lambda* (#:key inputs outputs #:allow-other-keys)
              (let* ((out (assoc-ref outputs "out"))
                     (pi-exe (string-append out "/lib/pi/pi"))
                     (patchelf (search-input-file inputs "/bin/patchelf"))
                     (ld-so (search-input-file inputs
                                               "/lib/ld-linux-x86-64.so.2"))
                     (bin-dir (string-append out "/bin"))
                     (wrapper (string-append bin-dir "/pi"))
                     (sh #$(file-append bash "/bin/sh"))
                     (pi-dir (string-append out "/lib/pi")))
                (chmod pi-exe #o755)
                (invoke patchelf "--set-interpreter" ld-so pi-exe)
                (mkdir-p bin-dir)
                (call-with-output-file wrapper
                  (lambda (port)
                    (format port "#!~a~%exec ~a/pi \"$@\"~%" sh pi-dir)))
                (chmod wrapper #o755)))))))
    (native-inputs (list patchelf))
    (inputs (list glibc bash))
    (home-page "https://github.com/earendil-works/pi")
    (synopsis "Coding agent CLI with read, bash, edit, write tools")
    (description
     "Pi is a minimal terminal-based coding agent harness extensible via
TypeScript modules.  It provides four core tools (read, write, edit, bash)
and operates in interactive, print, JSON, RPC, or SDK modes.  Features
include session management with branching, context compression, customizable
prompts, skills, extensions, themes, and support for multiple LLM providers.")
    (license license:expat)))

pi-coding-agent
