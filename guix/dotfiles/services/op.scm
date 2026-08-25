(define-module (dotfiles services op)
  #:use-module (gnu home services)
  #:use-module (guix gexp)
  #:use-module (dotfiles packages onepassword-cli)
  #:export (make-op-account-add-service
            make-op-items-provision-service
            %op-nushell-config))

;; Nushell config snippets for op CLI.  Append to your %nushell-config-nu:
;;   (define %nushell-config-nu
;;     (append base-config %op-nushell-config))
;;
;; Defines `op-login` as a function that prompts master password and exports
;; OP_SESSION_my to the calling shell.  Uses `def --env` to propagate the
;; mutation (a plain alias doesn't survive nushell's parse-time expansion
;; when the body contains env assignments).
(define %op-nushell-config
  (list
   (plain-file
    "op-login.nu"
    "def --env op-login [] {
    $env.OP_SESSION_my = (op signin --account my --raw)
}
")))

;; One-shot: register the 1Password account locally if not already registered.
;;
;; Reads ~/.config/op/account-info (provisioned via dotfiles, git-crypt
;; encrypted in remote, plaintext in working tree).  Expected KV format:
;;
;;   address=my.1password.com
;;   email=user@example.com
;;   secret_key=A3-XXXXXX-XXXXXX-...
;;   shorthand=my
;;
;; Pipes the secret-key via stdin to `op account add`; the master-password
;; prompt is interactive (handled by the user's `home-reconfigure` shell).
;; Subsequent reconfigures detect the local registration and skip.
(define* (make-op-account-add-service
          #:key (package onepassword-cli))
  (define script
    (program-file
     "op-account-add"
     #~(catch #t
         (lambda ()
           (use-modules (ice-9 popen) (ice-9 textual-ports) (ice-9 regex)
                        (srfi srfi-1))
           (define op   #$(file-append package "/bin/op"))
           (define op-dir (string-append (getenv "HOME") "/.config/op"))
           (define info (string-append op-dir "/account-info"))
           ;; op refuses to run if ~/.config/op isn't 700.  Tighten it here
           ;; in case the home-dotfiles auto-link created it with default perms.
           (when (file-exists? op-dir)
             (chmod op-dir #o700))
           (define (read-kv path)
             (filter-map
              (lambda (line)
                (let ((m (string-match "^([a-z_]+)=(.+)$" line)))
                  (and m (cons (match:substring m 1) (match:substring m 2)))))
              (string-split
               (call-with-input-file path get-string-all)
               #\newline)))
           (when (file-exists? info)
             (let* ((kv  (read-kv info))
                    (get (lambda (k) (assoc-ref kv k)))
                    (addr (get "address"))
                    (mail (get "email"))
                    (sk   (get "secret_key"))
                    (sh   (get "shorthand")))
               (cond
                ((not (and addr mail sk sh))
                 (format #t "[op-account-add] incomplete account-info, skipping~%"))
                ((not (string-match "^A3-" sk))
                 (format #t "[op-account-add] secret_key not in expected format (encrypted?), skipping~%"))
                (else
                 (let* ((p   (open-pipe* OPEN_READ op "account" "list"))
                        (out (get-string-all p))
                        (_   (close-pipe p)))
                   (if (string-contains out sh)
                       (format #t "[op-account-add] '~a' already registered~%" sh)
                       (begin
                         (format #t "[op-account-add] adding '~a' (master password prompt incoming)~%" sh)
                         (setenv "OP_SECRET_KEY" sk)
                         (let ((ec (status:exit-val
                                    (system* op "account" "add"
                                             "--address" addr
                                             "--email"   mail
                                             "--shorthand" sh))))
                           (unsetenv "OP_SECRET_KEY")
                           (if (and ec (zero? ec))
                               (format #t "[op-account-add] registered~%")
                               (format #t "[op-account-add] op exit ~a~%" ec))))))))))
           #t)
         (lambda args
           (format #t "[op-account-add] error ~a; skipping~%" args)
           #t))))
  (simple-service 'op-account-add home-activation-service-type
                  #~(system* #$script)))

;; Generic provision activation: download a list of items from 1Password
;; into files under $HOME.  Used for SSH keys, app-specific secrets, etc.
;;
;; ITEMS is a list of (URI DEST-REL MODE) tuples:
;;   URI       — full op:// URI
;;   DEST-REL  — destination path relative to $HOME (e.g. ".ssh/key")
;;   MODE      — octal integer like #o600
;;
;; For each item: if file missing AND op authed, download.  Master-password
;; prompt during reconfigure if signin needed.  Idempotent: existing files
;; skip the op read.
(define* (make-op-items-provision-service
          #:key (package onepassword-cli)
                (shorthand "my")
                (items '()))
  (define script
    (program-file
     "op-items-provision"
     #~(catch #t
         (lambda ()
           (use-modules (ice-9 popen) (ice-9 rdelim) (ice-9 textual-ports)
                        (srfi srfi-1))
           (define op   #$(file-append package "/bin/op"))
           (define shorthand #$shorthand)
           (define home (getenv "HOME"))
           (define items '#$items)
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
           (define (ensure-signed-in)
             (or (eqv? 0 (silent-status op '("whoami")))
                 (begin
                   (format #t "[op-items-provision] signing in to op (master password)~%")
                   (let* ((r     (capture op "signin" "--account" shorthand "--raw"))
                          (token (string-trim-right (cdr r))))
                     (and (eqv? 0 (car r))
                          (not (string-null? token))
                          (begin
                            (setenv (string-append "OP_SESSION_" shorthand) token)
                            #t))))))
           ;; Recursive mkdir (single-level `mkdir` fails for
           ;; dests like ~/.config/git/dotfiles/…).
           (define (mkdir-p path)
             (unless (file-exists? path)
               (mkdir-p (dirname path))
               (mkdir path)))
           ;; Base64-decode STR via base64(1) (avoids pulling gcrypt just
           ;; for this).  Round-trips through a temp file to sidestep
           ;; bidirectional-pipe pain in guile.
           (define (base64-decode-to-file str dest)
             (let ((tmp (string-append dest ".b64")))
               (call-with-output-file tmp
                 (lambda (p) (display str p)))
               (let ((ec (system (string-append
                                  "base64 -d < " tmp " > " dest))))
                 (false-if-exception (delete-file tmp))
                 (zero? ec))))
           (define (download item)
             (let* ((uri     (list-ref item 0))
                    (rel     (list-ref item 1))
                    (mode    (list-ref item 2))
                    (decode  (if (> (length item) 3)
                                 (list-ref item 3)
                                 'raw))
                    (dest    (string-append home "/" rel)))
               (unless (file-exists? dest)
                 (mkdir-p (dirname dest))
                 (let* ((r    (capture op "read" uri))
                        (val  (cdr r)))
                   (cond
                    ((not (and (eqv? 0 (car r)) (not (string-null? val))))
                     (format #t "[op-items-provision] download ~a failed (~a)~%"
                             rel (car r)))
                    ((eq? decode 'base64)
                     (if (base64-decode-to-file val dest)
                         (begin (chmod dest mode)
                                (format #t "[op-items-provision] downloaded+decoded ~a~%" rel))
                         (format #t "[op-items-provision] base64 decode failed for ~a~%" rel)))
                    (else
                     (call-with-output-file dest
                       (lambda (p) (display val p)))
                     (chmod dest mode)
                     (format #t "[op-items-provision] downloaded ~a~%" rel)))))))
           ;; Short-circuit: if every destination already exists, skip the
           ;; signin prompt entirely.  We only need op (and the master
           ;; password) when there's something to fetch.
           (define (item-dest item)
             (string-append home "/" (list-ref item 1)))
           (define (all-present?)
             (every (lambda (it) (file-exists? (item-dest it))) items))
           (cond
            ((null? items)
             #t)
            ((all-present?)
             #t)
            ((not (ensure-signed-in))
             (format #t "[op-items-provision] op signin failed; skipping~%"))
            (else
             (for-each download items)))
           #t)
         (lambda (key . args)
           (format #t "[op-items-provision] error ~a ~a; skipping~%" key args)
           #t))))
  (simple-service 'op-items-provision home-activation-service-type
                  #~(system* #$script)))
