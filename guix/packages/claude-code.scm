(define-module (packages claude-code)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system trivial)
  #:use-module (guix gexp)
  #:use-module ((guix licenses)
                #:prefix license:)
  #:use-module (gnu packages node)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base))

(define version
  "2.1.143")

(define-public claude-code-linux-x64
  (origin
    (method url-fetch)
    (uri (string-append
          "https://registry.npmjs.org/@anthropic-ai/claude-code-linux-x64/-/"
          "claude-code-linux-x64-" version ".tgz"))
    (sha256 (base32 "1165r7xqcs4vs6l613469pkiv3xvy6rhbh0r9ma4dqvhbrv21qk3"))))

(define-public claude-code
  (package
    (name "claude-code")
    (version version)
    (build-system trivial-build-system)
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://registry.npmjs.org/@anthropic-ai/claude-code/-/"
             "claude-code-" version ".tgz"))
       (sha256
        (base32 "0rji3ahx6dvfsc07281n32y44gm6bfwrazi753lcns3z3nkh7jn8"))))
    (native-inputs (list node bash))
    (inputs (list glibc claude-code-linux-x64))
    (arguments
     (list
      #:modules '((guix build utils))
      #:builder
      #~(begin
          (use-modules (guix build utils))

          (let* ((npm #$(file-append node "/bin/npm"))
                 (node-bin #$(file-append node "/bin/node"))
                 (sh-bin #$(file-append bash "/bin/sh"))
                 (glibc #$(this-package-input "glibc"))
                 (ld-linux (string-append glibc "/lib/ld-linux-x86-64.so.2"))
                 (out #$output)
                 (bin-dir (string-append out "/bin"))
                 (lib-dir (string-append out "/lib")))

            (setenv "HOME" out)
            (setenv "NPM_CONFIG_PREFIX" out)
            (setenv "NPM_CONFIG_GLOBAL" "true")
            (setenv "PATH"
                    (string-append (dirname node-bin) ":"
                                   (dirname sh-bin) ":"
                                   (getenv "PATH")))

            (mkdir-p bin-dir)
            (mkdir-p lib-dir)

            ;; Install the linux-x64 binary package
            (invoke npm
                    "install"
                    "-g"
                    #$claude-code-linux-x64
                    "--prefix"
                    out
                    "--loglevel=verbose"
                    "--offline"
                    "--no-audit"
                    "--no-fund")

            ;; Install the main wrapper package
            (invoke npm
                    "install"
                    "-g"
                    #$source
                    "--prefix"
                    out
                    "--loglevel=verbose"
                    "--offline"
                    "--no-audit"
                    "--no-fund")

            ;; Create a wrapper script that invokes the binary via Guix's ld-linux
            ;; (patchelf corrupts Bun binaries, so we use the dynamic linker directly)
            (let ((claude-exe (string-append out "/lib/node_modules/@anthropic-ai/claude-code/bin/claude.exe"))
                  (wrapper (string-append bin-dir "/claude")))
              ;; Remove the symlink npm created
              (when (file-exists? wrapper)
                (delete-file wrapper))
              ;; Write wrapper script
              (call-with-output-file wrapper
                (lambda (port)
                  (format port "#!~a~%exec ~a --library-path ~a ~a \"$@\"~%"
                          sh-bin ld-linux (string-append glibc "/lib") claude-exe)))
              (chmod wrapper #o755))

            #t))))
    (home-page "https://code.claude.com")
    (synopsis "AI coding assistant from Anthropic")
    (description
     "Claude Code is an agentic coding tool that lives in your terminal,
understands your codebase, and helps you code faster.")
    (license license:expat)))

claude-code
