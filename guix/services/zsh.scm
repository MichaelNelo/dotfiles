(define-module (services zsh)
  #:use-module (srfi srfi-1)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (gnu services)
  #:use-module (gnu home services)
  #:use-module (gnu home services shells)
  #:use-module (gnu packages rust-apps)
  #:use-module (gnu packages shellutils)
  #:use-module (gnu packages shells)
  #:use-module (gnu packages commencement)
  #:use-module (packages omz)
  #:export (zsh-service))

(define (make-zsh-snippet-for main-packages npkg file-name snippet)
  (let ((has-package? (any (lambda (pkg)
                             (string=? (package-name pkg)
                                       (package-name npkg))) main-packages)))
    (if has-package?
        (list (plain-file file-name snippet))
        '())))

(define (zsh-service main-packages)
  (service home-zsh-service-type
           (home-zsh-configuration (zprofile (append (make-zsh-snippet-for
                                                      main-packages zoxide
                                                      "init-zoxide.zsh"
                                                      "eval \"$(zoxide init zsh)\"")
                                                     (make-zsh-snippet-for
                                                      main-packages direnv
                                                      "init-direnv.zsh"
                                                      "eval \"$(direnv hook zsh)\"")
                                                     (list (plain-file
                                                            "make-npm-global-prefix.zsh"
                                                            "
if [[ ! -d \"$HOME/.npm-global\" ]] then
    mkdir \"$HOME/.npm-global\"
fi

npm config set prefix $HOME/.npm-global
"))))
                                   (environment-variables `(("ZSH" unquote
                                                             (file-append omz
                                                              "/share/oh-my-zsh"))
                                                            ("SHELL" unquote
                                                             (file-append zsh
                                                              "/bin/zsh"))
                                                            ("GUIX_LOCPATH" . "$HOME/.guix-home/profile/lib/locale")
                                                            ("CC" unquote
                                                             (file-append
                                                              gcc-toolchain
                                                              "/bin/gcc"))
                                                            ("GIT_SSL_CAPATH" . "/etc/ssl/certs")
                                                            ("EDITOR" . "nvim")
                                                            ("OPENCODE_ENABLE_EXA" . "1")
                                                            ("SSL_CERT_DIR" . "/etc/ssl/certs")
                                                            ("LD_LIBRARY_PATH" . "/usr/lib/wsl/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}")
                                                            ("ZELLIJ_CONFIG_DIR" . "$HOME/dotfiles/.config/zellij")
                                                            ("YAZI_CONFIG_HOME" . "$HOME/dotfiles/.config/yazi")
                                                            ("PATH" . "$HOME/.local/bin:$HOME/.npm-global/bin:$PATH"))))))
