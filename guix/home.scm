(use-modules 
 (gnu)
 (gnu home)
 (gnu home services)
 (gnu home services dotfiles)
 (gnu home services guix)
 (gnu home services shells)
 (gnu home services shepherd)
 (gnu home services ssh)
 (gnu packages ssh)
 (gnu packages base)
 (gnu packages bash)
 (gnu packages wget)
 (gnu packages nss)
 (gnu packages version-control)
 (gnu packages shells)
 (gnu packages base)
 (gnu packages emacs)
 (gnu packages node)
 (gnu packages terminals)
 (gnu packages text-editors)
 (gnu packages shellutils)
 (gnu packages ncurses)
 (gnu packages rust-apps)
 (gnu packages less)
 (gnu packages elf)
 (gnu packages compression)
 (guix packages)
 (guix channels)
 (srfi srfi-1)
 (packages omz))

(define main-packages (list less
                            ripgrep
                            git
                            emacs-no-x 
                            glibc-locales
                            fzf 
                            fzf-tab 
                            micro
                            unzip
                            direnv
                            zoxide
                            patchelf
                            openssh
                            omz
                            node))
(define dev-packages (if (getenv "TEST") 
                         (list bash 
                               wget 
                               nss-certs 
                               ncurses 
                               libiconv) 
                         '()))

(home-environment
 (packages (append main-packages dev-packages))
 (services (list
            ;; Dotfiles configuration
            (service home-dotfiles-service-type (home-dotfiles-configuration
                                                 (directories '("../../dotfiles"))))
            ;; SSH configuration
            (service home-openssh-service-type
                     (home-openssh-configuration
                      (hosts
                       (list (openssh-host (name "local.zo.eva")
                             			   (host-name "192.168.1.2")
                             			   (user "mknelo")
                             			   (identity-file "~/.ssh/eva.personal.id_dropbear"))))))
            ;; Shell configuration
            (service home-zsh-service-type (home-zsh-configuration
                                            (zprofile  (append (list (plain-file "make-npm-global-prefix.zsh"
                                                                                 "
if [[ ! -d \"$HOME/.npm-global\" ]] then
    mkdir \"$HOME/.npm-global\"
fi

npm config set prefix $HOME/.npm-global
                                                                                 "))))
                                            (environment-variables `(("ZSH"            .  ,(file-append omz "/share/oh-my-zsh"))
                                                                     ("SHELL"          .  ,(file-append zsh "/bin/zsh"))
                                                                     ("GUIX_LOCPATH"   .  "$HOME/.guix-home/profile/lib/locale")
                                                                     ("GIT_SSL_CAPATH" .  "/etc/ssl/certs")
                                                                     ("SSL_CERT_DIR"   .  "/etc/ssl/certs")
                                                                     ("PATH"           .  "$HOME/.npm-global/bin:$PATH"))))))))
