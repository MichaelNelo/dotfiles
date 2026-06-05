(define-module (packages llama-cpp)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix gexp)
  #:use-module (guix utils)
  #:use-module (gnu packages machine-learning)
  #:use-module (guix-science-nonfree packages cuda))

(define commit
  "4fb16eccce5e451b40014355f97374d692480a4d")

(define commit-hash
  "1z6995lkfznygf50zsqi3l6kr88jnzhdfcf2hsxjzjrnxalm7711")

(define (ui-asset name hash)
  (origin
    (method url-fetch)
    (uri (string-append
          "https://huggingface.co/buckets/ggml-org/llama-ui/resolve/latest/"
          name))
    (file-name (string-append "llama-ui-" name))
    (sha256 (base32 hash))))

(define ui-index-html
  (ui-asset "index.html"
            "1wsapkb24yhh51zqs93s4izy6nhm2blxk15d64pwqvj5d6n6v99y"))

(define ui-bundle-js
  (ui-asset "bundle.js" "12wf5gzm3mb7yxab34k325kkn1ixay5zlfrgrbj0wv6msngglyfr"))

(define ui-bundle-css
  (ui-asset "bundle.css"
            "0dx1q64m25l64amswjhfw7c3yj8hdvz79vh7cymj2dr4njqqsxfy"))

(define ui-loading-html
  (ui-asset "loading.html"
            "1p1wf1xrwbc66c6s7cj7pf5ba1v1kw0mv3xj2s6m30db75z0a015"))

(define-public llama-cpp-4f13cb
  (package
    (inherit llama-cpp)
    (version (string-append "0.0.0-" commit))
    (source
     (origin
       (inherit (package-source llama-cpp))
       (uri (git-reference
             (inherit (origin-uri (package-source llama-cpp)))
             (commit commit)))
       (sha256
        (base32 commit-hash))))
    (native-inputs (append (package-native-inputs llama-cpp)
                           `(("ui-index-html" ,ui-index-html)
                             ("ui-bundle-js" ,ui-bundle-js)
                             ("ui-bundle-css" ,ui-bundle-css)
                             ("ui-loading-html" ,ui-loading-html)
                             ("cuda" ,cuda-12.9))))
    (arguments
     (substitute-keyword-arguments (package-arguments llama-cpp)
       ((#:tests? _ #f)
        #f)
       ((#:validate-runpath? _ #f)
        #f)
       ((#:configure-flags _)
        #~(list "-DBUILD_SHARED_LIBS=ON" "-DLLAMA_USE_SYSTEM_GGML=OFF"
                "-DLLAMA_BUILD_UI=ON" "-DGGML_CUDA=ON"
                "-DCMAKE_CUDA_ARCHITECTURES=120"))
       ((#:phases phases)
        #~(modify-phases #$phases
            (delete 'fix-python-shebang)
            (add-after 'unpack 'provide-ui-assets
              (lambda* (#:key inputs #:allow-other-keys)
                (let ((dist-dir "build/tools/ui/dist"))
                  (mkdir-p dist-dir)
                  (for-each (lambda (pair)
                              (copy-file (assoc-ref inputs
                                                    (car pair))
                                         (string-append dist-dir "/"
                                                        (cdr pair))))
                            '(("ui-index-html" . "index.html")
                              ("ui-bundle-js" . "bundle.js")
                              ("ui-bundle-css" . "bundle.css")
                              ("ui-loading-html" . "loading.html"))))))
            (add-after 'fix-tests 'disable-test-chat
              (lambda _
                (substitute* '("tests/CMakeLists.txt")
                  (("llama_build_and_test\\(test-chat\\.cpp.*")
                   "")
                  (("target_include_directories\\(test-chat .*")
                   "")
                  (("target_link_libraries\\(test-chat .*")
                   "")
                  (("set_tests_properties\\(test-chat .*")
                   ""))))))))))

llama-cpp-4f13cb
