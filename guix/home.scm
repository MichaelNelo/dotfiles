(use-modules (gnu)
             (gnu home)
             (gnu home services)
             (gnu home services dotfiles)
             (gnu home services guix)
             (gnu home services shells)
             (gnu home services shepherd)
             (gnu home services ssh)
             (gnu packages version-control)
             (gnu packages ssh)
             (gnu packages freedesktop)
             (gnu packages base)
             (gnu packages bash)
             (gnu packages wget)
             (gnu packages nss)
             (gnu packages shells)
             (gnu packages pkg-config)
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
             (gnu packages commencement)
             (gnu packages cmake)
             (gnu packages lsof)
             (gnu packages curl)
             (gnu packages autotools)
             (gnu packages llvm)
             (guix packages)
             (guix channels)
             (srfi srfi-1)
             (packages omz)
             (packages opencode)
             (packages nvchad)
             (packages mise)
             (packages llama-cpp)
             (packages claude-code)
             (packages ollama)
             (packages lazygit)
             (packages zellij)
             (packages nvr)
             (packages yazi)
             (services ollama))

(define main-packages
  ;; Terminal tools
  (list less
        (specification->package "file")
        xdg-utils
        ripgrep
        ;; Editors
        micro
        ;; AI Tools
        claude-code
        opencode
        ollama
        llama-cpp-4f13cb
        ;; Editor/Shell Tools
        omz
        nvchad
        (specification->package "neovim")
        lsof
        ;; Compression
        unzip
        (specification->package "zstd")
        ;; Build Tools
        gnu-make
        libtool
        cmake
        gcc-toolchain
        llvm
        glibc
        patchelf
        pkg-config
        glibc-locales
        ;; Networking
        curl
        openssh
        dropbear
        ;; Dev Tools
        git
        mise
        node
        lazygit
        zellij
        nvr
        yazi
        direnv
        zoxide
        fzf
        fzf-tab
        (specification->package "sqlite")
        (specification->package "man-db")
        (specification->package "octave-cli")
        (specification->package "tree-sitter")
        (specification->package "tree-sitter-cli")))

(define dev-packages
  (if (getenv "TEST")
      (list bash wget nss-certs ncurses libiconv)
      '()))

(define (make-zsh-snippet-for npkg file-name snippet)
  (let ((has-package? (any (lambda (pkg)
                             (string=? (package-name pkg)
                                       (package-name npkg))) main-packages)))
    (if has-package?
        (list (plain-file file-name snippet))
        '())))

(home-environment
  (packages (append main-packages dev-packages))
  (services
   (list
    ;; Dotfiles configuration
    (service home-dotfiles-service-type
             (home-dotfiles-configuration (directories '("../../dotfiles"))))
    (simple-service 'gcc-to-cc-symlink home-activation-service-type
                    #~(begin
                        (use-modules (guix build utils))

                        (let ((bin-dir (string-append (getenv "HOME")
                                                      "/.local/bin"))
                              (gcc-bin #$(file-append gcc-toolchain "/bin/gcc")))
                          (let ((cc-link (string-append bin-dir "/cc")))
                            (mkdir-p bin-dir)
                            (when (file-exists? cc-link)
                              (delete-file cc-link))
                            (symlink gcc-bin cc-link)))))
    ;; Shepherd services
    (simple-service 'ollama-server home-shepherd-service-type
                    (list ollama-shepherd-service))
    ;; SSH configuration
    (service home-openssh-service-type
             (home-openssh-configuration (hosts (list (openssh-host (name
                                                                     "me.github.com")
                                                                    (host-name
                                                                     "github.com")
                                                                    (user
                                                                     "michaelnelo66@outlook.com")
                                                                    (identity-file
                                                                     "~/.ssh/personal.github.id_ed25519")
                                                                    (control-master 'ask))
                                                      (openssh-host (name
                                                                     "flush.github.com")
                                                                    (host-name
                                                                     "github.com")
                                                                    (user
                                                                     "michael@flush.com")
                                                                    (identity-file
                                                                     "~/.ssh/flush.github.id_ed25519")
                                                                    (control-master 'ask))))))
    (simple-service 'ssh-host-keys-setup home-activation-service-type
                    #~(let ((key-file (string-append (getenv "HOME")
                                       "/.ssh/dropbear_rsa_host_key"))
                            (dropbearkey #$(file-append dropbear
                                                        "/bin/dropbearkey")))
                        (unless (file-exists? key-file)
                          (format #t "Generating ssh server key...~%")
                          (invoke dropbearkey "-t" "rsa" "-f" key-file))))
    (simple-service 'ssh-client-keys-setup home-activation-service-type
                    #~(begin
                        (use-modules (ice-9 textual-ports))
                        (let* ((key-file (string-append (getenv "HOME")
                                                        "/.ssh/id_dropbear"))
                               (authorized-keys (string-append (getenv "HOME")
                                                 "/.ssh/authorized_keys"))
                               (ssh-keygen #$(file-append openssh
                                                          "/bin/ssh-keygen"))
                               (pubkey-file (string-append key-file ".pub"))
                               (zsh-shell #$(file-append zsh "/bin/zsh")))
                          (mkdir-p (string-append (getenv "HOME") "/.ssh"))
                          (unless (file-exists? key-file)
                            (format #t "Generating client ssh key...~%")
                            (invoke ssh-keygen
                                    "-t"
                                    "rsa"
                                    "-b"
                                    "4096"
                                    "-f"
                                    key-file
                                    "-N"
                                    ""
                                    "-C"
                                    "guix-home-generated"))
                          (let ((pubkey-contents (call-with-input-file pubkey-file
                                                   (lambda (port)
                                                     (get-string-all port))))
                                (current-keys (if (file-exists?
                                                   authorized-keys)
                                                  (call-with-input-file authorized-keys
                                                    (lambda (port)
                                                      (get-string-all port)))
                                                  "")))
                            (let ((wrapper-script (string-append (getenv
                                                                  "HOME")
                                                   "/.ssh/ssh-shell-wrapper.sh")))
                              ;; Crear el script wrapper
                              (call-with-output-file wrapper-script
                                (lambda (port)
                                  (display (string-append "#!"
                                            #$(file-append bash "/bin/bash")
                                            "\n"
                                            "# Configurar PATH con binarios de Guix\n"
                                            "export PATH=\"$HOME/.guix-home/profile/bin:$HOME/.guix-home/profile/libexec:$PATH\"
"
                                            "\n"
                                            "if [ -z \"$SSH_ORIGINAL_COMMAND\" ]; then\n"
                                            "    exec "
                                            zsh-shell
                                            " -i -l\n"
                                            "else\n"
                                            "    CMD=\"$SSH_ORIGINAL_COMMAND\"\n"
                                            "    # Extraer el primer word (el binario)
"
                                            "    FIRST_WORD=\"${CMD%% *}\"\n"
                                            "    # Si es ruta absoluta que no existe, buscar por nombre en PATH
"
                                            "    if [[ \"$FIRST_WORD\" == /* ]] && [[ ! -x \"$FIRST_WORD\" ]]; then
"
                                            "        BASENAME=\"$(basename \"$FIRST_WORD\")\"
"
                                            "        REAL_PATH=\"$(command -v \"$BASENAME\" 2>/dev/null)\"
"
                                            "        if [[ -n \"$REAL_PATH\" ]]; then\n"
                                            "            CMD=\"${CMD/\"$FIRST_WORD\"/\"$REAL_PATH\"}\"
"
                                            "        fi\n"
                                            "    fi\n"
                                            "    eval \"$CMD\"\n"
                                            "fi\n") port)))
                              (chmod wrapper-script #o755)
                              ;; Agregar la llave con command= apuntando al wrapper
                              (unless (string-contains current-keys
                                                       "guix-home-generated")
                                (format #t
                                 "Adding client key to authorized_keys")
                                (call-with-output-file authorized-keys
                                  (lambda (port)
                                    (display current-keys port)
                                    (display (string-append "command=\""
                                                            wrapper-script
                                                            "\" "
                                                            (string-trim-right
                                                             pubkey-contents))
                                             port)
                                    (newline port)))
                                (chmod authorized-keys #o600)))))))
    (simple-service 'dopbear-ssh-server home-shepherd-service-type
                    (list (shepherd-service (provision '(ssh-server))
                                            (documentation "SSH server")
                                            (start #~(make-forkexec-constructor
                                                      (list #$(file-append
                                                               dropbear
                                                               "/sbin/dropbear")
                                                            "-F"
                                                            "-E"
                                                            "-p"
                                                            "2222"
                                                            "-r"
                                                            (string-append (getenv
                                                                            "HOME")
                                                             "/.ssh/dropbear_rsa_host_key")
                                                            "-s"
                                                            "-w")))
                                            (stop #~(make-kill-destructor
                                                     SIGKILL))
                                            (respawn? #f))))
    ;; Channels configuration
    (simple-service 'my-channels-service-type home-channels-service-type
                    (cons* (channel
                             (name 'rustup)
                             (url
                              "https://github.com/declantsien/guix-rustup.git"))
                           (channel
                             (name 'guix-science-nonfree)
                             (url
                              "https://codeberg.org/guix-science/guix-science-nonfree.git")
                             (introduction
                              (make-channel-introduction
                               "58661b110325fd5d9b40e6f0177cc486a615817e"
                               (openpgp-fingerprint
                                "CA4F 8CF4 37D7 478F DA05  5FD4 4213 7701 1A37 8446"))))
                           %default-channels))
    ;; Shell configuration
    (service home-zsh-service-type
             (home-zsh-configuration (zprofile (append (make-zsh-snippet-for
                                                        zoxide
                                                        "init-zoxide.zsh"
                                                        "eval \"$(zoxide init zsh)\"")
                                                       (make-zsh-snippet-for
                                                        direnv
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
                                                               (file-append
                                                                omz
                                                                "/share/oh-my-zsh"))
                                                              ("SHELL" unquote
                                                               (file-append
                                                                zsh "/bin/zsh"))
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
                                                              ("PATH" . "$HOME/.local/bin:$HOME/.npm-global/bin:$PATH"))))))))
