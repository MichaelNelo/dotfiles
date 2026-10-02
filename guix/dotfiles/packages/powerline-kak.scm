;; powerline-kak: modeline plugin providing git/lsp/filetype/mode/cursor
;; modules with powerline-style separators.
;;
;; Installs the plugin's `rc/` tree under
;; @file{$out/share/kak/autoload/powerline/}.  Kakoune's default startup
;; kakrc auto-sources every @file{*.kak} under @file{${kak_runtime}/autoload/}
;; (which Guix Home merges into @file{~/.guix-home/profile/share/kak/autoload/}
;; via the KAKOUNE_RUNTIME native-search-path).
;;
;; Ships an extra @file{themes/night-owl.kak} to match our night-owl
;; colorscheme — upstream doesn't provide it.

(define-module (dotfiles packages powerline-kak)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix build-system trivial)
  #:use-module (guix gexp)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (powerline-kak))

;; Night Owl palette (matches kakoune-tree-sitter-themes' night-owl.kak).
;; Same 32-slot layout as upstream themes; only 00-15 are used.
(define %powerline-kak-night-owl-theme
  (plain-file
   "powerline-kak-night-owl.kak"
   "# Powerline colorscheme for Night Owl Kakoune theme
# Palette mirrors ~/.config/kak/colors/night-owl.kak.

hook global ModuleLoaded powerline %{ require-module powerline_night_owl }

provide-module powerline_night_owl %§
set-option -add global powerline_themes \"night-owl\"

define-command -hidden powerline-theme-night-owl %{ evaluate-commands %sh{
    bg=\"rgb:011627\"          # main background
    fg=\"rgb:d6deeb\"          # main foreground
    line=\"rgb:1d3b53\"        # selection / secondary bg
    cyan=\"rgb:7fdbca\"        # type / accent
    blue=\"rgb:82aaff\"        # function
    purple=\"rgb:c792ea\"      # keyword
    green=\"rgb:addb67\"       # type alt
    yellow=\"rgb:ecc48d\"      # string
    orange=\"rgb:f78c6c\"      # number

    printf '%s\\n' \"
        declare-option -hidden str powerline_color00 ${fg}      # fg: bufname
        declare-option -hidden str powerline_color01 ${line}    # bg: position
        declare-option -hidden str powerline_color02 ${cyan}    # fg: git
        declare-option -hidden str powerline_color03 ${line}    # bg: bufname
        declare-option -hidden str powerline_color04 ${bg}      # bg: git
        declare-option -hidden str powerline_color05 ${cyan}    # fg: position
        declare-option -hidden str powerline_color06 ${blue}    # fg: line-column
        declare-option -hidden str powerline_color07 ${purple}  # fg: mode-info
        declare-option -hidden str powerline_color08 ${bg}      # base background
        declare-option -hidden str powerline_color09 ${line}    # bg: line-column
        declare-option -hidden str powerline_color10 ${green}   # fg: filetype
        declare-option -hidden str powerline_color11 ${line}    # bg: filetype
        declare-option -hidden str powerline_color12 ${line}    # bg: client
        declare-option -hidden str powerline_color13 ${yellow}  # fg: client
        declare-option -hidden str powerline_color14 ${blue}    # bg: session
        declare-option -hidden str powerline_color15 ${bg}      # fg: session
        declare-option -hidden str powerline_color16 ${fg}      # unused
        declare-option -hidden str powerline_color17 ${bg}      # unused
        declare-option -hidden str powerline_color18 ${cyan}    # unused
        declare-option -hidden str powerline_color19 ${bg}      # unused
        declare-option -hidden str powerline_color20 ${line}    # unused
        declare-option -hidden str powerline_color21 ${cyan}    # unused
        declare-option -hidden str powerline_color22 ${cyan}    # unused
        declare-option -hidden str powerline_color23 ${cyan}    # unused
        declare-option -hidden str powerline_color24 ${bg}      # unused
        declare-option -hidden str powerline_color25 ${line}    # unused
        declare-option -hidden str powerline_color26 ${cyan}    # unused
        declare-option -hidden str powerline_color27 ${line}    # unused
        declare-option -hidden str powerline_color28 ${bg}      # unused
        declare-option -hidden str powerline_color29 ${cyan}    # unused
        declare-option -hidden str powerline_color30 ${cyan}    # unused
        declare-option -hidden str powerline_color31 ${line}    # unused

        declare-option -hidden str powerline_next_bg %opt{powerline_color08}
        declare-option -hidden str powerline_base_bg %opt{powerline_color08}
    \"
}}

§
"))

(define-public powerline-kak
  (package
    (name "powerline-kak")
    (version "0.0.0-1.299be5e")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/andreyorst/powerline.kak")
             (commit "299be5ef1b977a3e37238271dd35c6a3d9cd2e3d")))
       (file-name (string-append name "-" version "-checkout"))
       (sha256
        (base32 "0jg5i658icqvd1bab0sxyim3dw1cff97q176dnqp7s8fvxyrrfvd"))))
    (build-system trivial-build-system)
    (arguments
     (list
      #:modules '((guix build utils))
      #:builder
      #~(begin
          (use-modules (guix build utils))
          (let* ((src (assoc-ref %build-inputs "source"))
                 (out (assoc-ref %outputs "out"))
                 (autoload
                  (string-append out "/share/kak/autoload/powerline")))
            (mkdir-p autoload)
            (copy-recursively (string-append src "/rc") autoload)
            (copy-file #$%powerline-kak-night-owl-theme
                       (string-append autoload "/themes/night-owl.kak"))))))
    (home-page "https://github.com/andreyorst/powerline.kak")
    (synopsis "Powerline-style modeline plugin for Kakoune")
    (description
     "Modeline plugin for Kakoune providing modules for git branch, LSP
diagnostics, filetype, editor mode, cursor position, and session/client info,
rendered with powerline-style separators.  Requires a Powerline/Nerd font in
the terminal.")
    (license license:expat)))
