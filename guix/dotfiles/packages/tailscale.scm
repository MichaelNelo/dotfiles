;; -*- mode: scheme; -*-
;; Tailscale VPN — static binaries from official releases.
;;
;; To update:
;;   1. Latest version:
;;        curl -sL https://pkgs.tailscale.com/stable/ \
;;          | grep -oP 'tailscale_[0-9.]+_amd64\.tgz' | head -1
;;   2. Download + hash:
;;        wget URL -O /tmp/tailscale.tgz && guix hash /tmp/tailscale.tgz

(define-module (dotfiles packages tailscale)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system copy)
  #:use-module (nonguix licenses)
  #:export (tailscale))

(define-public tailscale
  (package
    (name "tailscale")
    (version "1.98.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://pkgs.tailscale.com/stable/tailscale_"
                           version "_amd64.tgz"))
       (sha256
        (base32 "076jiaxhrkcmrbky3fy10kckjz9m8j1m3czgxkdgpgz86pk2pq5a"))))
    (build-system copy-build-system)
    (arguments
     `(#:install-plan '(("tailscale"  "bin/")
                        ("tailscaled" "bin/"))))
    (home-page "https://tailscale.com")
    (synopsis "Mesh VPN built on WireGuard")
    (description
     "Tailscale is a mesh VPN that makes it easy to connect your devices.
It builds on top of WireGuard and provides automatic key management,
NAT traversal, and access control.")
    (license (nonfree "https://tailscale.com/terms"))))

tailscale
