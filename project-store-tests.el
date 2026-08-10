;;; project-store-tests.el --- Test project-store  -*- lexical-binding: t; -*-

;; SPDX-FileCopyrightText: 2026 Lin Jian <me@linj.tech>
;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:

;;; Code:

(require 'project-store)
(require 'ert)
(require 'subr-x)
(eval-when-compile (require 'cl-lib))

(ert-deftest project-store-try ()
  (let ((project-store-dir "/nix/store/")
        (project-to-dirs
         '(nil
           ("/" "/nix" "/nix/store/"
            "/home/" "/home/me/" "/home/me/project/" "/home/me/project/nixpkgs/"
            "/root/" "/var/" "/var/lib/" "/tmp/")
           (store . "/nix/store/jnhsnfz13w8ailk2lfs2pvamwa35mxzs-emacs-packages-deps/")
           ("/nix/store/jnhsnfz13w8ailk2lfs2pvamwa35mxzs-emacs-packages-deps/"
            "/nix/store/jnhsnfz13w8ailk2lfs2pvamwa35mxzs-emacs-packages-deps/share/"
            "/nix/store/jnhsnfz13w8ailk2lfs2pvamwa35mxzs-emacs-packages-deps/share/emacs/"
            "/nix/store/jnhsnfz13w8ailk2lfs2pvamwa35mxzs-emacs-packages-deps/share/emacs/site-lisp/"
            "/nix/store/jnhsnfz13w8ailk2lfs2pvamwa35mxzs-emacs-packages-deps/share/emacs/site-lisp/elpa/"
            "/nix/store/jnhsnfz13w8ailk2lfs2pvamwa35mxzs-emacs-packages-deps/share/emacs/site-lisp/elpa/project-0.11.2/")
           (store . "/nix/store/xxywqayx584zfal9d3h0smk5k2slyk44-emacs-30.2/")
           ("/nix/store/xxywqayx584zfal9d3h0smk5k2slyk44-emacs-30.2/"
            "/nix/store/xxywqayx584zfal9d3h0smk5k2slyk44-emacs-30.2/share/"
            "/nix/store/xxywqayx584zfal9d3h0smk5k2slyk44-emacs-30.2/share/emacs/"
            "/nix/store/xxywqayx584zfal9d3h0smk5k2slyk44-emacs-30.2/share/emacs/30.2/"
            "/nix/store/xxywqayx584zfal9d3h0smk5k2slyk44-emacs-30.2/share/emacs/30.2/lisp/"
            "/nix/store/xxywqayx584zfal9d3h0smk5k2slyk44-emacs-30.2/share/emacs/30.2/lisp/progmodes/"))))
    (cl-loop
     for (project dirs) on project-to-dirs by #'cddr
     do (ert-info ((format "%S" project) :prefix "project = ")
          (cl-loop
           for dir in dirs
           do (ert-info ((format "%S" dir) :prefix "dir = ")
                (let ((project-store--cached-projects (make-hash-table :test 'equal)))
                  (ert-info ("run without cache")
                    (should (equal (project-store-try dir)
                                   project)))
                  (ert-info ("cache is created")
                    (ert-info ((format "%S" project-store--cached-projects)
                               :prefix "cache = ")
                      (should (equal (gethash dir project-store--cached-projects)
                                     (or project 'not-found)))))
                  (ert-info ("run with cache")
                    (should (equal (project-store-try dir)
                                   project))))))))))

(ert-deftest project-store-root ()
  "Test `project-root' called with a project-store instance."
  (let ((project-and-roots
         (list '(store . "/nix/store/jnhsnfz13w8ailk2lfs2pvamwa35mxzs-emacs-packages-deps/")
               "/nix/store/jnhsnfz13w8ailk2lfs2pvamwa35mxzs-emacs-packages-deps/"
               '(store . "/nix/store/xxywqayx584zfal9d3h0smk5k2slyk44-emacs-30.2/")
               "/nix/store/xxywqayx584zfal9d3h0smk5k2slyk44-emacs-30.2/")))
    (cl-loop for (project project-root) on project-and-roots by #'cddr
             do (ert-info ((format "%S" project) :prefix "project = ")
                  (should (equal (project-root project)
                                 project-root))))))

(ert-deftest project-store-name ()
  "Test `project-name' called with a project-store instance."
  (let ((project-store-dir "/nix/store/")
        (project-and-name-suffixes
         (list
          '(store . "/nix/store/jnhsnfz13w8ailk2lfs2pvamwa35mxzs-emacs-packages-deps/")
          "emacs-packages-deps"
          '(store . "/nix/store/xxywqayx584zfal9d3h0smk5k2slyk44-emacs-30.2/")
          "emacs-30.2")))
    (cl-loop
     for (project project-name-suffix) on project-and-name-suffixes by #'cddr
     do (ert-info ((format "%S" project) :prefix "project = ")
          (cl-loop
           for project-store-name-prefix in '("/S/" "/store/" "<store>")
           do (ert-info ((format "%S" project-store-name-prefix)
                         :prefix "project-store-name-prefix = ")
                (let ((project-store--cached-project-names (make-hash-table :test 'equal))
                      (project-name (concat project-store-name-prefix project-name-suffix)))
                  (ert-info ("run without cache")
                    (should (equal (project-name project)
                                   project-name)))
                  (ert-info ("cache is created")
                    (ert-info ((format "%S" project-store--cached-project-names)
                               :prefix "cache = ")
                      (should (equal (gethash (project-root project)
                                              project-store--cached-project-names)
                                     project-name))))
                  (ert-info ("run with cache")
                    (should (equal (project-name project)
                                   project-name))))))))))

(cl-defstruct project-store-tests--dummy-project-type
  "A dummy project type for test."
  root)

(ert-deftest project-store-p ()
  (cl-loop for store-project in
           (list '(store . "/nix/store/jnhsnfz13w8ailk2lfs2pvamwa35mxzs-emacs-packages-deps/")
                 '(store . "/nix/store/xxywqayx584zfal9d3h0smk5k2slyk44-emacs-30.2/"))
           do (should (project-store-p store-project)))
  (cl-loop for non-store-project in
           (list '(vc Git "~/code/fork/nixpkgs/")
                 '(transient . "~/code/fork/nixpkgs/")
                 (make-project-store-tests--dummy-project-type :root "~/code/fork/nixpkgs/"))
           do (should-not (project-store-p non-store-project))))

(defmacro project-store-tests-save-value (symbol &rest body)
  "Record SYMBOL's value; evaluate BODY in `progn'; restore SYMBOL's value.
SYMBOL should evaluate to a symbol.
SYMBOL can be unbound, i.e., its value is void."
  (declare (indent 1) (debug t))
  (cl-with-gensyms (is-bound original-value)
    (cl-once-only (symbol)
      `(let* ((,is-bound (boundp ',symbol))
              (,original-value (when ,is-bound
                                 (symbol-value ,symbol))))
         (unwind-protect
             (progn ,@body)
           (if ,is-bound
               (set ,symbol ,original-value)
             (makunbound ',symbol)))))))

(ert-deftest project-store-unload-function ()
  (project-store-tests-save-value 'project-find-functions
    (project-store-tests-save-value 'project-list-exclude
      (add-hook 'project-find-functions #'project-store-try -20)
      (add-hook 'project-list-exclude #'project-store-p)
      (defvar project-find-functions)
      (defvar project-list-exclude)
      (ert-info ("hook functions are added")
        (should (memq #'project-store-try project-find-functions))
        (should (memq #'project-store-p project-list-exclude)))
      (ert-info ("return nil so that the standard unloading proceeds")
        ;; `project-store-unload-function' is only called after 'loadhist is loaded
        (require 'loadhist)
        (should-not (project-store-unload-function)))
      (ert-info ("hook functions are removed")
        (should-not (memq #'project-store-try project-find-functions))
        (should-not (memq #'project-store-p project-list-exclude))))))

(ert-deftest project-store-dir-change-clear-cache ()
  "Test that cache is cleared after `project-store-dir' is changed."
  (project-store-tests-save-value 'project-store-dir
    (let ((project-store-dir "/nix/store/")
          (project-store--cached-projects (make-hash-table :test 'equal))
          (project-store--cached-project-names (make-hash-table :test 'equal)))
      (project-name
       (project-store-try "/nix/store/xxywqayx584zfal9d3h0smk5k2slyk44-emacs-30.2/"))
      (ert-info ("cache is created")
        (should-not (hash-table-empty-p project-store--cached-projects))
        (should-not (hash-table-empty-p project-store--cached-project-names)))
      (setopt project-store-dir "/tmp/store/")
      (ert-info ("cache is cleared")
        (should (hash-table-empty-p project-store--cached-projects))
        (should (hash-table-empty-p project-store--cached-project-names))))))

(ert-deftest project-store-name-prefix-change-clear-cache ()
  "Test that cache is cleared after `project-store-name-prefix' is changed."
  (project-store-tests-save-value 'project-store-name-prefix
    (let ((project-store--cached-project-names (make-hash-table :test 'equal)))
      (project-name
       '(store . "/nix/store/xxywqayx584zfal9d3h0smk5k2slyk44-emacs-30.2/"))
      (ert-info ("cache is created")
        (should-not (hash-table-empty-p project-store--cached-project-names)))
      (setopt project-store-name-prefix "<store>")
      (ert-info ("cache is cleared")
        (should (hash-table-empty-p project-store--cached-project-names))))))

(ert-deftest project-store-dir-change-value ()
  "Test that `project-store-dir' can be changed by `setopt'."
  (project-store-tests-save-value 'project-store-dir
    (let ((new-value "/project/store/tests/"))
      (ert-info ("before change")
        (should-not (equal project-store-dir
                           new-value)))
      (setopt project-store-dir new-value)
      (ert-info ("after change")
        (should (equal project-store-dir
                       new-value))))))

(ert-deftest project-store-name-prefix-change-value ()
  "Test that `project-store-name-prefix' can be changed by `setopt'."
  (project-store-tests-save-value 'project-store-name-prefix
    (let ((new-value "/project/store/tests/"))
      (ert-info ("before change")
        (should-not (equal project-store-name-prefix
                           new-value)))
      (setopt project-store-name-prefix new-value)
      (ert-info ("after change")
        (should (equal project-store-name-prefix
                       new-value))))))

(provide 'project-store-tests)

;;; project-store-tests.el ends here

;; Local Variables:
;; package-lint-main-file: "project-store.el"
;; End:
