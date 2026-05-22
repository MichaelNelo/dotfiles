(define-module (services dotfiles)
  #:use-module (gnu home)
  #:use-module (gnu home services)
  #:use-module (gnu home services dotfiles)
  #:export     (%dotfiles-service))

(define %dotfiles-service
  (service home-dotfiles-service-type
           (home-dotfiles-configuration (directories '("../../../dotfiles")))))
