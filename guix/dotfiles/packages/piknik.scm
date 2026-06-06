(define-module (dotfiles packages piknik)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix build-system go)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages golang)
  #:use-module (gnu packages golang-build)
  #:use-module (gnu packages golang-crypto)
  #:use-module (gnu packages golang-xyz))

(define-public piknik
  (package
    (name "piknik")
    (version "0.10.2")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/jedisct1/piknik")
             (commit version)))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0dr6v4qnq72d5y9a72l522vnaq5flx7qbdhms69lhfrfqkga3ni9"))))
    (build-system go-build-system)
    (arguments
     (list #:go go-1.24
           #:import-path "github.com/jedisct1/piknik"
           #:install-source? #f))
    (propagated-inputs
     (list go-github-com-burntsushi-toml
           go-github-com-minio-blake2b-simd
           go-github-com-mitchellh-go-homedir
           go-golang-org-x-crypto
           go-golang-org-x-term))
    (home-page "https://github.com/jedisct1/piknik")
    (synopsis "Copy/paste anything over the network with E2E encryption")
    (description
     "Piknik is a small utility to copy/paste content between machines over
TCP using authenticated end-to-end encryption.  It supports a server/client
model that works through NAT gateways without needing SSH.")
    (license license:bsd-2)))

piknik
