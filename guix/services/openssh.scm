(define-module (services openssh)
  #:use-module (gnu services)
  #:use-module (gnu home services ssh)
  #:export (%openssh-service))

(define %openssh-service
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
                                                                  (control-master 'ask)))))))
