(define-module (dotfiles services piknik)
  #:use-module (gnu home services)
  #:use-module (gnu home services shepherd)
  #:use-module (gnu services shepherd)
  #:use-module (guix gexp)
  #:use-module (dotfiles packages piknik)
  #:use-module (dotfiles packages onepassword-cli)
  #:export (%piknik-server-service
            make-piknik-provision-service))

;; One-shot activation: ensures the piknik keyset exists in 1Password,
;; downloads each field to ~/.piknik.parts/, and assembles ~/.piknik.toml.
;;
;; Pipeline (single op signin covers all steps):
;;   1. Ensure ~/.piknik.parts/ exists with mode 700
;;   2. Sign in to op if not authed (interactive master-password prompt)
;;   3. If item missing in 1Password: generate keyset with `piknik -genkeys`,
;;      parse Psk/SignPk/SignSk/EncryptSk, upload as Secure Note
;;   4. For each of the 4 fields: if part file missing, `op read` and save
;;   5. If all 4 parts present and ~/.piknik.toml missing: assemble it
;;
;; Idempotent: subsequent reconfigures detect already-done state and no-op.
;; If op signin fails (cancelled, wrong password), the whole pipeline skips
;; without breaking reconfigure.
(define* (make-piknik-provision-service
          #:key (op-package onepassword-cli)
                (piknik-package piknik)
                (shorthand "my")
                (vault "Personal")
                (item "Piknik")
                (listen "0.0.0.0:8075")
                (connect "127.0.0.1:8075"))
  (define script
    (program-file
     "piknik-1p-provision"
     #~(catch #t
         (lambda ()
           (use-modules (ice-9 popen) (ice-9 rdelim) (ice-9 regex)
                        (ice-9 textual-ports)
                        (srfi srfi-1))
           (define op        #$(file-append op-package "/bin/op"))
           (define piknik-bin #$(file-append piknik-package "/bin/piknik"))
           (define shorthand #$shorthand)
           (define vault     #$vault)
           (define item      #$item)
           (define home      (getenv "HOME"))
           (define parts-dir (string-append home "/.piknik.parts"))
           (define toml-path (string-append home "/.piknik.toml"))
           (define fields '("Psk" "SignPk" "SignSk" "EncryptSk"))

           (define (silent-status cmd args)
             (let ((pid (primitive-fork)))
               (if (zero? pid)
                   (begin
                     (close-fdes 1) (close-fdes 2)
                     (open-fdes "/dev/null" 1) (open-fdes "/dev/null" 2)
                     (apply execl cmd cmd args))
                   (status:exit-val (cdr (waitpid pid))))))
           (define (capture cmd . args)
             (let* ((port (apply open-pipe* OPEN_READ cmd args))
                    (out  (get-string-all port))
                    (ec   (status:exit-val (close-pipe port))))
               (cons ec out)))
           (define (find-field name text)
             (let loop ((lines (string-split text #\newline)))
               (if (null? lines)
                   #f
                   (let ((m (string-match
                             (string-append "^" name "[ \t]*=[ \t]*\"([^\"]+)\"")
                             (car lines))))
                     (if m
                         (match:substring m 1)
                         (loop (cdr lines)))))))

           (define (ensure-signed-in)
             (or (eqv? 0 (silent-status op '("whoami")))
                 (begin
                   (format #t "[piknik-provision] signing in to op (master password)~%")
                   (let* ((r     (capture op "signin" "--account" shorthand "--raw"))
                          (token (string-trim-right (cdr r))))
                     (and (eqv? 0 (car r))
                          (not (string-null? token))
                          (begin
                            (setenv (string-append "OP_SESSION_" shorthand) token)
                            #t))))))

           (define (item-exists?)
             (eqv? 0 (silent-status op (list "item" "get" item "--vault" vault))))

           (define (bootstrap-item)
             (format #t "[piknik-provision] generating keyset~%")
             (let* ((r   (capture piknik-bin "-genkeys"))
                    (out (cdr r))
                    (psk    (find-field "Psk"       out))
                    (signpk (find-field "SignPk"    out))
                    (signsk (find-field "SignSk"    out))
                    (esk    (find-field "EncryptSk" out)))
               (cond
                ((and psk signpk signsk esk)
                 (let ((ec (silent-status op
                            (list "item" "create"
                                  "--category" "Secure Note"
                                  "--title" item
                                  "--vault" vault
                                  (string-append "Psk[password]="       psk)
                                  (string-append "SignPk[text]="        signpk)
                                  (string-append "SignSk[password]="    signsk)
                                  (string-append "EncryptSk[password]=" esk)))))
                   (if (eqv? 0 ec)
                       (format #t "[piknik-provision] uploaded~%")
                       (format #t "[piknik-provision] op item create failed (~a)~%" ec))))
                (else
                 (format #t "[piknik-provision] parse failed~%")))))

           (define (download-field f)
             (let ((dest (string-append parts-dir "/" f)))
               (unless (file-exists? dest)
                 (let* ((uri (string-append "op://" vault "/" item "/" f))
                        (r   (capture op "read" uri))
                        (val (string-trim-right (cdr r))))
                   (cond
                    ((and (eqv? 0 (car r)) (not (string-null? val)))
                     (call-with-output-file dest
                       (lambda (port) (display val port)))
                     (chmod dest #o600)
                     (format #t "[piknik-provision] downloaded ~a~%" f))
                    (else
                     (format #t "[piknik-provision] download ~a failed (~a)~%" f (car r))))))))

           (define (assemble-toml)
             (when (and (not (file-exists? toml-path))
                        (every (lambda (f)
                                 (file-exists? (string-append parts-dir "/" f)))
                               fields))
               (let* ((read-part (lambda (f)
                                   (string-trim-right
                                    (call-with-input-file
                                        (string-append parts-dir "/" f)
                                      get-string-all))))
                      (content (string-append
                                "Listen = \""    #$listen  "\"\n"
                                "Connect = \""   #$connect "\"\n"
                                "Psk = \""       (read-part "Psk")       "\"\n"
                                "SignPk = \""    (read-part "SignPk")    "\"\n"
                                "SignSk = \""    (read-part "SignSk")    "\"\n"
                                "EncryptSk = \"" (read-part "EncryptSk") "\"\n")))
                 (call-with-output-file toml-path
                   (lambda (port) (display content port)))
                 (chmod toml-path #o600)
                 (format #t "[piknik-provision] assembled ~a~%" toml-path))))

           ;; Pipeline
           (unless (file-exists? parts-dir)
             (mkdir parts-dir))
           (chmod parts-dir #o700)

           (cond
            ((not (ensure-signed-in))
             (format #t "[piknik-provision] op signin failed; skipping~%"))
            (else
             (unless (item-exists?)
               (bootstrap-item))
             (when (item-exists?)
               (for-each download-field fields)
               (assemble-toml))))
           #t)
         (lambda (key . args)
           (format #t "[piknik-provision] error ~a ~a; skipping~%" key args)
           #t))))
  (simple-service 'piknik-provision home-activation-service-type
                  #~(system* #$script)))

;; Home Shepherd service for `piknik -server`.
;;
;; Guards against missing ~/.piknik.toml: if the config file doesn't exist
;; yet, the start procedure returns #f (Shepherd marks the service as
;; "stopped" instead of entering a respawn loop).
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
