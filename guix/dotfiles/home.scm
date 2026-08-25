(define-module (dotfiles home)
  #:use-module (gnu home)
  #:use-module (gnu home services)
  #:use-module (gnu home services shepherd)
  #:use-module (gnu home services guix)
  #:use-module (guix channels)
  #:use-module (dotfiles packages manifest)
  #:use-module (dotfiles packages onepassword-cli)
  #:use-module (dotfiles packages oh-my-posh)
  #:use-module (dotfiles packages nushell)
  #:use-module (dotfiles packages zellij-plugins)
  #:use-module (dotfiles services dotfiles)
  #:use-module (dotfiles services ssh)
  #:use-module (dotfiles services nushell)
  #:use-module (dotfiles services op)
  #:use-module (dotfiles services piknik)
  #:use-module (gnu packages rust-apps)   ;zoxide
  #:use-module (gnu packages ssh)         ;openssh (ssh-agent shepherd)
  #:use-module (guix gexp)
  #:export (dotfiles-home-environment))

;; ========================================
;; GUIX CHANNELS
;; ========================================

;; Install ~/.config/guix/channels.scm so `guix pull` picks up nonguix
;; (required by onepassword-cli).  guix is pinned by commit for
;; reproducibility; bump the (commit ...) string to move to a newer
;; revision.  Must mirror /home/mknelo/dotfiles/channels.scm (the
;; bootstrap file used by `guix pull -C`).
(define %channels-service
  (service home-channels-service-type
           (list (channel
                  (name 'guix)
                  (url "https://git.savannah.gnu.org/git/guix.git")
                  (commit "85dd4524a64b82ec646e57094a3d6dcf7e506bf1")
                  (introduction
                   (make-channel-introduction
                    "9edb3f66fd807b096b48283debdcddccfea34bad"
                    (openpgp-fingerprint
                     "BBB0 2DDF 2CEA F6A8 0D1D  E643 A2A0 6DF2 A33A 54FA"))))
                 (channel
                  (name 'nonguix)
                  (url "https://gitlab.com/nonguix/nonguix")
                  (introduction
                   (make-channel-introduction
                    "897c1a470da759236cc11798f4e0a5f7d4d59fbc"
                    (openpgp-fingerprint
                     "2A39 3FFF 68F4 EF7A 3D29  12AF 6F51 20A0 22FB B2D5")))))))

;; ========================================
;; NUSHELL — env.nu
;; ========================================

;; Pre-compute `zoxide init nushell` at build time so the resulting file
;; embeds zoxide's absolute /gnu/store path.  Fixes two hazards:
;;   1. `source ./custom/.zoxide.nu` from env.nu was resolved relative to
;;      the /gnu/store env.nu path, not ~/.config/nushell/, so it failed.
;;   2. Any checked-in pre-generated init goes stale as soon as zoxide
;;      gets a new store hash — `zoxide` gets executed on every hook and
;;      the old hash is not in the store anymore.
(define zoxide-nushell-init
  (computed-file
   "zoxide-init.nu"
   #~(begin
       (use-modules (ice-9 popen) (ice-9 textual-ports))
       (let* ((port (open-pipe* OPEN_READ
                                #$(file-append zoxide "/bin/zoxide")
                                "init" "nushell")))
         (call-with-output-file #$output
           (lambda (out)
             (display (get-string-all port) out)))
         (close-pipe port)))))

(define %nushell-env-nu
  (list (plain-file "direnv-init.nu" "
$env.config = {
    hooks: {
      env_change: {
          PWD: [
                  { ||
                    if (which direnv | is-empty) {
                        return
                    }
                    direnv export json | from json | default {} | load-env
              }
               ]
       }
   }
}
")
        (mixed-text-file "zoxide-source.nu"
                         "source " zoxide-nushell-init "\n")
        ;; PATH & Guix locales.  On a foreign distro /etc/profile doesn't
        ;; know about ~/.guix-home/profile or ~/.config/guix/current, so
        ;; we prepend them here.  Order matters: current-guix first so
        ;; `guix` resolves to the user's own guix (not the system one).
        (plain-file "path-init.nu"
                    "$env.GUIX_LOCPATH = $\"($env.HOME)/.guix-home/profile/lib/locale\"
$env.PATH = ($env.PATH | split row (char esep) | prepend [
  $\"($env.HOME)/.local/bin\"
  $\"($env.HOME)/.config/guix/current/bin\"
  $\"($env.HOME)/.guix-home/profile/bin\"
  $\"($env.HOME)/.guix-home/profile/sbin\"
  $\"($env.HOME)/.nix-profile/bin\"
  \"/nix/var/nix/profiles/default/bin\"
])
$env.NIX_PROFILES = $\"/nix/var/nix/profiles/default ($env.HOME)/.nix-profile\"
$env.NIX_SSL_CERT_FILE = \"/etc/ssl/certs/ca-certificates.crt\"
")
        ;; VA-API driver path — needs $env.HOME interpolation because
        ;; Guix installs .so files under the home profile, not /usr/lib/dri.
        (plain-file "vaapi-init.nu"
                    "$env.LIBVA_DRIVERS_PATH = $\"($env.HOME)/.guix-home/profile/lib/dri\"
")
        ;; SSH agent socket + auto-load of provisioned keys.  Runs on
        ;; every shell start: guaranteed to be idempotent because
        ;; ssh-add on an already-loaded key is a no-op re-add.
        ;;
        ;; Why here and not in home-activation: shepherd's ssh-agent
        ;; service is only up AFTER activation completes (shepherd
        ;; reload is at end of reconfigure).  Doing ssh-add at
        ;; activation would race with a non-running agent.  Doing it
        ;; per-shell instead guarantees the agent is up (auto-started
        ;; by shepherd) by the time any shell tries to use it.
        (plain-file "ssh-agent-init.nu"
                    "$env.SSH_AUTH_SOCK = (
    $env
    | get -i XDG_RUNTIME_DIR
    | default $\"($env.HOME)/.local/state\"
    | path join ssh-agent.sock
)

def ssh-load-keys [] {
    let keys = [
        $\"($env.HOME)/.ssh/personal.github.id_ed25519\"
        $\"($env.HOME)/.ssh/eva.personal.id_dropbear\"
        $\"($env.HOME)/.ssh/codeberg.id_ed25519\"
    ]
    # Fingerprints currently in the agent — second whitespace-delimited
    # field of each `ssh-add -l` line.  Skips silently if the agent is
    # empty or unreachable (returns []).
    let loaded = (
        try {
            ^ssh-add -l
            | lines
            | each {|l| $l | split row -r '\\s+' | get 1 }
        } catch { [] }
    )
    for key in $keys {
        if not ($key | path exists) { continue }
        let fp = (
            try { ^ssh-keygen -lf $key | split row -r '\\s+' | get 1 }
            catch { '' }
        )
        if ($fp != '' and ($fp not-in $loaded)) {
            try { ^ssh-add $key out+err> /dev/null }
        }
    }
}

# Best-effort auto-load on shell start.  First shell with a passphrase-
# protected key prompts once; subsequent shells reuse the agent because
# ssh-load-keys skips keys whose fingerprint is already loaded.
try { ssh-load-keys }
")))

;; ========================================
;; NUSHELL — config.nu (oh-my-posh + op-login)
;; ========================================

;; oh-my-posh init must be the last line of config.nu (per upstream docs).
;; Requires nushell >= 0.104.0.
(define %nushell-config-nu
  (append
   %op-nushell-config
   (list (mixed-text-file
          "oh-my-posh-init.nu"
          "oh-my-posh init nu --config "
          (file-append oh-my-posh "/share/oh-my-posh/themes/tokyo.omp.json")
          "\n"))))

;; Aliases with spaces are emitted as `def NAME [] { … }` by the nushell
;; service (see serialize-nushell-aliases) — nushell's plain `alias` only
;; supports a single command atom, so multi-arg wrappers need def.
(define %nushell-aliases
  '(("home-reconfigure" .
     "guix home reconfigure -L ~/dotfiles/guix ~/dotfiles/guix/dotfiles/home.scm")
    ("explore" .
     "zellij action new-tab --layout ~/.config/zellij/layouts/explore.kdl")
    ("edit" .
     "zellij action new-tab --layout ~/.config/zellij/layouts/edit.kdl")))

(define %nushell-service
  (make-nushell-service
   #:package nushell-0.104.0
   #:aliases %nushell-aliases
   #:env-nu %nushell-env-nu
   #:config-nu %nushell-config-nu))

;; ========================================
;; SSH AGENT — user shepherd service
;; ========================================

;; ssh-agent user daemon.  Fixed socket path at
;; $XDG_RUNTIME_DIR/ssh-agent.sock so env.nu's SSH_AUTH_SOCK finds it
;; deterministically.  Auto-starts on shepherd reload (end of home
;; activation) and respawns if killed.  Keys are ssh-add'd from env.nu
;; (see ssh-load-keys) rather than during activation because shepherd
;; may not be up yet at that phase.
(define %ssh-agent-shepherd-service
  (simple-service 'ssh-agent
                  home-shepherd-service-type
                  (list
                   (shepherd-service
                    (provision '(ssh-agent))
                    (documentation "OpenSSH agent — key store for the session.")
                    (auto-start? #t)
                    (respawn? #t)
                    (start
                     #~(make-forkexec-constructor
                        (list #$(file-append openssh "/bin/ssh-agent")
                              "-D"    ;foreground
                              "-a"    ;socket path
                              (string-append
                               (or (getenv "XDG_RUNTIME_DIR")
                                   (string-append (getenv "HOME") "/.local/state"))
                               "/ssh-agent.sock"))))
                    (stop #~(make-kill-destructor))))))

;; ========================================
;; ZELLIJ PLUGINS
;; ========================================

;; Drop the WASM plugins into ~/.config/zellij/plugins/ so config.kdl
;; references like `plugin location="file:~/.config/zellij/plugins/zjstatus.wasm"`
;; resolve.  Kept as file-append so the plugins move with package upgrades.
(define %zellij-plugins-service
  (simple-service 'zellij-plugins
                  home-files-service-type
                  `((".config/zellij/plugins/zjstatus.wasm"
                     ,(file-append zjstatus
                                   "/share/zellij/plugins/zjstatus.wasm"))
                    (".config/zellij/plugins/room.wasm"
                     ,(file-append zellij-room
                                   "/share/zellij/plugins/room.wasm")))))

;; ========================================
;; PIKNIK
;; ========================================

;; piknik server binds on this address; clients elsewhere connect via
;; Tailscale (or LAN).  Connect is a placeholder for loopback tests.
(define %piknik-listen  "0.0.0.0:8075")
(define %piknik-connect "127.0.0.1:8075")

;; Create the log dir the Shepherd server writes to and the parts dir
;; the 1Password provisioner drops per-field keyset files into.
(define %piknik-dirs-service
  (simple-service 'piknik-dirs home-activation-service-type
    #~(let* ((home  (getenv "HOME"))
             (state (or (getenv "XDG_STATE_HOME")
                        (string-append home "/.local/state")))
             (log   (string-append state "/log"))
             (parts (string-append home "/.piknik.parts")))
        (mkdir-p log)
        (mkdir-p parts)
        (chmod parts #o700))))

;; ========================================
;; 1PASSWORD-PROVISIONED SECRETS
;; ========================================

;; SSH keys downloaded by make-op-items-provision-service on activation.
;; Each tuple: (op-URI dest-rel-to-$HOME mode).  Idempotent: existing
;; files skip the op read.
(define %op-provisioned-items
  '(("op://Personal/PERSONAL GITHUB SSH/private key?ssh-format=openssh"
     ".ssh/personal.github.id_ed25519" #o600)
    ("op://Personal/LOCAL SSH CLIENT KEY/private key?ssh-format=openssh"
     ".ssh/eva.personal.id_dropbear" #o600)
    ("op://Personal/CODEBERG SSH KEY/private key?ssh-format=openssh"
     ".ssh/codeberg.id_ed25519" #o600)))

;; ========================================
;; COMPOSE HOME ENVIRONMENT
;; ========================================

(define dotfiles-home-environment
  (home-environment
    (packages (append %base-packages
                      (if (getenv "TEST") %dev-packages
                          '())))
    (services
     (list
      %channels-service
      %micro-plugins-service
      %zellij-plugins-service
      %dotfiles-service
      %ssh-service
      %ssh-agent-shepherd-service
      %nushell-service
      ;; Piknik: dirs first, then server, then provisioning (needs op).
      %piknik-dirs-service
      %piknik-server-service
      (make-piknik-provision-service
       #:listen %piknik-listen
       #:connect %piknik-connect)
      ;; Secrets provisioned from 1Password (SSH keys, see %op-provisioned-items).
      (make-op-items-provision-service
       #:package onepassword-cli
       #:items %op-provisioned-items)
      ;; op-account-add MUST be last in the services list so it runs FIRST
      ;; during home activation (Guix runs activation gexps in reverse list
      ;; order).  Account must be registered before provisioners sign in.
      (make-op-account-add-service #:package onepassword-cli)))))

;; Export for direct use
dotfiles-home-environment
