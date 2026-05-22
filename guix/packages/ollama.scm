(define-module (packages ollama)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build utils)
  #:use-module (guix build-system copy)
  #:use-module (guix gexp)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages base)
  #:use-module (gnu packages gcc)
  #:use-module ((guix licenses)
                #:prefix license:)
  #:use-module (gnu packages compression))

(define-public ollama
  (package
    (name "ollama")
    (version "master")
    (source
     (origin
       (method url-fetch)
       (uri "https://ollama.com/download/ollama-linux-amd64.tar.zst")
       (sha256
        (base32 "1nywgijy2limpclhjxl29vhndg9dc5l8ipqr8wxhsvm0dgbgii8m"))))
    (build-system copy-build-system)
    (arguments
     (list
      #:validate-runpath? #f
      #:install-plan
      #~`(("../bin/ollama" "bin/ollama")
          ("../lib/" "lib"))
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'install 'patchelf
            (lambda* (#:key inputs outputs #:allow-other-keys)
              (let* ((ollama-out (assoc-ref outputs "out"))
                     (ldd (search-input-file inputs
                                             "/lib/ld-linux-x86-64.so.2"))
                     (patchelf (search-input-file inputs "/bin/patchelf"))
                     (libgcc (search-input-file inputs "/lib/libgcc_s.so.1"))
                     (libc (search-input-file inputs "/lib/libc.so.6"))
                     (gcc-lib (dirname libgcc))
                     (glibc-lib (dirname libc))
                     (ollama-lib (string-append ollama-out "/lib/ollama"))
                     (vulkan-lib (string-append ollama-lib "/vulkan"))
                     (cuda-v12 (string-append ollama-lib "/cuda_v12"))
                     (cuda-v13 (string-append ollama-lib "/cuda_v13"))
                     (lib-rpath (string-join (list gcc-lib
                                                   glibc-lib
                                                   ollama-lib
                                                   vulkan-lib
                                                   cuda-v12
                                                   cuda-v13) ":"))
                     (ollama (string-append ollama-out "/bin/ollama")))
                (chmod ollama #o755)
                (invoke patchelf
                        "--set-rpath"
                        (string-join (list gcc-lib glibc-lib ollama-lib) ":")
                        "--set-interpreter"
                        ldd
                        ollama)
                (for-each (lambda (so)
                            (chmod so #o755)
                            (invoke patchelf "--set-rpath" lib-rpath so))
                          (find-files (string-append ollama-out "/lib")
                                      "\\.so(\\..*)?$"))))))))
    (native-inputs `(("patchelf" ,patchelf)
                     ("glibc" ,glibc)
                     ("zstd" ,zstd)))
    (inputs (list `(,gcc "lib")))
    (home-page "https://ollama.com")
    (synopsis "The easiest way to build with open models")
    (description
     "Ollama is the easiest way to get up and running with large language models such as gpt-oss, Gemma 3, DeepSeek-R1, Qwen3 and more.")
    (license license:expat)))

ollama
