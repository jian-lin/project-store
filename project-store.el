;;; project-store.el --- Project backend for Nix store  -*- lexical-binding: t; -*-

;; SPDX-FileCopyrightText: 2026 Lin Jian <me@linj.tech>
;; SPDX-License-Identifier: GPL-3.0-or-later

;; Author: Lin Jian <me@linj.tech>
;; URL: https://github.com/jian-lin/project-store
;; Keywords: nix store project tools
;; Version: 0.9.0
;; Package-Requires: ((emacs "29.1"))

;;; Commentary:

;; Refer to README or `describe-package'.

;;; Code:

(eval-when-compile (require 'cl-lib))

(defgroup project-store ()
  "Project backend for Nix store."
  :group 'project
  :prefix "project-store-"
  :link '(url-link
          :tag "Nix store"
          "https://nix.dev/manual/nix/2.35/store/index.html")
  :link '(info-link "(emacs) Projects"))

(defvar project-store--cached-projects (make-hash-table :test 'equal)
  "Cache for `project-store-try'.")

(defvar project-store--cached-project-names (make-hash-table :test 'equal)
  "Cache for `project-name'.")

(defun project-store--set-dir (symbol value)
  "Set `project-store-dirs' after invalidating cache.
SYMBOL and VALUE are passed to `set-default-toplevel-value'.
VALUE is preprocessed by `file-name-as-directory'."
  (clrhash project-store--cached-projects)
  (clrhash project-store--cached-project-names)
  (set-default-toplevel-value symbol (mapcar #'file-name-as-directory value)))

(defcustom project-store-dirs '("/nix/store/")
  "A list of store directories.

See URL `https://nix.dev/manual/nix/2.35/store/store-path.html#store-directory-path'."
  :type '(repeat directory)
  ;; TODO set :initialize when Emacs bug#81396 is fixed
  ;; :initialize #'custom-initialize-changed
  :set #'project-store--set-dir
  :link '(url-link
          :tag "store directory definition"
          "https://nix.dev/manual/nix/2.35/store/store-path.html#store-directory-path"))

;;;###autoload
(defun project-store-try (dir)
  "Return a store project instance of DIR.
DIR should be a store path or a child dir of a store path.
Otherwise, return nil.

See `project-root' for store path definition."
  (let ((cached-project (with-memoization
                            (gethash dir project-store--cached-projects)
                          (or (project-store--try-without-cache dir)
                              ;; `with-memoization' can't distinguish nil and "no value yet".
                              ;; Use symbol `not-found' to represent nil.
                              'not-found))))
    (unless (eq cached-project 'not-found)
      cached-project)))

(defun project-store--try-without-cache (dir)
  "Like `project-store-try', but do not use cache.
See `project-store-try' for DIR and return value."
  (cl-loop for project-store-dir in project-store-dirs
           thereis
           (when (and (string-prefix-p project-store-dir dir)
                      (not (string= dir project-store-dir)))
             (cl-loop for project-root = dir then project-root-parent
                      for project-root-parent = (file-name-parent-directory project-root)
                      until (string= project-root-parent project-store-dir)
                      finally return (list 'store project-root project-store-dir)))))

(cl-defmethod project-root ((project (head store)))
  "Return PROJECT store path.

See URL `https://nix.dev/manual/nix/2.35/store/store-path.html#store-path'
for store path definition."
  (nth 1 project))

(defun project-store--set-name-prefix (symbol value)
  "Set `project-store-name-prefix' after invalidating cache.
SYMBOL and VALUE are passed to `set-default-toplevel-value'."
  (clrhash project-store--cached-project-names)
  (set-default-toplevel-value symbol value))

(defcustom project-store-name-prefix "/S/"
  "Prefix of `project-name' for store projects."
  :type 'string
  ;; TODO set :initialize when Emacs bug#81396 is fixed
  ;; :initialize #'custom-initialize-changed
  :set #'project-store--set-name-prefix)

(cl-defmethod project-name ((project (head store)))
  "Return `project-store-name-prefix' and store path name for PROJECT.

See `project-root' for store path definition."
  (let ((project-root (project-root project)))
    (with-memoization
        (gethash project-root project-store--cached-project-names)
      (concat project-store-name-prefix
              (substring (directory-file-name project-root)
                         (+ (length (nth 2 project))
                            ;; length of digest and a hyphen
                            33))))))

;; `project-store-p' is called by `project-remember-project' via `project-list-exclude'.
;; It is possible to call `project-store-p' before the autoloaded `project-store-try'.
;; So autoload it, too.
;;;###autoload
(defun project-store-p (project)
  "Return t if PROJECT is a store project."
  (eq (car-safe project) 'store))

(defun project-store-unload-function ()
  "Do extra cleanup when called by `unload-feature'."
  (defvar unload-feature-special-hooks)
  (cl-flet ((remove-hook-when-needed (hook function)
              (when (and
                     ;; https://debbugs.gnu.org/cgi/bugreport.cgi?bug=81550
                     (not (memq hook unload-feature-special-hooks))
                     (boundp hook))
                (remove-hook hook function))))
    (remove-hook-when-needed 'project-find-functions #'project-store-try)
    (remove-hook-when-needed 'project-list-exclude #'project-store-p))
  ;; The standard unloading proceeds.
  nil)

(provide 'project-store)

;;; project-store.el ends here
