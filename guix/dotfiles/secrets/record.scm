;; <secret>: a piece of data managed by 1Password whose canonical
;; on-disk location and shape are described here.  Type-agnostic core:
;; the record + a wait-loop consumer that any shepherd service can
;; embed to block until the secret's file appears.
;;
;; Type-specific generators (nushell code for provisioning, piknik
;; keyset assembly) live in sibling modules under (dotfiles secrets ...)
;; so this file stays free of nushell/piknik dependencies.

(define-module (dotfiles secrets record)
  #:use-module (guix records)
  #:use-module (guix gexp)
  #:export (<secret>
            secret
            secret?
            secret-name
            secret-path
            secret-type
            secret-source
            secret-mode
            secret-owner
            secret-on-missing

            secret->wait-loop-gexp))

;; ================
;; Record
;; ================

;; type: 'raw | 'base64 | 'piknik-keyset
;;   'raw           → source is an op:// URI string; body written verbatim.
;;   'base64        → source is an op:// URI string; body base64-decoded.
;;   'piknik-keyset → source is a <piknik-source> (see
;;                    (dotfiles secrets piknik)); four fields fetched
;;                    (or generated with `piknik -genkeys` when
;;                    on-missing='generate) and assembled into TOML.
;;
;; mode:  file permission bits (octal integer).
;; owner: #f = current user; "user:group" (e.g. "root:root") = install
;;        via `sudo tee`/`sudo chown`.  Used for the guix offload key
;;        at /etc/guix/offload/… which guix-daemon reads as root.
;; on-missing: 'error (default; abort provisioning with a print) or
;;             'generate (only valid for 'piknik-keyset — generate a
;;             fresh keyset and upload to 1P before download).
(define-record-type* <secret>
  secret make-secret
  secret?
  (name        secret-name)
  (path        secret-path)
  (type        secret-type)
  (source      secret-source)
  (mode        secret-mode (default #o600))
  (owner       secret-owner (default #f))
  (on-missing  secret-on-missing (default 'error)))

;; ================
;; Wait-loop gexp
;; ================

;; Returns a gexp that blocks until the secret's file appears on disk.
;; Meant for embedding in a shepherd start proc (or a wrapper program).
;; Poll every 5 seconds; log to stderr every 60 seconds so someone
;; tailing the service log sees progress.
;;
;; Path is resolved against passwd:dir when it starts with "~/".
(define (secret->wait-loop-gexp secret)
  (let ((name (secret-name secret))
        (raw-path (secret-path secret)))
    #~(let* ((raw-path #$raw-path)
             (path (if (and (>= (string-length raw-path) 2)
                            (string=? (substring raw-path 0 2) "~/"))
                       (string-append (passwd:dir (getpwuid (getuid)))
                                      (substring raw-path 1))
                       raw-path)))
        (let loop ((waited 0))
          (cond
           ((file-exists? path) #t)
           (else
            (when (or (= waited 0) (zero? (modulo waited 60)))
              (format (current-error-port)
                      "[wait-secret ~a] waiting for ~a (~a sec)~%"
                      #$name path waited)
              (force-output (current-error-port)))
            (sleep 5)
            (loop (+ waited 5))))))))
