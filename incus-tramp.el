;;; incus-tramp.el --- TRAMP integration for Incus -*- lexical-binding:t; coding:utf-8 -*-
;;
;; Copyright (C) 2026 Roman Isaev
;;
;; Author: Roman Isaev <mdnight@riseup.net>
;; Maintainer: Roman Isaev <mdnight@riseup.net>
;; Keywords: tramp, incus, containers, extensions
;; Package: incus-tramp
;; Package-Version: 0.1.0
;; Package-Requires: ((emacs "30.1"))

;; This file is not part of GNU Emacs.

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Allows Tramp access to environments provided by Incus.
;;
;; ## Usage
;;
;; Open a file on a running Incus container:
;;
;;     C-x C-f /incus:CONTAINER:/path/to/file
;;
;; Where:
;;     CONTAINER     is the container to connect to.

;;; Code:

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
