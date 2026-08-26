;; Nushell code generation for <secret> provisioners.
;;
;; Emits INLINE code (no defs) meant to be dropped into login.nu via
;; the nushell service's login-nu list.  Layout of the returned file:
;;
;;   1. op-agent session prelude — runs once at TOP level so load-env
;;      propagates to login.nu's shell scope.  If the daemon already
;;      has a session, just load it; otherwise, only prompt unlock
;;      when at least one secret is missing (avoid prompting for
;;      nothing on already-provisioned boxes).
;;
;;   2. Per-secret `do { … }` block — scope-isolates local vars
;;      (path, val, decoded, …).  Each block short-circuits on
;;      `path exists` and on op read failures.
;;
;; Consequence: no user-callable `provision-<name>` defs in the
;; top-level namespace.  Re-provisioning after manual deletion of a
;; secret file happens on the next login shell.

(define-module (dotfiles secrets nushell)
  #:use-module (guix gexp)
  #:use-module (srfi srfi-1)
  #:use-module (ice-9 format)
  #:use-module (dotfiles secrets record)
  #:use-module (dotfiles secrets piknik)
  #:export (secret->nushell-provisioner
            secrets->nushell-config))

;; ================
;; Helpers
;; ================

(define (mode->nushell mode)
  (format #f "0o~o" mode))

;; The write-body: takes a nushell expression that evaluates to the
;; bytes to save, plus mode/owner semantics from the record.
(define (write-body secret value-expr indent)
  (let ((mode  (mode->nushell (secret-mode secret)))
        (owner (secret-owner secret))
        (name  (secret-name secret)))
    (if owner
        (format #f
                "~alet parent = ($path | path dirname)
~a^sudo install -d -m 700 -o ~a -g ~a $parent
~a~a | ^sudo tee $path out+err> /dev/null
~a^sudo chmod ~a $path
~a^sudo chown ~a $path
~aprint $'[secret ~a] wrote ($path) (~a)'"
                indent
                indent (car (string-split owner #\:)) (cadr (string-split owner #\:))
                indent value-expr
                indent mode
                indent owner
                indent name owner)
        (format #f
                "~alet parent = ($path | path dirname)
~amkdir $parent
~a~a | save --force $path
~a^chmod ~a $path
~aprint $'[secret ~a] wrote ($path)'"
                indent
                indent
                indent value-expr
                indent mode
                indent name))))

(define (fetch-body secret)
  (let ((uri (secret-source secret))
        (name (secret-name secret)))
    (case (secret-type secret)
      ((raw)
       (format #f
               "        let val = (^op read '~a' | complete)
        if $val.exit_code != 0 or ($val.stdout | is-empty) {
            print $'[secret ~a] op read failed (~~($val.exit_code))'
        } else {
~a
        }"
               uri name
               (write-body secret "$val.stdout" "            ")))
      ((base64)
       (format #f
               "        let b64 = (^op read '~a' | complete)
        if $b64.exit_code != 0 or ($b64.stdout | is-empty) {
            print $'[secret ~a] op read failed (~~($b64.exit_code))'
        } else {
            let decoded = ($b64.stdout | ^base64 -d | complete | get stdout)
~a
        }"
               uri name
               (write-body secret "$decoded" "            ")))
      ((piknik-keyset)
       (piknik-keyset->nushell-body
        secret
        (write-body secret "$content" "                ")))
      (else
       (error "secret->nushell-provisioner: unknown type"
              (secret-type secret))))))

;; ================
;; Public API
;; ================

;; Emit a `do { ... }` inline block for one secret.  No def wrapper —
;; the block runs immediately when the enclosing script is executed.
(define (secret->nushell-provisioner secret)
  (let ((name (secret-name secret))
        (path-expr (format #f "('~a' | path expand)" (secret-path secret))))
    (format #f
            "# --- secret: ~a (~a) ---
do {
    let path = ~a
    if not ($path | path exists) {
~a
    }
}
"
            name (symbol->string (secret-type secret))
            path-expr
            (fetch-body secret))))

;; Op-agent ensure prelude — runs at top-level so load-env propagates
;; to the outer login shell.  Only prompts unlock when at least one
;; secret is missing (short-circuits on already-provisioned boxes).
(define (op-ensure-block secrets)
  (let ((path-list
         (string-join
          (map (lambda (s)
                 (format #f "        ('~a' | path expand)"
                         (secret-path s)))
               secrets)
          "\n")))
    (format #f
            "# --- op-agent session (top-level: load-env propagates) ---
let __op_env_out = (^op-agent env | complete)
if $__op_env_out.exit_code == 0 and (($__op_env_out.stdout | str trim) != '') {
    for line in ($__op_env_out.stdout | lines) {
        let kv = ($line | split row -n 2 '=')
        if ($kv | length) == 2 {
            load-env { ($kv | get 0): ($kv | get 1) }
        }
    }
}

let __secrets_missing = ([
~a
    ] | any {|p| not ($p | path exists) })

if $__secrets_missing and (($env.OP_SESSION_my? | default '') | is-empty) {
    try { ^op-agent unlock }
    let __op_env_out2 = (^op-agent env | complete)
    if $__op_env_out2.exit_code == 0 and (($__op_env_out2.stdout | str trim) != '') {
        for line in ($__op_env_out2.stdout | lines) {
            let kv = ($line | split row -n 2 '=')
            if ($kv | length) == 2 {
                load-env { ($kv | get 0): ($kv | get 1) }
            }
        }
    }
}
"
            path-list)))

;; Bundle N secrets → single mixed-text-file containing:
;;   - op-agent ensure prelude (top-level; load-env propagates)
;;   - each secret's `do { ... }` block
;; Added to nushell's login-nu list in home.scm so its contents get
;; concatenated into ~/.config/nushell/login.nu on activation.
(define (secrets->nushell-config secrets)
  (mixed-text-file
   "secrets-provisioners.nu"
   (op-ensure-block secrets)
   "\n"
   (string-join (map secret->nushell-provisioner secrets) "\n")))
