(define-module (services activation)
  #:use-module (guix build utils)
  #:use-module (guix gexp)
  #:use-module (gnu services)
  #:use-module (gnu home services)
  #:use-module (gnu packages commencement)
  #:use-module (gnu packages ssh)
  #:use-module (gnu packages shells)
  #:use-module (gnu packages bash)
  #:export     (%gcc-activation %ssh-host-keys-setup %ssh-client-keys-setup))

(define %gcc-activation
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
                          (symlink gcc-bin cc-link))))))

(define %ssh-host-keys-setup
  (simple-service 'ssh-host-keys-setup home-activation-service-type
                  #~(let ((key-file (string-append (getenv "HOME")
                                                   "/.ssh/dropbear_rsa_host_key"))
                        (dropbearkey #$(file-append dropbear "/bin/dropbearkey")))
                    (unless (file-exists? key-file)
                      (format #t "Generating ssh server key...~%")
                      (invoke dropbearkey "-t" "rsa" "-f" key-file)))))

(define %ssh-client-keys-setup
  (simple-service 'ssh-client-keys-setup home-activation-service-type
                  #~(begin
                      (use-modules (ice-9 textual-ports))
                      (let* ((key-file (string-append (getenv "HOME")
                                                       "/.ssh/id_dropbear"))
                             (authorized-keys (string-append (getenv "HOME")
                                                             "/.ssh/authorized_keys"))
                             (ssh-keygen #$(file-append openssh "/bin/ssh-keygen"))
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
                              (current-keys (if (file-exists? authorized-keys)
                                                (call-with-input-file authorized-keys
                                                  (lambda (port)
                                                    (get-string-all port)))
                                                "")))
                          (let ((wrapper-script (string-append (getenv "HOME")
                                                               "/.ssh/ssh-shell-wrapper.sh")))
                            (call-with-output-file wrapper-script
                              (lambda (port)
                                (display (string-append "#!"
                                                        #$(file-append bash "/bin/bash")
                                                        "\n"
                                                        "# Configurar PATH con binarios de Guix\n"
                                                        "export PATH=\"$HOME/.guix-home/profile/bin:$HOME/.guix-home/profile/libexec:$PATH\"\n"
                                                        "if [ -z \"$SSH_ORIGINAL_COMMAND\" ]; then\n"
                                                        (string-append "    exec " zsh-shell " -i -l\n")
                                                        "else\n"
                                                        "    CMD=\"$SSH_ORIGINAL_COMMAND\"\n"
                                                        "    # Extraer el primer word (el binario)\n"
                                                        "    FIRST_WORD=\"${CMD%% *}\"\n"
                                                        "    # Si es ruta absoluta que no existe, buscar por nombre en PATH\n"
                                                        "    if [[ \"$FIRST_WORD\" == /* ]] && [[ ! -x \"$FIRST_WORD\" ]]; then\n"
                                                        "        BASENAME=$(basename \"$FIRST_WORD\")\n"
                                                        "        REAL_PATH=$(command -v \"$BASENAME\" 2>/dev/null)\n"
                                                        "        if [[ -n \"$REAL_PATH\" ]]; then\n"
                                                        "            CMD=\"${CMD/\"$FIRST_WORD\"/\"$REAL_PATH\"}\"\n"
                                                        "        fi\n"
                                                        "    fi\n"
                                                        "    eval \"$CMD\"\n"
                                                        "fi\n") port)))
                            (chmod wrapper-script #o755)
                            (unless (string-contains current-keys
                                                     "guix-home-generated")
                              (format #t "Adding client key to authorized_keys")
                              (call-with-output-file authorized-keys
                                (lambda (port)
                                  (display current-keys port)
                                  (display (string-append "command=\""
                                                          wrapper-script
                                                          "\" "
                                                          (string-trim-right
                                                           pubkey-contents))
                                           port)
                                  (newline port))))
                              (chmod authorized-keys #o600)))))))
