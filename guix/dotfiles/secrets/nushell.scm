;; Nushell code generation for <secret> provisioners.
;;
;; The primary consumer path: `provision-<name>` defs generated here
;; are appended to config.nu and invoked from login.nu (see home.scm),
;; so provisioning happens at every interactive login and stays out of
;; `guix home reconfigure`.  Idempotent: the def short-circuits when
;; the path exists AND when op-agent is locked.

(define-module (dotfiles secrets nushell)
  #:use-module (guix gexp)
  #:use-module (srfi srfi-1)
  #:use-module (ice-9 format)
  #:use-module (dotfiles secrets record)
  #:use-module (dotfiles secrets piknik)
  #:export (secret->nushell-provisioner
            secrets->nushell-config))

;; ================
;; Path & mode helpers
;; ================

;; Nushell path expansion — handles both absolute paths and "~/…".
(define (nushell-path-expr path)
  (format #f "('~a' | path expand)" path))

;; Nushell octal literal for a permission mode.
(define (mode->nushell mode)
  (format #f "0o~o" mode))

;; ================
;; Common nushell blocks
;; ================

;; Guard: skip silently if op-agent is locked.  Keeps shell startup
;; fast and non-interactive on already-provisioned boxes.
(define %nushell-op-unlocked-check
  "    # Only fetch if op-agent is unlocked; otherwise silent skip.
    let st = (^op-agent status | complete)
    if $st.exit_code != 0 { return }
    if not ($st.stdout | str contains 'unlocked') { return }
")

;; The write-body: takes a nushell expression that evaluates to the
;; bytes to save, plus mode/owner semantics from the record.  Emits
;; either a self-write (mkdir + save + chmod) or a sudo-mediated one
;; (install dir + sudo tee + sudo chmod + sudo chown).
(define (write-body secret value-expr)
  (let ((mode  (mode->nushell (secret-mode secret)))
        (owner (secret-owner secret))
        (name  (secret-name secret)))
    (if owner
        (format #f
                "    let parent = ($path | path dirname)
    ^sudo install -d -m 700 -o ~a -g ~a $parent
    ~a | ^sudo tee $path out+err> /dev/null
    ^sudo chmod ~a $path
    ^sudo chown ~a $path
    print $'[provision-~a] wrote ($path) (~a)'"
                (car (string-split owner #\:))
                (cadr (string-split owner #\:))
                value-expr
                mode
                owner
                name owner)
        (format #f
                "    let parent = ($path | path dirname)
    mkdir $parent
    ~a | save --force $path
    ^chmod ~a $path
    print $'[provision-~a] wrote ($path)'"
                value-expr
                mode
                name))))

;; ================
;; Dispatch by type
;; ================

(define (fetch-body secret)
  (let ((uri (secret-source secret))
        (name (secret-name secret)))
    (case (secret-type secret)
      ((raw)
       (format #f
               "    let val = (^op read '~a' | complete)
    if $val.exit_code != 0 or ($val.stdout | is-empty) {
        print $'[provision-~a] op read failed (~~($val.exit_code))'
        return
    }
~a"
               uri name
               (write-body secret "$val.stdout")))
      ((base64)
       (format #f
               "    let b64 = (^op read '~a' | complete)
    if $b64.exit_code != 0 or ($b64.stdout | is-empty) {
        print $'[provision-~a] op read failed (~~($b64.exit_code))'
        return
    }
    let decoded = ($b64.stdout | ^base64 -d | complete | get stdout)
~a"
               uri name
               (write-body secret "$decoded")))
      ((piknik-keyset)
       (piknik-keyset->nushell-body secret (write-body secret "$content")))
      (else
       (error "secret->nushell-provisioner: unknown type"
              (secret-type secret))))))

;; ================
;; Public API
;; ================

(define (secret->nushell-provisioner secret)
  (let ((name      (secret-name secret))
        (path-expr (nushell-path-expr (secret-path secret))))
    (format #f
            "# provision-~a: ~a
def provision-~a [] {
    let path = ~a
    if ($path | path exists) { return }
~a~a
}
"
            name (symbol->string (secret-type secret))
            name
            path-expr
            %nushell-op-unlocked-check
            (fetch-body secret))))

;; Bundle N secrets → single nushell config file with each
;; provision-<name> def plus a provision-all-secrets combinator.
(define (secrets->nushell-config secrets)
  (mixed-text-file
   "secrets-provisioners.nu"
   (string-join (map secret->nushell-provisioner secrets) "\n")
   "\n# Combinator: runs every provisioner in declared order.  Cheap
# when all files exist (single `path exists` check each).
def provision-all-secrets [] {\n"
   (string-join
    (map (lambda (s)
           (format #f "    provision-~a" (secret-name s)))
         secrets)
    "\n")
   "\n}\n"))
