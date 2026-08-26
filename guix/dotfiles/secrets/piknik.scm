;; Piknik-specific secret pieces: the composite source record and the
;; nushell-string generator for the 'piknik-keyset type.
;;
;; The generic secret->nushell-provisioner (in (dotfiles secrets nushell))
;; dispatches on secret-type; for 'piknik-keyset it calls into here
;; instead of inlining the logic — keeping the nushell dispatcher
;; free of piknik details and letting the piknik knowledge (fields,
;; TOML shape, piknik -genkeys parsing) live in one place.

(define-module (dotfiles secrets piknik)
  #:use-module (guix records)
  #:use-module (srfi srfi-1)
  #:use-module (ice-9 format)
  #:use-module (dotfiles secrets record)
  #:export (<piknik-source>
            piknik-source
            piknik-source?
            piknik-source-vault
            piknik-source-item
            piknik-source-fields
            piknik-source-listen
            piknik-source-connect

            piknik-keyset->nushell-body))

;; ================
;; Record
;; ================

;; vault + item = 1P coordinates of the Secure Note holding the four
;; keyset fields.  listen/connect are the endpoints written into the
;; assembled TOML.
(define-record-type* <piknik-source>
  piknik-source make-piknik-source
  piknik-source?
  (vault    piknik-source-vault)
  (item     piknik-source-item)
  (fields   piknik-source-fields  (default '("Psk" "SignPk" "SignSk" "EncryptSk")))
  (listen   piknik-source-listen  (default "0.0.0.0:8075"))
  (connect  piknik-source-connect (default "127.0.0.1:8075")))

;; ================
;; Nushell generator for the piknik-keyset type
;; ================

;; Emit the fetch/generate body for a 'piknik-keyset secret.  Meant to
;; be embedded inside a `do { if not ($path | path exists) { … } }`
;; block (see (dotfiles secrets nushell)), so this uses nested
;; if/else — no `return` — and 8-space indentation for the body.
;; write-body is the nushell "write $content with permissions" snippet
;; that lives inside the innermost success branch.
(define (piknik-keyset->nushell-body secret write-body)
  (let* ((source     (secret-source secret))
         (vault      (piknik-source-vault source))
         (item       (piknik-source-item source))
         (fields     (piknik-source-fields source))
         (listen     (piknik-source-listen source))
         (connect    (piknik-source-connect source))
         (on-missing (secret-on-missing secret))
         (name       (secret-name secret)))
    (format #f
            "        # Ensure the 1P item exists (generate + upload if missing).
        let __item_exists = (^op item get '~a' --vault '~a' out+err> /dev/null | complete)
        let __item_ready = if $__item_exists.exit_code == 0 { true } else {
~a
        }
        if $__item_ready {
            # Read all four fields.
            let __fields_data = ('~a' | split row ',' | each {|f|
                let r = (^op read $'op://~a/~a/($f)' | complete)
                if $r.exit_code != 0 {
                    print $'[secret ~a] read ($f) failed'
                    {}
                } else {
                    { field: $f, value: ($r.stdout | str trim) }
                }
            } | where field != null)
            if ($__fields_data | length) == (('~a' | split row ',') | length) {
                let __by_field = ($__fields_data | reduce -f {} {|it, acc| $acc | insert $it.field $it.value })
                let content = $'Listen = \"~a\"
Connect = \"~a\"
Psk = \"($__by_field.Psk)\"
SignPk = \"($__by_field.SignPk)\"
SignSk = \"($__by_field.SignSk)\"
EncryptSk = \"($__by_field.EncryptSk)\"
'
~a
            }
        }"
            item vault
            (if (eq? on-missing 'generate)
                (piknik-generate-and-upload item vault name)
                (format #f
                        "            print $'[secret ~a] 1P item ~a missing - on-missing=error, skipping.'
            false"
                        name item))
            (string-join fields ",")
            vault item
            name
            (string-join fields ",")
            listen connect
            write-body)))

;; Emits a nushell expression that runs `piknik -genkeys`, parses the
;; four fields, and uploads a Secure Note to 1P.  Returns true on
;; success, false on any failure.  Called from the `else` branch of
;; the item-exists check above (must be an expression, not a
;; statement, because we're feeding a `let … = if … { … } else { … }`).
(define (piknik-generate-and-upload item vault name)
  (format #f
          "            print '[secret ~a] generating fresh keyset via piknik -genkeys'
            let __gen = (^piknik -genkeys | complete)
            if $__gen.exit_code != 0 {
                print '[secret ~a] piknik -genkeys failed'
                false
            } else {
                let __parsed = ($__gen.stdout | lines | each {|ln|
                    let m = ($ln | parse -r '^(?P<k>[A-Za-z]+)\\s*=\\s*\"(?P<v>[^\"]+)\"')
                    if ($m | length) > 0 { { field: ($m | get 0.k), value: ($m | get 0.v) } } else { {} }
                } | where field? != null)
                let __g = ($__parsed | reduce -f {} {|it, acc| $acc | insert $it.field $it.value })
                let __create = (^op item create --category 'Secure Note' --title '~a' --vault '~a'
                    $'Psk[password]=($__g.Psk)'
                    $'SignPk[text]=($__g.SignPk)'
                    $'SignSk[password]=($__g.SignSk)'
                    $'EncryptSk[password]=($__g.EncryptSk)' | complete)
                $__create.exit_code == 0
            }"
          name name item vault))
