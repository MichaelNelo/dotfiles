(define-module (packages claude-code)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system trivial)
  #:use-module (guix gexp)
  #:use-module ((guix licenses)
                #:prefix license:)
  #:use-module (gnu packages node)
  #:use-module (gnu packages bash))

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
    (native-inputs (list node bash claude-code-linux-x64))
    (arguments
     (list
      #:modules '((guix build utils))
      #:builder
      #~(begin
          (use-modules (guix build utils))

          (let* ((npm #$(file-append node "/bin/npm"))
                 (node-bin #$(file-append node "/bin/node"))
                 (sh-bin #$(file-append bash "/bin/sh"))
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

            ;; Paso 1: Instalar el linux-x64 binary primero
            ;; El postinstall extrae el tarball y copia el binary
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

            ;; Paso 2: Instalar el wrapper después
            ;; El postinstall encuentra el linux-x64 binary ya instalado y lo vincula
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

            #t))))
    (home-page "https://code.claude.com")
    (synopsis "AI coding assistant from Anthropic")
    (description
     "Claude Code is an agentic coding tool that lives in your terminal,
understands your codebase, and helps you code faster.")
    (license license:expat)))

claude-code
