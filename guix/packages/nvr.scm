(define-module (packages nvr)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system python)
  #:use-module (guix gexp)
  #:use-module ((guix licenses)
                #:prefix license:)
  #:use-module (gnu packages python)
  #:use-module (gnu packages python-build)
  #:use-module (gnu packages python-xyz)
  #:use-module (gnu packages vim))

(define-public nvr
  (package
    (name "nvr")
    (version "2.5.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://github.com/mhinz/neovim-remote/archive/refs/tags/v"
             version ".tar.gz"))
       (file-name (string-append "neovim-remote-" version ".tar.gz"))
       (sha256
        (base32 "00fs2j67g9k57lpcp5i1rg3687fj3vp266s4vrl93a9fv3w4vw6g"))))
    (build-system python-build-system)
    (arguments
     (list
      #:tests? #f))
    (propagated-inputs (list python-psutil python-pynvim
                             python-typing-extensions))
    (home-page "https://github.com/mhinz/neovim-remote")
    (synopsis "Control nvim processes using the nvr command line tool")
    (description
     "nvr is a Python script that controls Neovim instances remotely via its
msgpack-rpc API.  Useful for editing files from inside :term, sharing one nvim
instance across panes, or scripting nvim from the shell.")
    (license license:expat)))

nvr
