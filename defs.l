;;; -*- Mode: Lisp; Package: EDITOR -*-
;;;
;;; This file is not part of xyzzy.
;;;
; $Id: defs.l 777 2007-12-21 18:39:28Z torihat $
;
; kamailg/defs.l
;
; by HATTORI Masashi

(defpackage "kamailg"
  (:use "lisp" "editor")
  (:nicknames "kmg"))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (require "junk/defs")
  (require "junk/macro")
  (require "junk/mail")
  (require "junk/lib")
  (require "junk/log")
  (require "junk/mime-encode")
  (require "junk/rfc822")
  (require "junk/rfc2045")
  (require "junk/imap4")
  (require "junk/smtp")
  (require "junk/mail-view")
  (require "junk/mail-edit")
  (require "junk/mail-address")
  (require "junk/mail-signature"))

(provide "kamailg/defs")

(in-package "kamailg")

(defvar *debug-mode* nil)

(defvar *prog-name* "KaMailG")
(defvar *prog-version* "0.0.0.1-alpha")

(defvar *pframe-name* "KaMailG")
(defvar *pframe-old* nil)

(defvar *user-agent*
  (format nil "~A/~A xyzzy-~A (~A)"
	  *prog-name*
	  *prog-version*
	  (software-version)
	  (os-platform)))

(defvar *base-directory* "~/.kamailg")

(defvar *config-file*
  (merge-pathnames "config.l" *base-directory*))

(defvar *data-directory*
  (merge-pathnames "data" *base-directory*))

(defvar *mail-directory*
  (merge-pathnames "mail" *base-directory*))

(defvar *draft-directory*
  (merge-pathnames "draft" *base-directory*))

(defvar *buffer-prefix* "*KaMailG ")

(defvar *buffer-summary*   (concat *buffer-prefix* "Summary*"))
(defvar *buffer-temp*      (concat *buffer-prefix* "Temp*"))

(defvar *summary-mark-string-marked*  "X")
(defvar *summary-mark-string-normal*  " ")

(defvar *summary-flag-string-flagged* "#")
(defvar *summary-flag-string-normal*  " ")

(defvar *summary-type-normal*    " ")
(defvar *summary-type-multipart* "@")

(defvar *summary-status-unseen*    "U")
(defvar *summary-status-seen*      " ")
(defvar *summary-status-answered*  "A")
(defvar *summary-status-draft*     "D")
(defvar *summary-status-recent*    "N")

(defvar *summary-attribute-mark*       (list :foreground  1))
(defvar *summary-attribute-flag*       (list :foreground  9))
(defvar *summary-attribute-status*     (list :foreground 13))
(defvar *summary-attribute-multipart*  (list :foreground 12))
(defvar *summary-attribute-date*       (list :foreground 10))
(defvar *summary-attribute-from*       (list :foreground 11))
(defvar *summary-attribute-title*      (list :foreground 14))

(setq *summary-window-height* 10)

(defvar *account-list* nil)
(defvar *account-current* nil)

(defvar *folder-list-current* nil)
(defvar *folder-current* nil)

(defvar *kamailg-start-hook* nil)
(defvar *kamailg-finish-hook* nil)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun title-mode-line ()
  (make-local-variable 'title-bar-format)
  (setq title-bar-format *user-agent*))

(defun kamailg-message (fmt &rest args)
  (apply #'message (concat *prog-name* ": " fmt) args))

(defun kamailg-msgbox (fmt &rest args)
  (message-box (apply #'format nil fmt args)
	       *prog-name*))

(defun kamailg-error (fmt &rest args)
  (apply #'error (concat *prog-name* "~%~%" fmt) args))

(defun show-help ()
  (interactive)
  (let ((url "https://github.com/torihat/kamailg"))
    (shell-execute url t)))

(defun show-startup-screen ()
  (set-buffer (get-buffer-create *buffer-temp*))
  (erase-buffer (selected-buffer))
  (setq need-not-save t)
  (insert "Loading ...")
  (refresh-screen))

(defun hide-startup-screen ()
  (when (find-buffer *buffer-temp*)
    (delete-buffer *buffer-temp*)))

(defun init ()
  (junk::create-directory-if *base-directory*)
  (junk::create-directory-if *data-directory*)
  (junk::create-directory-if *mail-directory*)
  (junk::create-directory-if *draft-directory*)
  (unless (or *account-current*
	      (setq *account-current* (car *account-list*)))
    (kamailg-error "init: no account setting found."))
  (junk::mail-address-load)
  (init-account *account-current*)
  )

(defun init-account (account)
  (search-history-load account)
  (folder-init account)
  (unless (folder-load *account-current*)
    (kamailg-error "init-account: folder-load"))
  (setq *folder-current* (car *folder-list-current*)))

(defun load-config ()
  (junk::load-config-file *config-file*))

(defun frame-set ()
  (setq *pframe-old* (ed::pseudo-frame-name (selected-pseudo-frame)))
  (new-pseudo-frame *pframe-name*))

(defun frame-get ()
  (find-pseudo-frame *pframe-name*))

(defun hide ()
  (interactive)
  (let ((old (find-pseudo-frame *pframe-old*)))
    (when old
      (select-pseudo-frame old))))

(defun restore ()
  (interactive)
  (let ((frame (frame-get)))
    (if frame
	  (select-pseudo-frame frame)
      (user::kamailg))))

(defun finish ()
  (interactive)
  (handler-case
      (account-disconnect *account-current*)
    (error (c)
      (kamailg-msgbox "~A" (si:*condition-string c))))
  (let ((frame (frame-get)))
    (dolist (buf (buffer-list))
      (let ((bufname (buffer-name buf)))
	(when (string-match (concat "^" (regexp-quote *buffer-prefix*)) bufname)
	  (delete-buffer buf))))
    (when frame
      (delete-pseudo-frame frame)))
  (run-hooks '*kamailg-finish-hook*))

(defun user::kamailg-mailto (mailto)
  (let ((header (junk::parse-mailto mailto))
	to
	subject
	body)
    (user::kamailg)
    (summary-draft-create)
    (dolist (h header)
      (let ((field (car h))
	    (value (cdr h)))
	(cond ((or (equalp field "to")
		   (equalp field "subject"))
	       (junk::mail-draft-edit-header-string field value))
	      ((equalp field "body")
	       (setf (junk::maildraft-body junk::*mail-draft-current*) value)
	       (junk::mail-draft-refresh)))))
    ))

(defun user::kamailg-toggle ()
  (interactive)
  (if (equal *pframe-name*
	     (ed::pseudo-frame-name (selected-pseudo-frame)))
      (hide)
    (restore)))

(defun user::kamailg ()
  (interactive)
  (when (frame-get)
    (restore)
    (return-from user::kamailg))
  (load-config)
  (frame-set)
  (show-startup-screen)
  (handler-case
      (progn
	(init)
	(summary-window-set)
	(summary-mode)
	(summary-folder-open *account-current* *folder-inbox*)
	(run-hooks '*kamailg-start-hook*)
	(hide-startup-screen)
	(kamailg-message "started."))
    (error (c)
      (kamailg-msgbox "~A" (si:*condition-string c))
      (finish))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require "kamailg/gmail")
(require "kamailg/account")
(require "kamailg/folder")
(require "kamailg/fetch")
(require "kamailg/summary")
(require "kamailg/search")
(require "kamailg/message")
