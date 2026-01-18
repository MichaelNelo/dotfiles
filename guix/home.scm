(define-module (home)
  #:use-module (gnu home)
  #:use-module (packages manifest)
  #:use-module (services dotfiles)
  #:use-module (services ssh)
  #:use-module (services zsh)
  #:export (dotfiles-home-environment))

;; Compose home environment from modular components
(define dotfiles-home-environment
  (home-environment
   (packages (append %base-packages
                     (if (getenv "TEST") %dev-packages '())))
   (services (list %dotfiles-service
                   %ssh-service
                   %zsh-service))))

;; Export for direct use
dotfiles-home-environment
