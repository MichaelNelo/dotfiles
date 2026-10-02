;; kakoune-tree-sitter-themes: pre-built colorschemes with ts_* faces.
;;
;; Upstream ships colors under `colors/<family>/<name>.kak` (sub-directory per
;; palette family).  We flatten them into `$out/share/kak/colors/` so kakoune's
;; `colorscheme` command finds them: kakoune searches for a scheme NAME in
;; @file{<install-dir>/share/kak/colors/NAME.kak}, and Guix Home merges every
;; profile package's share/ tree under @file{~/.guix-home/profile/share/}.
;; No home-service needed — profile inclusion is enough.
;;
;; Bump: update commit + refresh hash with
;;   guix hash -rx $(git clone <url> && cd repo && git checkout <sha> && ..).

(define-module (dotfiles packages kakoune-tree-sitter-themes)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix build-system trivial)
  #:use-module (guix gexp)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (kakoune-tree-sitter-themes))

(define-public kakoune-tree-sitter-themes
  (package
    (name "kakoune-tree-sitter-themes")
    (version "0.0.0-1.205ec3f")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://git.sr.ht/~hadronized/kakoune-tree-sitter-themes")
             (commit "205ec3f2fde8fbfa578e4a4b853a36ec3443e4b0")))
       (file-name (string-append name "-" version "-checkout"))
       (sha256
        (base32 "0r2ddfn5gfk6fbjjakfl1mi58wd6zk0m7m6qy9jwsvbhn6z7c3p5"))))
    (build-system trivial-build-system)
    (arguments
     (list
      #:modules '((guix build utils)
                  (ice-9 ftw)
                  (srfi srfi-1))
      #:builder
      #~(begin
          (use-modules (guix build utils)
                       (ice-9 ftw)
                       (srfi srfi-1))
          (let* ((src (assoc-ref %build-inputs "source"))
                 (colors-src (string-append src "/colors"))
                 (out (assoc-ref %outputs "out"))
                 (dst (string-append out "/share/kak/colors")))
            (mkdir-p dst)
            ;; Flatten colors/<family>/*.kak → share/kak/colors/*.kak.
            (for-each
             (lambda (family)
               (let ((family-dir (string-append colors-src "/" family)))
                 (when (eq? 'directory (stat:type (stat family-dir)))
                   (for-each
                    (lambda (file)
                      (when (string-suffix? ".kak" file)
                        (copy-file (string-append family-dir "/" file)
                                   (string-append dst "/" file))))
                    (scandir family-dir
                             (lambda (f) (not (member f '("." "..")))))))))
             (scandir colors-src
                      (lambda (f) (not (member f '("." ".."))))))))))
    (home-page "https://git.sr.ht/~hadronized/kakoune-tree-sitter-themes")
    (synopsis "Tree-sitter-aware colorschemes for Kakoune")
    (description
     "Ships four colorschemes that define the @code{ts_*} faces consumed by
@code{kak-tree-sitter}: @code{catppuccin_latte}, @code{catppuccin_macchiato},
@code{catppuccin_mocha}, and @code{night-owl}.  Installed under
@file{share/kak/colors/} so Kakoune's @code{:colorscheme NAME} command finds
them.")
    (license license:bsd-3)))
