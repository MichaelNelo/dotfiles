(define-module (dotfiles home)
  #:use-module (gnu home)
  #:use-module (dotfiles packages manifest)
  #:use-module (dotfiles services dotfiles)
  #:use-module (dotfiles services ssh)
  #:use-module (dotfiles services zsh)
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
