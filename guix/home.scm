(use-modules 
 (gnu)
 (gnu home)
 (gnu home services)
 (gnu home services dotfiles)
 (gnu home services shells)
 (gnu home services shepherd)
 (gnu home services ssh)
 (gnu packages base)
 (gnu packages bash)
 (gnu packages wget)
 (gnu packages nss)
 (gnu packages version-control)
 (gnu packages shells)
 (gnu packages base)
 (gnu packages emacs)
 (gnu packages terminals)
 (gnu packages text-editors)
 (gnu packages shellutils)
 (gnu packages ncurses)
 (gnu packages rust-apps)
 (gnu packages less)
 (gnu packages compression)
 (guix packages)
 (srfi srfi-1)
 (packages omz)
 (packages doom))

(define main-packages (list ripgrep 
                            git
                            emacs-no-x 
                            glibc-locales
                            fzf 
                            fzf-tab 
                            micro
                            unzip
                            direnv
                            zoxide))
(define dev-packages (if (getenv "TEST") 
                         (list less 
                               bash 
                               wget 
                               nss-certs 
                               ncurses 
                               libiconv) 
                         '()))

(define (make-zsh-snippet-for npkg file-name snippet)
  (let ((has-package? (any
                       (lambda (pkg) (string=? (package-name pkg) (package-name npkg)))
                       main-packages)))
    (if has-package?
        (list (plain-file file-name
                          snippet))
        '())))

(home-environment
 (packages (append main-packages dev-packages))
 (services (list
            ;; Dotfiles configuration
            (service home-dotfiles-service-type (home-dotfiles-configuration
                                                 (directories '("../../dotfiles"))))
            ;; Shepherd services
            (simple-service 'emacs-daemon
                            home-shepherd-service-type
                            (list (shepherd-service
                                   (provision '(emacs-daemon))
                                   (documentation "Personal Emacs daemon")
                                   (start #~(make-forkexec-constructor
                                             (list #$(file-append emacs-no-x "/bin/emacs")
                                                   "--fg-daemon=personal")))
                                   (stop #~(make-kill-destructor))
                                   (respawn? #t))))
            ;; SSH configuration
            (service home-openssh-service-type
                     (home-openssh-configuration
                      (hosts
                       (list (openssh-host (name "me.github.com")
                                           (host-name "github.com")
                                           (user "michaelnelo66@outlook.com")
                                           (identity-file "~/.ssh/personal.github.id_ed25519"))))))
            ;; Doom emacs configuration
            (simple-service 'doom-emacs-installation
                            home-activation-service-type
                            #~(let ((doom-path (string-append #$doom "/share/doom-emacs"))
                                    (emacs-path (string-append #$emacs-no-x "/bin/"))
                                    (git-path (string-append #$git "/bin/"))
                                    (sh-path (string-append #$bash "/bin/"))
                                    (doom-dir (string-append (getenv "HOME") "/.config/emacs"))
                                    (doom-local (string-append (getenv "HOME") "/.config/emacs/.local"))
                                    (ca-path (string-append #$nss-certs "/etc/ssl/certs/")))              
                                (unless (file-exists? doom-local)
                                  (copy-recursively doom-path doom-dir)
                                  (setenv "PATH" (string-append git-path 
                                                                ":" 
                                                                emacs-path 
                                                                ":" 
                                                                sh-path 
                                                                ":" 
                                                                (getenv "PATH")))
                                  (setenv "GIT_SSL_CAPATH" ca-path)
                                  (setenv "SSL_CERT_DIR" ca-path)
                                  (system* #$(file-append bash "/bin/sh")
                                           (string-append doom-dir "/bin/doom")
                                           "install"
                                           "--verbose")
                                  (system* #$(file-append bash "/bin/sh")
                                           (string-append doom-dir "/bin/doom")
                                           "sync"))))
            ;; Shell configuration
            (service home-zsh-service-type (home-zsh-configuration
                                            (zprofile  (append (make-zsh-snippet-for
                                                                zoxide
                                                                "init-zoxide.zsh"
                                                                "eval \"$(zoxide init zsh)\"")
                                                               (make-zsh-snippet-for
                                                                direnv
                                                                "init-direnv.zsh"
                                                                "eval \"$(direnv hook zsh)\"")))
                                                       (environment-variables `(("ZSH"          .  ,(file-append omz "/share/oh-my-zsh"))
                                                                                ("SHELL"        .  ,(file-append zsh "/bin/zsh"))
                                                                                ("GUIX_LOCPATH" .  "$HOME/.guix-home/profile/lib/locale"))))))))
