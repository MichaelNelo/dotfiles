(define-module (packages fzfcolored)
  #:use-module (guix packages)
  #:use-module (guix build-system trivial)
  #:use-module (guix gexp)
  #:use-module (guix licenses)
  #:use-module (gnu packages rust-apps)
  #:use-module (gnu packages terminals))

(define-public fzfcolored
  (package
    (name "fzfcolored")
    (version "0.1.0")
    (source #f)
    (build-system trivial-build-system)
    (arguments
     (list
      #:modules '((guix build utils))
      #:builder
      #~(begin
          (use-modules (guix build utils))
          (let* ((out (assoc-ref %outputs "out"))
                 (bin (string-append out "/bin"))
                 (fd  (string-append (assoc-ref %build-inputs "fd") "/bin/fd"))
                 (fzf (string-append (assoc-ref %build-inputs "fzf") "/bin/fzf")))
            (mkdir-p bin)
            (call-with-output-file (string-append bin "/fzfcolored")
              (lambda (port)
                (format port "#!/bin/sh~%exec ~a . -t f -c always | ~a --ansi \"$@\"~%" fd fzf)))
            (chmod (string-append bin "/fzfcolored") #o755)))))
    (inputs (list fd fzf))
    (synopsis "Colored fzf wrapper using fd")
    (description
     "A wrapper script that pipes fd output with colors into fzf with ANSI support.
Recommended by the micro-fzfinder plugin for colored file selection.")
    (home-page "https://github.com/MuratovAS/micro-fzfinder")
    (license expat)))
