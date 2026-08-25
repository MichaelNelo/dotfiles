;;; op-agent — 1Password session agent for Guix Home.
;;;
;;; Shepherd user service starts a Guile daemon listening on a
;;; Unix-domain socket at $XDG_RUNTIME_DIR/op-agent.sock.  The daemon
;;; holds an OP session token in memory (never on disk) and answers
;;; simple line-oriented requests.
;;;
;;; Protocol (each request is one line; response is one line):
;;;   status         → "unlocked" | "expired" | "locked"
;;;                    (also proactively drops an expired token)
;;;   unlock         → daemon reads next line as master password,
;;;                    calls `op signin --account SHORTHAND --raw`,
;;;                    caches the token.  Response: "ok" | "fail".
;;;   token          → the cached token (empty if locked).
;;;   sign-out       → forget the token.  Response: "ok".
;;;
;;; Client CLI (~/.local/bin/op-agent) wraps the socket:
;;;   op-agent status
;;;   op-agent unlock         → prompts master pw (stty -echo)
;;;   op-agent env            → prints `OP_SESSION_my=<token>` (empty if locked)
;;;   op-agent lock
;;;   op-agent <op args…>     → exec op with OP_SESSION_my pre-set
;;;
;;; env.nu auto-loads the session env on every shell start — no manual
;;; `eval` needed after the initial unlock.
;;;
;;; Security note: the token lives only in the daemon's process memory,
;;; the socket is chmod 0600, and the daemon runs as the user.  Any
;;; process the user owns can query it — same threat model as ssh-agent.

(define-module (dotfiles services op-agent)
  #:use-module (gnu home services)
  #:use-module (gnu home services shepherd)
  #:use-module (gnu services shepherd)
  #:use-module (guix gexp)
  #:use-module (dotfiles packages onepassword-cli)
  #:export (op-agent-daemon
            op-agent-cli
            %op-agent-service
            %op-agent-install-service))

;; ========================================
;; DAEMON
;; ========================================

(define op-agent-daemon
  (program-file
   "op-agent-daemon"
   #~(begin
       (use-modules (ice-9 rdelim) (ice-9 textual-ports))

       (define op-bin #$(file-append onepassword-cli "/bin/op"))
       (define shorthand "my")

       ;; In-memory session token.  #f means locked.
       (define *token* #f)

       (define (socket-path)
         (string-append (or (getenv "XDG_RUNTIME_DIR")
                            (string-append (getenv "HOME") "/.local/state"))
                        "/op-agent.sock"))

       ;; Fork op with a specific OP_SESSION_my in env; return (exit-code . stdout).
       ;; Used to test the current token via `op whoami`.
       (define (op-with-token token args)
         (let* ((out-pipe (pipe))
                (out-r (car out-pipe))
                (out-w (cdr out-pipe))
                (pid   (primitive-fork)))
           (cond
            ((zero? pid)
             (close-port out-r)
             (setenv "OP_SESSION_my" token)
             (dup2 (fileno out-w) 1)
             (dup2 (fileno out-w) 2)
             (close-port out-w)
             (apply execl op-bin "op" args))
            (else
             (close-port out-w)
             (let* ((out (get-string-all out-r))
                    (ec  (status:exit-val (cdr (waitpid pid)))))
               (close-port out-r)
               (cons ec out))))))

       (define (session-valid?)
         (and *token*
              (zero? (car (op-with-token *token* '("whoami"))))))

       ;; Run `op signin --account SHORTHAND --raw`, feeding MASTER-PW on
       ;; stdin.  Returns the trimmed token on success, #f on failure.
       (define (do-signin master-pw)
         (let* ((in-pipe  (pipe))
                (out-pipe (pipe))
                (in-r     (car in-pipe))
                (in-w     (cdr in-pipe))
                (out-r    (car out-pipe))
                (out-w    (cdr out-pipe))
                (pid      (primitive-fork)))
           (cond
            ((zero? pid)
             (close-port in-w)
             (close-port out-r)
             (dup2 (fileno in-r)  0)
             (dup2 (fileno out-w) 1)
             (close-port in-r)
             (close-port out-w)
             (execl op-bin "op" "signin" "--account" shorthand "--raw"))
            (else
             (close-port in-r)
             (close-port out-w)
             (display master-pw in-w)
             (newline  in-w)
             (close-port in-w)
             (let* ((tok (string-trim-right (get-string-all out-r)))
                    (ec  (status:exit-val (cdr (waitpid pid)))))
               (close-port out-r)
               (and (zero? ec)
                    (not (string-null? tok))
                    tok))))))

       (define (send client s)
         (display s client)
         (newline client)
         (force-output client))

       (define (handle-client client)
         (let ((line (read-line client)))
           (unless (eof-object? line)
             (cond
              ((string=? line "status")
               (send client
                     (cond ((not *token*)      "locked")
                           ((session-valid?)   "unlocked")
                           (else               (set! *token* #f) "expired"))))
              ((string=? line "unlock")
               (let ((pw (read-line client)))
                 (cond
                  ((eof-object? pw)   (send client "fail"))
                  (else
                   (let ((tok (do-signin pw)))
                     (cond
                      (tok (set! *token* tok) (send client "ok"))
                      (else (send client "fail"))))))))
              ((string=? line "token")
               (send client (or *token* "")))
              ((string=? line "sign-out")
               (set! *token* #f)
               (send client "ok"))
              (else
               (send client "unknown"))))))

       ;; Accept loop.  One client per accept, blocking; we're single-user,
       ;; requests are tiny — no concurrency needed.
       (let* ((path (socket-path))
              (sock (socket PF_UNIX SOCK_STREAM 0)))
         (when (file-exists? path)
           (delete-file path))
         (bind sock (make-socket-address AF_UNIX path))
         (chmod path #o600)
         (listen sock 5)
         (format #t "op-agent listening on ~a~%" path)
         (force-output)
         (let loop ()
           (let ((client (car (accept sock))))
             (catch #t
                    (lambda () (handle-client client))
                    (lambda args
                      (format #t "op-agent handler error: ~a~%" args)
                      (force-output)))
             (close-port client))
           (loop))))))

;; ========================================
;; CLIENT CLI
;; ========================================

(define op-agent-cli
  (program-file
   "op-agent"
   #~(begin
       (use-modules (ice-9 rdelim) (ice-9 textual-ports))

       (define op-bin #$(file-append onepassword-cli "/bin/op"))

       (define (socket-path)
         (string-append (or (getenv "XDG_RUNTIME_DIR")
                            (string-append (getenv "HOME") "/.local/state"))
                        "/op-agent.sock"))

       (define (talk lines)
         (let ((sock (socket PF_UNIX SOCK_STREAM 0)))
           (catch #t
                  (lambda ()
                    (connect sock (make-socket-address AF_UNIX (socket-path))))
                  (lambda args
                    (format (current-error-port)
                            "op-agent: daemon not reachable at ~a~%"
                            (socket-path))
                    (exit 2)))
           (for-each (lambda (l)
                       (display l sock)
                       (newline sock))
                     lines)
           (force-output sock)
           (let ((resp (read-line sock)))
             (close-port sock)
             (if (eof-object? resp) "" resp))))

       ;; Read a line with echo off.
       (define (read-password-tty prompt)
         (display prompt (current-error-port))
         (force-output (current-error-port))
         (system* "stty" "-echo")
         (let ((line (read-line)))
           (system* "stty" "echo")
           (newline (current-error-port))
           line))

       (define args (cdr (command-line)))

       (cond
        ((null? args)
         (display "usage: op-agent {status|unlock|env|lock|<op args…>}\n"
                  (current-error-port))
         (exit 1))
        ((string=? (car args) "status")
         (display (talk '("status")))
         (newline))
        ((string=? (car args) "unlock")
         (let ((pw (read-password-tty "op master password: ")))
           (display (talk (list "unlock" pw)))
           (newline)))
        ((string=? (car args) "env")
         (let ((tok (talk '("token"))))
           (unless (string-null? tok)
             (format #t "OP_SESSION_my=~a~%" tok))))
        ((string=? (car args) "lock")
         (display (talk '("sign-out")))
         (newline))
        (else
         ;; Pass-through: op-agent op-args… → exec op with session set.
         (let ((tok (talk '("token"))))
           (unless (string-null? tok)
             (setenv "OP_SESSION_my" tok))
           (apply execl op-bin "op" args)))))))

;; ========================================
;; HOME SERVICES
;; ========================================

;; Shepherd service — starts the daemon at session start, respawn on crash.
(define %op-agent-service
  (simple-service 'op-agent
                  home-shepherd-service-type
                  (list (shepherd-service
                         (provision '(op-agent))
                         (documentation "1Password session agent.")
                         (auto-start? #t)
                         (respawn? #t)
                         (start #~(make-forkexec-constructor
                                   (list #$op-agent-daemon)
                                   #:log-file
                                   (string-append
                                    (or (getenv "XDG_STATE_HOME")
                                        (string-append (getenv "HOME")
                                                       "/.local/state"))
                                    "/log/op-agent.log")))
                         (stop #~(make-kill-destructor))))))

;; Install the CLI at ~/.local/bin/op-agent.
(define %op-agent-install-service
  (simple-service 'op-agent-cli
                  home-files-service-type
                  `((".local/bin/op-agent" ,op-agent-cli))))
