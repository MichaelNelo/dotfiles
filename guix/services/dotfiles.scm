(define-module (services dotfiles)
  #:use-module (ice-9 match)
  #:use-module (guix gexp)
  #:use-module (gnu home services)
  #:use-module (gnu home services dotfiles)
  #:use-module (packages micro-plugins lsp)
  #:use-module (packages micro-plugins autofmt)
  #:use-module (packages micro-plugins fzf)
  #:export (%dotfiles-service %micro-plugins-service))


(define micro-plugins 
  `(("lsp" ,micro-plugin-lsp)
  	("fzfinder" ,micro-plugin-fzf)
    ("autofmt" ,micro-plugin-autofmt)))

(define (plugin-entries pkgs)
  (map (match-lambda 
  		 ((subdir pkg)
          (list (string-append "micro/plug/" subdir)
                (file-append pkg "/share"))))
       pkgs))

(define %micro-plugins-service
  (simple-service 'link-micro-plugins
  				  home-xdg-configuration-files-service-type
  				  (plugin-entries micro-plugins)))
;; Dotfiles service pointing to dotfiles_client root
;; Path resolution: services/dotfiles.scm -> ../../ = dotfiles_client/
;; Copies .config/* to ~/.config/*
(define %dotfiles-service
  (service home-dotfiles-service-type
           (home-dotfiles-configuration
            (directories '("../..")))))
