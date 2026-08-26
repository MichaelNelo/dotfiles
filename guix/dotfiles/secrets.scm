;; Secrets: declarative 1Password-backed provisioning primitives.
;;
;; A <secret> is a piece of data managed by 1Password whose canonical
;; on-disk location and shape are described here.  Two consumers:
;;
;;   - `secret->nushell-provisioner` returns a chunk of nushell source
;;     that defines `provision-<name>` — a def the shell invokes at
;;     session start (from login.nu).  Idempotent by file existence;
;;     silent no-op when op-agent is locked.
;;
;;   - `secret->wait-loop-gexp` returns a Guile gexp that polls until
;;     the secret's on-disk file appears.  Meant to wrap a shepherd
;;     service so it survives an unprovisioned first boot without
;;     manual `herd start`.
;;
;; Provisioning at shell-start (via login.nu) instead of at
;; `guix home reconfigure` avoids the reconfigure-with-pull latency
;; (channels take several minutes to fetch).  Reconfigure keeps a
;; safety-net home-activation service, but the primary path is the
;; nushell provisioners.

(define-module (dotfiles secrets)
  #:use-module (guix records)
  #:use-module (guix gexp)
  #:use-module (srfi srfi-1)
  #:use-module (ice-9 format)
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

            <piknik-source>
            piknik-source
            piknik-source?
            piknik-source-vault
            piknik-source-item
            piknik-source-fields
            piknik-source-listen
            piknik-source-connect

            secret->nushell-provisioner
            secrets->nushell-config
            secret->wait-loop-gexp))

;; ================
;; Record types
;; ================

;; type: 'raw | 'base64 | 'piknik-keyset
;;   'raw           → source is an op:// URI string; body is fetched and
;;                    written verbatim.
;;   'base64        → source is an op:// URI string; body is base64-
;;                    decoded before write.
;;   'piknik-keyset → source is a <piknik-source>; four fields fetched
;;                    (or generated with `piknik -genkeys` if the item
;;                    is missing and on-missing='generate) and
;;                    assembled into a TOML config.
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

;; Composite source for 'piknik-keyset.  vault + item = 1P coordinates
;; of the Secure Note holding the four keyset fields.  listen/connect
;; are the endpoints written into the assembled TOML.
(define-record-type* <piknik-source>
  piknik-source make-piknik-source
  piknik-source?
  (vault    piknik-source-vault)
  (item     piknik-source-item)
  (fields   piknik-source-fields  (default '("Psk" "SignPk" "SignSk" "EncryptSk")))
  (listen   piknik-source-listen  (default "0.0.0.0:8075"))
  (connect  piknik-source-connect (default "127.0.0.1:8075")))

;; ================
;; Path helpers
;; ================

;; Both consumers accept "~/..." to mean $HOME-relative.  Nushell path
;; expansion handles it natively via `path expand`; for Guile gexps we
;; expand at run time against passwd:dir.
(define (nushell-path-expr path)
  ;; Returns nushell code that evaluates to the resolved path string.
  ;; Wrapped in a subexpression `(...)` so it can be interpolated into
  ;; other nushell strings via `$"(...)"` when needed.
  (format #f "('~a' | path expand)" path))

;; ================
;; Nushell provisioner generation
;; ================

;; Nushell literal for an integer permission mode (e.g. #o600 → "0o600"
;; per nushell's octal syntax, which yields the same numeric value).
(define (mode->nushell mode)
  (format #f "0o~o" mode))

;; The op-agent status guard.  We only fetch when op-agent is unlocked;
;; if it's locked the def silently returns so shell startup stays fast
;; and non-interactive on the common case (already-provisioned box, or
;; user hasn't unlocked yet).
(define %nushell-op-unlocked-check
  "    # Only fetch if op-agent is unlocked; otherwise silent skip.
    let st = (^op-agent status | complete)
    if $st.exit_code != 0 { return }
    if not ($st.stdout | str contains 'unlocked') { return }
")

;; sudo prefix for owner-managed paths.  When owner is set the write
;; goes through sudo tee, and mode/chown are applied with sudo.
(define (write-block secret)
  (let* ((path-expr (nushell-path-expr (secret-path secret)))
         (mode      (mode->nushell (secret-mode secret)))
         (owner     (secret-owner secret))
         (uri       (secret-source secret)))
    (case (secret-type secret)
      ((raw)
       (format #f
               "    let val = (^op read '~a' | complete)
    if $val.exit_code != 0 or ($val.stdout | is-empty) {
        print $'[provision-~a] op read failed (~~($val.exit_code))'
        return
    }
~a"
               uri (secret-name secret)
               (write-body secret path-expr mode owner "$val.stdout")))
      ((base64)
       (format #f
               "    let b64 = (^op read '~a' | complete)
    if $b64.exit_code != 0 or ($b64.stdout | is-empty) {
        print $'[provision-~a] op read failed (~~($b64.exit_code))'
        return
    }
    let decoded = ($b64.stdout | ^base64 -d | complete | get stdout)
~a"
               uri (secret-name secret)
               (write-body secret path-expr mode owner "$decoded")))
      ((piknik-keyset)
       (piknik-write-block secret path-expr mode owner))
      (else
       (error "secret->nushell-provisioner: unknown type"
              (secret-type secret))))))

;; Emit the write + chmod/chown lines for a produced value.
;; VALUE-EXPR is a nushell expression that evaluates to the bytes to
;; write.  Handles owner=#f (self) vs "user:group" (sudo).
(define (write-body secret path-expr mode owner value-expr)
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
              (secret-name secret) owner)
      (format #f
              "    let parent = ($path | path dirname)
    mkdir $parent
    ~a | save --force $path
    ^chmod ~a $path
    print $'[provision-~a] wrote ($path)'"
              value-expr
              mode
              (secret-name secret))))

;; Piknik-keyset provisioner: read 4 fields, optionally generate+upload
;; when on-missing='generate, assemble TOML.
(define (piknik-write-block secret path-expr mode owner)
  (let* ((source     (secret-source secret))
         (vault      (piknik-source-vault source))
         (item       (piknik-source-item source))
         (fields     (piknik-source-fields source))
         (listen     (piknik-source-listen source))
         (connect    (piknik-source-connect source))
         (on-missing (secret-on-missing secret)))
    (format #f
            "    # Check if the 1P item exists; generate + upload if missing.
    let item_exists = (^op item get '~a' --vault '~a' out+err> /dev/null | complete)
    if $item_exists.exit_code != 0 {
        ~a
    }
    # Read all fields.
    let fields_data = ('~a' | split row ',' | each {|f|
        let r = (^op read $'op://~a/~a/($f)' | complete)
        if $r.exit_code != 0 {
            print $'[provision-~a] read ($f) failed'
            {}
        } else {
            { field: $f, value: ($r.stdout | str trim) }
        }
    } | where field != null)
    if ($fields_data | length) != (('~a' | split row ',') | length) {
        return
    }
    let by_field = ($fields_data | reduce -f {} {|it, acc| $acc | insert $it.field $it.value })
    let content = $'Listen = \"~a\"
Connect = \"~a\"
Psk = \"($by_field.Psk)\"
SignPk = \"($by_field.SignPk)\"
SignSk = \"($by_field.SignSk)\"
EncryptSk = \"($by_field.EncryptSk)\"
'
~a"
            item vault
            (if (eq? on-missing 'generate)
                (piknik-generate-and-upload item vault fields)
                (format #f
                        "        print $'[provision-~a] 1P item ~a missing (on-missing=error); skipping.'
        return"
                        (secret-name secret) item))
            (string-join fields ",")
            vault item
            (secret-name secret)
            (string-join fields ",")
            listen connect
            (write-body secret path-expr mode owner "$content"))))

;; Nushell snippet: `piknik -genkeys` → parse 4 fields → `op item create`.
(define (piknik-generate-and-upload item vault fields)
  (format #f
          "        print '[provision-piknik-keyset] generating fresh keyset via piknik -genkeys'
        let gen = (^piknik -genkeys | complete)
        if $gen.exit_code != 0 {
            print '[provision-piknik-keyset] piknik -genkeys failed'
            return
        }
        # Parse: lines like `Psk = \"…\"`
        let parsed = ($gen.stdout | lines | each {|ln|
            let m = ($ln | parse -r '^(?P<k>[A-Za-z]+)\\s*=\\s*\"(?P<v>[^\"]+)\"')
            if ($m | length) > 0 { { field: ($m | get 0.k), value: ($m | get 0.v) } } else { {} }
        } | where field? != null)
        let g = ($parsed | reduce -f {} {|it, acc| $acc | insert $it.field $it.value })
        ^op item create --category 'Secure Note' --title '~a' --vault '~a'
            $'Psk[password]=($g.Psk)'
            $'SignPk[text]=($g.SignPk)'
            $'SignSk[password]=($g.SignSk)'
            $'EncryptSk[password]=($g.EncryptSk)'
            | ignore"
          item vault))

;; Generate a `def provision-<name> []` block.
(define (secret->nushell-provisioner secret)
  (let* ((name      (secret-name secret))
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
            (write-block secret))))

;; Bundle all secrets into a nushell config file: N provisioners plus
;; a `provision-all-secrets` that calls each.  The user invokes the
;; combinator from login.nu (see home.scm).
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
