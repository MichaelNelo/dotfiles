(define-module (services shepherd)
  #:use-module (gnu home services shepherd)
  #:use-module (guix gexp)
  #:use-module (gnu services)
  #:use-module (gnu packages ssh)
  #:use-module (services ollama)
  #:export     (%ollama-service %dopbear-ssh-service))

(define %ollama-service
  (simple-service 'ollama-server home-shepherd-service-type
                  (list ollama-shepherd-service)))

(define %dopbear-ssh-service
  (simple-service 'dopbear-ssh-server home-shepherd-service-type
                  (list (shepherd-service (provision '(ssh-server))
                                          (documentation "SSH server")
                                          (start #~(make-forkexec-constructor
                                                    (list #$(file-append dropbear "/sbin/dropbear")
                                                          "-F"
                                                          "-E"
                                                          "-p"
                                                          "2222"
                                                          "-r"
                                                          (string-append (getenv "HOME")
                                                                         "/.ssh/dropbear_rsa_host_key")
                                                          "-s"
                                                           "-w")))
                                          (stop #~(make-kill-destructor SIGKILL))
                                          (respawn? #f)))))
