(define-module (dotfiles packages jadx)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system copy)
  #:use-module (guix gexp)
  #:use-module ((guix licenses)
                #:prefix license:)
  #:use-module (gnu packages base)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages elf)
  #:use-module ((gnu packages java) #:select (openjdk21)))

;; jadx release ZIP layout (verified via `unzip -l`):
;;   bin/{jadx,jadx-gui,*.bat}
;;   lib/jadx-<version>-all.jar
;;   LICENSE, README.md
;;
;; The default `unpack` phase in copy-build-system passes .zip files
;; to tar which fails silently, leaving the build dir empty — hence
;; the "stat bin/: No such file or directory" failure on `install`.
;; We override `unpack` to invoke `unzip` explicitly, then use the
;; install-plan as normal.
(define-public jadx
  (package
    (name "jadx")
    (version "1.5.6")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/skylot/jadx/releases/download/v"
                           version
                           "/jadx-"
                           version
                           ".zip"))
       (sha256
        (base32 "0x491qijmnnknkw9dq3657jav194v95wymap2jy12994kjza4pjl"))))
    (build-system copy-build-system)
    (native-inputs (list unzip))
    ;; Propagated so `java` ends up in the user's profile PATH when
    ;; they install jadx; the wrapper scripts in bin/ call `java`
    ;; unqualified, so it must be findable at runtime.
    (propagated-inputs (list openjdk21))
    (arguments
     (list
      #:install-plan
      #~'(("bin/" "bin/")
          ("lib/" "lib/"))
      #:phases
      #~(modify-phases %standard-phases
          (replace 'unpack
            (lambda* (#:key source #:allow-other-keys)
              (invoke #$(file-append unzip "/bin/unzip") "-q" source))))))
    (home-page "https://github.com/skylot/jadx")
    (synopsis "Dex to Java decompiler")
    (description "Command line and GUI tools for producing Java source code from Android Dex and Apk files")
    (license license:asl2.0)))

jadx
