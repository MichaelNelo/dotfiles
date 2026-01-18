(define-module (services dotfiles)
  #:use-module (gnu home services)
  #:use-module (gnu home services dotfiles)
  #:export (%dotfiles-service
            make-dotfiles-service))

;; Default dotfiles service pointing to parent directory (dotfiles_client root)
;; This will copy .config/* to ~/.config/*
(define %dotfiles-service
  (service home-dotfiles-service-type
           (home-dotfiles-configuration
            (directories '("..")))))

;; Factory function to create dotfiles service with custom directories
(define* (make-dotfiles-service #:key (directories '("../../dotfiles")))
  (service home-dotfiles-service-type
           (home-dotfiles-configuration
            (directories directories))))
