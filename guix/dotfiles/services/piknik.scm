(define-module (dotfiles services piknik)
  #:use-module (gnu home services)
  #:use-module (gnu home services shepherd)
  #:use-module (gnu services shepherd)
  #:use-module (guix gexp)
  #:use-module (dotfiles packages piknik)
  #:export (%piknik-server-service))

;; Home Shepherd service for `piknik -server`.
;;
;; Guards against missing ~/.piknik.toml: if the config file doesn't exist
;; yet, the start procedure returns #f (Shepherd marks the service as
;; "stopped" instead of entering a respawn loop).  After keys are uploaded
;; to 1Password and provisioned on next nushell login, run
;; `herd start piknik-server`.
;;
;; Log directory (~/.local/state/log) is created by the activation snippet
;; in guix/home/user.scm, not here.
(define %piknik-server-service
  (simple-service 'piknik-server
                  home-shepherd-service-type
                  (list
                   (shepherd-service
                    (provision '(piknik-server))
                    (documentation "Piknik server (clipboard relay).")
                    (auto-start? #t)
                    (respawn? #t)
                    (start
                     #~(lambda args
                         (let* ((home (getenv "HOME"))
                                (toml (string-append home "/.piknik.toml"))
                                (state (or (getenv "XDG_STATE_HOME")
                                           (string-append home "/.local/state")))
                                (log (string-append state "/log/piknik-server.log")))
                           (if (file-exists? toml)
                               (apply (make-forkexec-constructor
                                       (list #$(file-append piknik "/bin/piknik")
                                             "-server")
                                       #:log-file log)
                                      args)
                               (begin
                                 (format #t "[piknik-server] ~a missing, not starting~%" toml)
                                 #f)))))
                    (stop #~(make-kill-destructor))))))
