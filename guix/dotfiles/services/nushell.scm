;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2025 mknelo <mknelo@protonmail.com>
;;;
;;; This file is part of GNU Guix.
;;;
;;; GNU Guix is free software; you can redistribute it and/or modify it
;;; under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3 of the License, or (at
;;; your option) any later version.
;;;
;;; GNU Guix is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Guix.  If not, see <http://www.gnu.org/licenses/>.

(define-module (dotfiles services nushell)
  #:use-module (gnu services configuration)
  #:use-module (gnu home services)
  #:use-module (gnu home services utils)
  #:use-module (gnu packages nushell)
  #:use-module (gnu packages shells)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix records)
  #:use-module (srfi srfi-13)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:export (home-nushell-service-type
            home-nushell-configuration
            home-nushell-extension
            %nushell-service
            make-nushell-service))

;; ========================================
;; Environment variable quoting for nushell
;; ========================================

(define (nushell-escape-string value)
  "Escape VALUE for use in nushell double-quoted strings.
Escapes backslash, dollar sign, and double quote."
  (define (escape-char c)
    (cond
     ((char=? c #\\) "\\\\")
     ((char=? c #\$) "\\$")
     ((char=? c #\") "\\\"")
     (else c)))
  (apply string (map escape-char (string->list value))))

;; ========================================
;; Configuration definition
;; ========================================

(define (serialize-nushell-env-vars field-name val)
  "Serialize ALIST of environment variables to nushell syntax.
Produces lines like: $env.VAR = \"value\""
  #~(string-append
     #$@(map
         (lambda (pair)
           (let ((key (car pair))
                 (value (cdr pair)))
             (cond
              ((eq? value #f)
               #~(string-append "$env." #$key " = null\n"))
              ((eq? value #t)
               #~(string-append "$env." #$key " = true\n"))
              ((string? value)
               #~(string-append "$env." #$key " = \""
                                #$(nushell-escape-string value)
                                "\"\n"))
              (else ""))))
         val)))

(define (serialize-nushell-aliases field-name val)
  "Serialize ALIST of aliases to nushell syntax.
Simple commands (no spaces) use `alias`. Complex commands use `def`."
    #~(begin
        (string-append
         #$@(map
             (lambda (pair)
               (let ((key (car pair))
                     (value (cdr pair)))
                 (cond
                  ((not (string? value)) "")
                  ;; Commands with spaces need `def` instead of `alias`
                  ((string-contains value " ")
                   #~(string-append "def " #$key " [] {"
                                    #$(nushell-escape-string value)
                                    "}\n"))
                  (else
                   #~(string-append "alias " #$key " = \""
                                    #$(nushell-escape-string value)
                                    "\"\n")))))
             val))))

(define (serialize-nushell-abbreviations field-name val)
  "Serialize ALIST of abbreviations to nushell syntax."
  #~(string-append
     #$@(map
         (lambda (pair)
           (let ((key (car pair))
                 (value (cdr pair)))
             (if (and (string? key) (string? value))
                 #~(string-append "abbr " #$key " \""
                                  #$(nushell-escape-string value)
                                  "\"\n")
                 "")))
         val)))

(define-configuration home-nushell-configuration
  (package
    (package nushell)
    "The Nushell package to use.")
  (environment-variables
   (alist '())
   "Association list of environment variables to set in Nushell.
Values are written as `$env.VAR = \"value\"` in @file{env.nu}.
Boolean values @code{#t} produce @code{true}, @code{#f} produces @code{null}."
   (serializer serialize-nushell-env-vars))
  (aliases
   (alist '())
   "Association list of aliases to set in Nushell.
Each entry produces an @code{alias NAME = \"COMMAND\"} line in @file{config.nu}."
   (serializer serialize-nushell-aliases))
  (abbreviations
   (alist '())
   "Association list of abbreviations to set in Nushell.
Each entry produces an @code{abbr KEY \"VALUE\"} line in @file{config.nu}."
   (serializer serialize-nushell-abbreviations))
  (config-nu
   (text-config '())
   "List of file-like objects, which will be added to @file{config.nu}.
This is the main Nushell configuration file, loaded at startup.")
  (env-nu
   (text-config '())
   "List of file-like objects, which will be added to @file{env.nu}.
This file is loaded when Nushell starts to set up environment variables.")
  (login-nu
   (text-config '())
   "List of file-like objects, which will be added to @file{login.nu}.
This file is sourced when Nushell starts as a login shell."))

;; ========================================
;; Helper functions
;; ========================================

(define (nushell-config-file config)
  "Generate .config/nushell/config.nu from CONFIG.
Contains: aliases, abbreviations, config-nu." 
  (mixed-text-file
   "config.nu"
   "# Nushell configuration file\n\n"
   (serialize-configuration
    config
    (filter-configuration-fields
     home-nushell-configuration-fields
     '(aliases abbreviations config-nu)))))

(define (nushell-env-file config)
  "Generate .config/nushell/env.nu from CONFIG.
Contains: environment-variables, env-nu." 
  (mixed-text-file
   "env.nu"
   "# Nushell environment variables file\n\n"
   (serialize-configuration
    config
    (filter-configuration-fields
     home-nushell-configuration-fields
     '(environment-variables env-nu)))))

(define (nushell-login-file config)
  "Generate .config/nushell/login.nu from CONFIG.
Contains: login-nu." 
  (mixed-text-file
   "login.nu"
   "# Nushell login script\n\n"
   "source $nu.config-path\n"
   "source $nu.env-path\n\n"
   (serialize-configuration
    config
    (filter-configuration-fields
     home-nushell-configuration-fields
     '(login-nu)))))

(define (nushell-files config)
  "Return list of file-like objects for all nushell files."
  `((".config/nushell/config.nu" ,(nushell-config-file config))
    (".config/nushell/env.nu"     ,(nushell-env-file config))
    (".config/nushell/login.nu"   ,(nushell-login-file config))))

(define (nushell-packages config)
  "Return the nushell package for the profile."
  (list (home-nushell-configuration-package config)))

;; ========================================
;; Service type definition
;; ========================================

(define-configuration/no-serialization home-nushell-extension
  (environment-variables
   (alist '())
   "Additional environment variables to set.")
  (aliases
   (alist '())
   "Additional aliases to set.")
  (abbreviations
   (alist '())
   "Additional abbreviations to set.")
  (config-nu
   (text-config '())
   "Additional content for @file{config.nu}.")
  (env-nu
   (text-config '())
   "Additional content for @file{env.nu}.")
  (login-nu
   (text-config '())
   "Additional content for @file{login.nu}."))

(define (home-nushell-extensions original-config extension-configs)
  "Merge EXTENSION-CONFIGS into ORIGINAL-CONFIG."
  (home-nushell-configuration
   (inherit original-config)
   (environment-variables
    (append (home-nushell-configuration-environment-variables original-config)
            (append-map
             home-nushell-extension-environment-variables extension-configs)))
   (aliases
    (append (home-nushell-configuration-aliases original-config)
            (append-map
             home-nushell-extension-aliases extension-configs)))
   (abbreviations
    (append (home-nushell-configuration-abbreviations original-config)
            (append-map
             home-nushell-extension-abbreviations extension-configs)))
   (config-nu
    (append (home-nushell-configuration-config-nu original-config)
            (append-map
             home-nushell-extension-config-nu extension-configs)))
   (env-nu
    (append (home-nushell-configuration-env-nu original-config)
            (append-map
             home-nushell-extension-env-nu extension-configs)))
   (login-nu
    (append (home-nushell-configuration-login-nu original-config)
            (append-map
             home-nushell-extension-login-nu extension-configs)))))

(define home-nushell-service-type
  (service-type (name 'home-nushell)
                (extensions
                 (list (service-extension
                        home-files-service-type
                        nushell-files)
                       (service-extension
                        home-profile-service-type
                        nushell-packages)))
                (compose identity)
                (extend home-nushell-extensions)
                (default-value (home-nushell-configuration))
                (description "Install and configure Nushell.")))

;; ========================================
;; Default service and factory function
;; ========================================

(define %nushell-service
  (service home-nushell-service-type
           (home-nushell-configuration)))

(define* (make-nushell-service
          #:key
          (package nushell)
          (environment-variables '())
          (aliases '())
          (abbreviations '())
          (config-nu '())
          (env-nu '())
          (login-nu '()))
  "Create a Nushell home service with custom configuration."
  (service home-nushell-service-type
           (home-nushell-configuration
            (package package)
            (environment-variables environment-variables)
            (aliases aliases)
            (abbreviations abbreviations)
            (config-nu config-nu)
            (env-nu env-nu)
            (login-nu login-nu))))
