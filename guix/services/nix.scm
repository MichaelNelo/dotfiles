(define-module (services nix)
  #:use-module (guix gexp)
  #:use-module (gnu services)
  #:use-module (gnu home services)
  #:use-module (gnu packages package-management)
  #:export (%devenv-install))

(define %devenv-install
  (simple-service 'devenv-install home-activation-service-type
                  #~(let* ((bin (string-append (getenv "HOME")
                                               "/.nix-profile/bin/devenv"))
                           (nix-bin #$(file-append nix "/bin/nix"))
                           (nix-store-bin #$(file-append nix
                                                         "/bin/nix-store")))
                      ;; Sin /nix/var/nix preexistente, nix 2.25 hace fallback
                      ;; silencioso a chroot store y los install fallan con
                      ;; "directory iterator cannot open directory". Pre-creamos
                      ;; la estructura mínima del store nativo.
                      (when (file-exists? "/nix")
                        (mkdir-p "/nix/store")
                        (mkdir-p "/nix/var/nix/db")
                        (mkdir-p "/nix/var/nix/profiles")
                        (mkdir-p "/nix/var/nix/gcroots")
                        ;; Inicializa la DB del store si no existe (idempotente).
                        (unless (file-exists? "/nix/var/nix/db/db.sqlite")
                          (format #t "Initializing nix store database...~%")
                          (invoke nix-store-bin "--init")))
                      (unless (file-exists? bin)
                        (format #t
                                "Installing devenv via nix profile (first run, may take a few minutes)...~%")
                        (invoke nix-bin
                                "profile"
                                "install"
                                "nixpkgs#devenv"
                                "--accept-flake-config"
                                "--extra-experimental-features"
                                "nix-command flakes")))))
