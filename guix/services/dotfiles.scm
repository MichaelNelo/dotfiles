(define-module (services dotfiles)
  #:use-module (gnu home services)
  #:use-module (gnu home services dotfiles)
  #:export (%dotfiles-service
            make-dotfiles-service))

;; Default dotfiles service pointing to ../../dotfiles relative to guix/
(define %dotfiles-service
  (service home-dotfiles-service-type
           (home-dotfiles-configuration
            (directories '("../../dotfiles")))))

;; Factory function to create dotfiles service with custom directories
(define* (make-dotfiles-service #:key (directories '("../../dotfiles")))
  (service home-dotfiles-service-type
           (home-dotfiles-configuration
            (directories directories))))
