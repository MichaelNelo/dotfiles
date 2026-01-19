(define-module (services dotfiles)
  #:use-module (gnu home services)
  #:use-module (gnu home services dotfiles)
  #:export (%dotfiles-service))

;; Dotfiles service pointing to dotfiles_client root
;; Path resolution: services/dotfiles.scm -> ../../ = dotfiles_client/
;; Copies .config/* to ~/.config/*
(define %dotfiles-service
  (service home-dotfiles-service-type
           (home-dotfiles-configuration
            (directories '("../..")))))
