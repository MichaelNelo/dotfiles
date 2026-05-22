(define-module (packages claude-code)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system trivial)
  #:use-module (guix gexp)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages node))
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
    (version "2.0.76")
    (source (origin
              (method url-fetch)
              (uri (string-append 
                    "https://registry.npmjs.org/@anthropic-ai/claude-code/-/"
                    "claude-code-" version ".tgz"))
              (sha256
               (base32
                "1ndrj51yfgkp1xgph5r3v6n946rlamj3v0y6wk4114wfzwv9k8zw"))))
    (build-system trivial-build-system)
    (arguments
     (list
      #:modules '((guix build utils))
      #:builder
      #~(begin
          (use-modules (guix build utils))
          
          (let* ((npm #$(file-append node "/bin/npm"))
                 (node-bin #$(file-append node "/bin/node"))
                 (tarball #$source)
                 (out #$output)
                 (bin-dir (string-append out "/bin"))
                 (lib-dir (string-append out "/lib")))
            
            (setenv "HOME" out)
            (setenv "NPM_CONFIG_PREFIX" out)
            (setenv "NPM_CONFIG_GLOBAL" "true")
            (setenv "PATH" (string-append (dirname node-bin) ":" (getenv "PATH")))
            
            (mkdir-p bin-dir)
            (mkdir-p lib-dir)
            
            (invoke npm
                    "install"
                    "-g"
                    tarball
                    "--prefix" out
                    "--loglevel=verbose"
                    "--offline"
                    "--no-audit"
                    "--no-fund")
            
            #t))))
    (native-inputs
     (list node))
    (home-page "https://code.claude.com")
    (synopsis "AI coding assistant from Anthropic")
    (description
     "Claude Code is an agentic coding tool that lives in your terminal,
understands your codebase, and helps you code faster.")
    (license license:expat)))

claude-code
