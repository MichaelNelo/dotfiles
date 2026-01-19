(define-module (services zsh)
  #:use-module (gnu home services)
  #:use-module (gnu home services shells)
  #:use-module (gnu packages shells)
  #:use-module (guix gexp)
  #:use-module (packages omz)
  #:export (%zsh-environment-variables
            %zsh-zprofile
            %zsh-service
            make-zsh-service))

;; Default environment variables for ZSH
(define %zsh-environment-variables
  `(("ZDOTDIR"        . "$HOME/.config/zsh")
    ("ZSH"            . ,(file-append omz "/share/oh-my-zsh"))
    ("SHELL"          . ,(file-append zsh "/bin/zsh"))
    ("GUIX_LOCPATH"   . "$HOME/.guix-home/profile/lib/locale")
    ("GIT_SSL_CAPATH" . "/etc/ssl/certs")
    ("SSL_CERT_DIR"   . "/etc/ssl/certs")
    ("PATH"           . "$HOME/.npm-global/bin:$PATH")))

;; Default zprofile scripts
(define %zsh-zprofile
  (list (plain-file "npm-global-prefix.zsh"
                    "
if [[ ! -d \"$HOME/.npm-global\" ]]; then
    mkdir \"$HOME/.npm-global\"
fi

npm config set prefix $HOME/.npm-global
")
        (plain-file "direnv-init.zsh"
                    "
eval \"$(direnv hook zsh)\"
")
        (plain-file "zoxide-init.zsh"
                    "
eval \"$(zoxide init zsh)\"
")))

;; Default ZSH service
(define %zsh-service
  (service home-zsh-service-type
           (home-zsh-configuration
            (zprofile %zsh-zprofile)
            (environment-variables %zsh-environment-variables))))

;; Factory function to create ZSH service with custom configuration
(define* (make-zsh-service #:key
                           (environment-variables %zsh-environment-variables)
                           (zprofile %zsh-zprofile))
  (service home-zsh-service-type
           (home-zsh-configuration
            (zprofile zprofile)
            (environment-variables environment-variables))))
