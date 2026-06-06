(define-module (dotfiles services op)
  #:use-module (gnu home services)
  #:use-module (guix gexp)
  #:use-module (dotfiles packages onepassword-cli)
  #:export (make-op-account-add-service
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
