(define-module (services ollama)
  #:use-module (gnu home services shepherd)
  #:use-module (gnu packages commencement)
  #:use-module (guix gexp)
  #:use-module (packages ollama)
  #:export (ollama-shepherd-service))

(define ollama-shepherd-service
  (shepherd-service (provision '(ollama))
                    (documentation "Ollama LLM server (ollama serve)")
                    (start #~(make-forkexec-constructor (list #$(file-append
                                                                 ollama
                                                                 "/bin/ollama")
                                                              "serve")
                                                        #:log-file (string-append
                                                                    (getenv
                                                                     "HOME")
                                                                    "/.local/var/log/ollama.log")
                                                        #:environment-variables
                                                        (append (environ)
                                                                (list (string-append
                                                                       "LD_LIBRARY_PATH="
                                                                       #$(file-append
                                                                          ollama
                                                                          "/lib/ollama")
                                                                       ":"
                                                                       #$(file-append
                                                                          ollama
                                                                          "/lib/ollama/vulkan")
                                                                       ":"
                                                                       #$(file-append
                                                                          ollama
                                                                          "/lib/ollama/cuda_v12")
                                                                       ":"
                                                                       #$(file-append
                                                                          ollama
                                                                          "/lib/ollama/cuda_v13")
                                                                       ":"
                                                                       #$(file-append
                                                                          gcc-toolchain
                                                                          "/lib")
                                                                       ":"
                                                                       "/usr/lib/wsl/lib")
                                                                 "OLLAMA_CONTEXT_LENGTH=131072"))))
                    (stop #~(make-kill-destructor SIGKILL))
                    (respawn? #t)))
