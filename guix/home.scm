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
 (gnu packages disk)
 (gnu packages compression)
 (guix packages)
 (guix channels)
 (srfi srfi-1)
 (packages omz)
 (packages doom)
 (packages claude-code))

(define main-packages (list less
                            ranger
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
                            claude-code
                            doom
                            omz
                            openssh
                            dropbear
                            node))
(define dev-packages (if (getenv "TEST") 
                         (list bash 
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
                                                   "--fg-daemon=personal")
                                             #:environment-variables
                                             (let ((home (getenv "HOME")))
                                               (append (environ)
                                                       (list (string-append "DOOMDIR=" home "/.config/doom")
                                                             (string-append "EMACSDIR=" home "/.config/emacs"))))))
                                   (stop #~(make-kill-destructor SIGKILL))
                                   (respawn? #f))))
            ;; SSH configuration
            (service home-openssh-service-type
                     (home-openssh-configuration
                      (hosts
                       (list (openssh-host (name "me.github.com")
                                           (host-name "github.com")
                                           (user "michaelnelo66@outlook.com")
                                           (identity-file "~/.ssh/personal.github.id_ed25519"))
                             (openssh-host (name "flush.github.com")
                                           (host-name "github.com")
                                           (user "michael@flush.com")
                                           (identity-file "~/.ssh/flush.github.id_ed25519"))))))
            (simple-service 'ssh-host-keys-setup
                home-activation-service-type
                #~(let ((key-file (string-append (getenv "HOME") 
                                                "/.ssh/dropbear_rsa_host_key"))
                        (dropbearkey #$(file-append dropbear "/bin/dropbearkey")))
                    (unless (file-exists? key-file)
                      (format #t "Generating ssh server key...~%")
                      (invoke dropbearkey "-t" "rsa" "-f" key-file))))
            (simple-service 'ssh-client-keys-setup
                home-activation-service-type
                #~(begin
                    (use-modules (ice-9 textual-ports))
                    (let* ((key-file (string-append (getenv "HOME") "/.ssh/id_dropbear"))
                        (authorized-keys (string-append (getenv "HOME") "/.ssh/authorized_keys"))
                        (ssh-keygen #$(file-append openssh "/bin/ssh-keygen"))
                        (pubkey-file (string-append key-file ".pub")))
                    (mkdir-p (string-append (getenv "HOME") "/.ssh"))
                    (unless (file-exists? key-file)
                      (format #t "Generating client ssh key...~%")
                      (invoke ssh-keygen 
                              "-t" "rsa"
                              "-b" "4096"
                              "-f" key-file
                              "-N" ""
                              "-C" "guix-home-generated"))
                    (let ((pubkey-contents (call-with-input-file pubkey-file (lambda (port) (get-string-all port))))
                          (current-keys (if (file-exists? authorized-keys) (call-with-input-file authorized-keys (lambda (port) (get-string-all port))) "")))
                      (unless (string-contains current-keys "guix-home-generated")
                        (format #t "Adding client key to authorized_keys")
                        (call-with-output-file authorized-keys
                                               (lambda (port)
                                                 (display current-keys port)
                                                 (display pubkey-contents port)
                                                 (newline port)))
                        (chmod authorized-keys #o600))))))
            (simple-service 'dopbear-ssh-server
                            home-shepherd-service-type
                            (list (shepherd-service
                                   (provision '(ssh-server))
                                   (documentation "SSH server")
                                   (start #~(make-forkexec-constructor
                                             (list #$(file-append dropbear "/sbin/dropbear")
                                                   "-F"
                                                   "-E"
                                                   "-p" "2222"
                                                   "-r" (string-append (getenv "HOME") 
                                                                       "/.ssh/dropbear_rsa_host_key")
                                                   "-s"
                                                   "-w"))) 
                                   (stop #~(make-kill-destructor SIGKILL))
                                   (respawn? #f))))
            ;; Doom emacs configuration
            (simple-service 'doom-emacs-installation
                            home-activation-service-type
                            #~(let ((doom-path (string-append #$doom "/share/doom-emacs"))
                                    (emacs-path (string-append #$emacs-no-x "/bin/"))
                                    (git-path (string-append #$git "/bin/"))
                                    (sh-path (string-append #$bash "/bin/"))
                                    (doom-dir (string-append (getenv "HOME") "/.config/emacs"))
                                    (doom-local (string-append (getenv "HOME") "/.config/emacs/.local"))
                                    (ca-path (if (getenv "TEST") (string-append #$nss-certs "/etc/ssl/certs/") "/etc/ssl/certs")))              
                                (unless (file-exists? doom-local)
                                  (copy-recursively doom-path doom-dir)
                                  (setenv "PATH" (string-append git-path 
                                                                ":" 
                                                                emacs-path 
                                                                ":" 
                                                                sh-path 
                                                                ":" 
                                                                (getenv "PATH")))
                                  (setenv "EMACSDIR" (string-append (getenv "HOME") "/.config/emacs"))
                                  (setenv "DOOMDIR" (string-append (getenv "HOME") "/.config/doom"))                                
                                  (setenv "GIT_SSL_CAPATH" ca-path)
                                  (setenv "SSL_CERT_DIR" ca-path)
                                  (system* #$(file-append bash "/bin/sh")
                                           (string-append doom-dir "/bin/doom")
                                           "install"
                                           "--verbose")
                                  (system* #$(file-append bash "/bin/sh")
                                           (string-append doom-dir "/bin/doom")
                                           "sync"))))
            ;; Channels configuration
            (simple-service 'my-channels-service-type
                            home-channels-service-type (cons* (channel
                                                               (name 'rustup)
                                                               (url "https://github.com/declantsien/guix-rustup.git"))
                                                              %default-channels))
            ;; Shell configuration
            (service home-zsh-service-type (home-zsh-configuration
                                            (zprofile  (append (make-zsh-snippet-for
                                                                zoxide
                                                                "init-zoxide.zsh"
                                                                "eval \"$(zoxide init zsh)\"")
                                                               (make-zsh-snippet-for
                                                                direnv
                                                                "init-direnv.zsh"
                                                                "eval \"$(direnv hook zsh)\"")
                                                               (list (plain-file "make-npm-global-prefix.zsh"
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
