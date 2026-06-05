(define-module (dotfiles packages zellij-plugins)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system trivial)
  #:use-module (guix gexp)
  #:use-module ((guix licenses)
                #:prefix license:))

(define (make-wasm-package name version uri hash synopsis home-page)
  "Single-file .wasm plugin: copy to share/zellij/plugins/NAME.wasm."
  (package
    (name name)
    (version version)
    (source
     (origin
       (method url-fetch)
       (uri uri)
       (file-name (string-append name "-" version ".wasm"))
       (sha256 (base32 hash))))
    (build-system trivial-build-system)
    (arguments
     (list
      #:modules '((guix build utils))
      #:builder
      #~(begin
          (use-modules (guix build utils))
          (let* ((plugins (string-append #$output "/share/zellij/plugins"))
                 (dst (string-append plugins "/" #$name ".wasm")))
            (mkdir-p plugins)
            (copy-file #$(package-source this-package) dst)
            (chmod dst #o644)))))
    (home-page home-page)
    (synopsis synopsis)
    (description synopsis)
    (license license:expat)))

(define-public zjstatus
  (make-wasm-package
   "zjstatus" "0.23.0"
   "https://github.com/dj95/zjstatus/releases/download/v0.23.0/zjstatus.wasm"
   "1zv173qh67x4bf4k4m5fpz22vy0pbp6f88c0c7dkjhjj4c9901p0"
   "Configurable status bar plugin for Zellij"
   "https://github.com/dj95/zjstatus"))

(define-public zellij-room
  (make-wasm-package
   "room" "1.2.1"
   "https://github.com/rvcas/room/releases/download/v1.2.1/room.wasm"
   "1lbjq3wipw1is8zcpb8kbk6yvyq5g9c608c6fpxnh93n1fj87d4h"
   "Session manager TUI plugin for Zellij"
   "https://github.com/rvcas/room"))

;; List for convenience when adding all three to a profile
(define-public %zellij-plugins
  (list zjstatus zellij-room))
