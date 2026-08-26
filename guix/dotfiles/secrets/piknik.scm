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

;; Emitted as the fetch/generate body of the provision-<name> def.
;; write-body is the nushell-side "write $content with permissions"
;; snippet; it's produced by (dotfiles secrets nushell) and passed in
;; so this module doesn't need to know about mode/owner/sudo details.
(define (piknik-keyset->nushell-body secret write-body)
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
            write-body)))

;; Emits a nushell block that runs `piknik -genkeys`, parses the
;; four fields, and uploads a Secure Note to 1P.  Called from the
;; 'if item_exists.exit_code != 0' branch above.
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
