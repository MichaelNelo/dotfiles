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

;; Preamble emitted once at the top of secrets-provisioners.nu.
;;
;; op-agent-ensure-session: load OP_SESSION_my from the daemon into
;; THIS shell's env; if the daemon has no session, prompt master
;; password once via `op-agent unlock` and load again.  Idempotent:
;; subsequent calls in the same shell hit the "has session" path and
;; don't prompt, because op-agent daemon caches the session in RAM
;; after first unlock.
;;
;; `def --env` propagates load-env to the caller's scope, so a
;; provision-<name> that calls this helper sees OP_SESSION_my in its
;; own env and the `op read` subprocess inherits it.
(define %nushell-op-ensure-def
  "# Preamble: helper called by every provision-<name> before op read.
def --env op-agent-ensure-session [] {
    let out = (^op-agent env | complete)
    if $out.exit_code == 0 and (($out.stdout | str trim) != '') {
        for line in ($out.stdout | lines) {
            let kv = ($line | split row -n 2 '=')
            if ($kv | length) == 2 {
                load-env { ($kv | get 0): ($kv | get 1) }
            }
        }
        return true
    }
    # No session — prompt for unlock (interactive; master password).
    try { ^op-agent unlock } catch { return false }
    let out2 = (^op-agent env | complete)
    if $out2.exit_code == 0 and (($out2.stdout | str trim) != '') {
        for line in ($out2.stdout | lines) {
            let kv = ($line | split row -n 2 '=')
            if ($kv | length) == 2 {
                load-env { ($kv | get 0): ($kv | get 1) }
            }
        }
        return true
    }
    false
}
")

;; Guard emitted at the top of every provision-<name>: ensures the
;; op-agent session is loaded (prompting unlock if necessary), and
;; skips this secret if the unlock failed / was aborted.
(define %nushell-op-unlocked-check
  "    if not (op-agent-ensure-session) { return }
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

;; Bundle N secrets → single nushell config file with the op-agent
;; session helper (preamble), each provision-<name> def, plus a
;; provision-all-secrets combinator.
(define (secrets->nushell-config secrets)
  (mixed-text-file
   "secrets-provisioners.nu"
   %nushell-op-ensure-def
   "\n"
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
