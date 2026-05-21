;;; incus-tramp.el --- TRAMP integration for Incus -*- lexical-binding:t; coding:utf-8 -*-
;;
;; Copyright (C) 2026 Roman Isaev
;;
;; Author: Roman Isaev <mdnight@riseup.net>
;; Maintainer: Roman Isaev <mdnight@riseup.net>
;; Keywords: tramp, incus, containers, extensions
;; Package: incus-tramp
;; Package-Version: 0.0.1
;; Package-Requires: ((emacs "30.0"))

(require 'tramp)
(require 'subr-x)

(defgroup incus-tramp nil
  "TRAMP integration for Incus."
  :group 'tramp)

(defcustom incus-tramp-incus-program "incus"
  "Path to the Incus executable."
  :type 'string
  :group 'incus-tramp)

;;;###autoload
(defconst incus-tramp-method "incus"
  "Tramp method name to connect to Incus containers.")

(defun tramp-incus-completion-function (method)
  (tramp-skeleton-completion-function method
    (when-let* ((raw-list (shell-command-to-string
                           (concat program " list status=running --columns=n --format=csv")))
                (names (split-string raw-list "\n" 'omit)))
      (mapcar (lambda (name) (list nil name)) names))))

;;;###autoload
(defun incus-tramp-enable-method ()
  (interactive)
  (with-eval-after-load 'tramp
    (add-to-list 'tramp-methods
                 `(,incus-tramp-method
                   (tramp-login-program ,incus-tramp-incus-program)
                   (tramp-login-args (("exec") ("%h") (,(format "--env TERM=%s" tramp-terminal-type)) ("--") ("%l")))
                   (tramp-direct-async (,tramp-default-remote-shell "-c"))
                   (tramp-remote-shell ,tramp-default-remote-shell)
                   (tramp-remote-shell-login ("-l"))
                   (tramp-remote-shell-args ("-i" "-c"))
                   (tramp-completion-use-cache nil)
                   (tramp-connection-timeout 60)))
    (tramp-set-completion-function incus-tramp-method
                                   `((tramp-incus-completion-function ,incus-tramp-method)))
    (add-to-list 'tramp-completion-multi-hop-methods incus-tramp-method)))

(provide 'incus-tramp)
