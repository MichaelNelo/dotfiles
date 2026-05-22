(define-module (dotfiles services ssh)
  #:use-module (gnu home services)
  #:use-module (gnu home services ssh)
  #:export (%ssh-hosts %ssh-service make-ssh-service))

;; Default SSH hosts configuration
(define %ssh-hosts
  (list (openssh-host (name "me.github.com")
                      (host-name "github.com")
                      (user "michaelnelo66@outlook.com")
                      (identity-file "~/.ssh/personal.github.id_ed25519"))
        (openssh-host (name "local.zo.eva")
                      (host-name "192.168.1.2")
                      (port 2222)
                      (user "mknelo")
                      (identity-file "~/.ssh/eva.personal.id_dropbear"))))

;; Default SSH service with predefined hosts
(define %ssh-service
  (service home-openssh-service-type
           (home-openssh-configuration (hosts %ssh-hosts))))

;; Factory function to create SSH service with custom/additional hosts
(define* (make-ssh-service #:key (hosts %ssh-hosts))
  (service home-openssh-service-type
           (home-openssh-configuration (hosts hosts))))
