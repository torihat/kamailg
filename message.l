;;; -*- Mode: Lisp; Package: EDITOR -*-
;;;
;;; This file is not part of xyzzy.
;;;
; $Id: message.l 778 2007-12-23 05:13:24Z torihat $
;
; kamailg/message.l
;
; by HATTORI Masashi

(eval-when (:compile-toplevel :load-toplevel :execute)
  (require "kamailg/defs"))

(require "junk/mail-view")

(provide "kamailg/message")

(in-package "kamailg")

(defvar *message-mode-hook* nil)

(defvar *message-file-current* nil)
(defvar-local *message-structure* nil)

(defvar *message-map* nil)
(unless *message-map*
  (setq *message-map* (copy-keymap junk::*mail-view-map*))
  (define-key *message-map* #\c   'draft-create)
  (define-key *message-map* #\r   'message-reply)
  (define-key *message-map* #\a   'message-reply-all)
  (define-key *message-map* #\f   'message-forward)
  (define-key *message-map* #\F   'message-forward-as-attachment)
  (define-key *message-map* #\u   'message-close)
  (define-key *message-map* #\q   'message-close)
  )

(defun message-buffer-set ()
  (junk::mail-view-buffer-set))

(defun message-window-get ()
  (and (find-buffer junk::*mail-view-buffer*)
       (get-buffer-window junk::*mail-view-buffer*)))

(defun message-window-set ()
  (let ((win (message-window-get)))
    (if win
	(set-window win)
      (progn
	(summary-window-set)
	(split-window *summary-window-height*)
	(other-window 1)
	(message-buffer-set)))))

(defun message-mode ()
  (interactive)
  (junk::modify-read-only-buffer
    (use-keymap *message-map*)
    (title-mode-line)
    (run-hooks '*message-mode-hook*)))

(defun source-buffer-set ()
  (junk::mail-view-source-buffer-set))

(defun message-show (file)
  (message-window-set)
  (setq *message-file-current* file)
  (when (setq *message-structure* (junk::mail-view-show file))
    (message-mode)
    t))

(defun message-close ()
  (interactive)
  (summary-window-set)
  (junk::mail-view-buffer-clear))

(defun message-scroll-forward ()
  (junk::mail-view-scroll-forward))

(defun message-scroll-backward ()
  (junk::mail-view-scroll-backward))


;;;
;;; Draft
;;;
(defvar *draft-mode-hook* nil)
(defvar *draft-current-number* nil)
(defvar *draft-current-folder* nil)

(defvar *draft-map* nil)
(unless *draft-map*
  (setq *draft-map* (copy-keymap junk::*mail-draft-map*))
  (define-key *draft-map* '(#\C-x #\C-s) 'draft-save)
  (define-key *draft-map* '(#\C-c #\C-c) 'draft-send)
  )

(defun draft-mode ()
  (interactive)
  (junk::modify-read-only-buffer
    (use-keymap *draft-map*)
    (title-mode-line)
    (setq *draft-current-number* nil)
    (setq *draft-current-folder* nil)
    (run-hooks '*draft-mode-hook*)))

(defun draft-set-from ()
  (let ((addr (account-email *account-current*))
	(name (account-name  *account-current*)))
    (when addr
      (junk::mail-draft-edit-header-string "from"
					   (junk::format-address addr name)))))

(defun draft-create ()
  (interactive)
  (junk::mail-draft-create)
  (draft-mode)
  (draft-set-from))

(defun message-edit ()
  (interactive)
  (let ((attachments (junk::mail-view-autosave-attachments
		      *message-file-current*
		      *message-structure*)))
    (junk::mail-draft-from-message *message-file-current*
				   *message-structure*
				   attachments)
    (draft-mode)
    (draft-set-from)))

(defun message-reply (&optional all)
  (interactive "p")
  (junk::mail-draft-create-reply *message-structure* all)
  (draft-mode)
  (draft-set-from))

(defun message-reply-all ()
  (interactive)
  (junk::mail-draft-create-reply-all *message-structure*)
  (draft-mode)
  (draft-set-from))

(defun message-forward ()
  (interactive)
  (let ((attachments (junk::mail-view-autosave-attachments
		      *message-file-current*
		      *message-structure*)))
    (junk::mail-draft-create-forward *message-structure*
				     attachments)
    (draft-mode)
    (draft-set-from)))

(defun message-forward-as-attachment ()
  (interactive)
  (junk::mail-draft-create-forward-as-attachment *message-structure*
						 *message-file-current*)
  (draft-mode)
  (draft-set-from))

(defun draft-save-file (prefix cnt)
  (merge-pathnames
   (format nil "~A_~2,'0D.~A"
	   prefix
	   cnt
	   *fetch-file-suffix*)
   *draft-directory*))

(defun draft-save-path ()
  (let ((prefix (format nil "~D" (get-universal-time)))
	(cnt 0)
	path)
    (setq path (draft-save-file prefix cnt))
    (while (file-exist-p path)
      (incf cnt)
      (setq path (draft-save-file prefix cnt)))
    path))

(defun draft-save ()
  (interactive)
  (let ((path (draft-save-path))
	(folder (or *draft-current-folder*
		    (folder-get *folder-draft* *folder-list-current*))))
    ;(junk::mail-draft-check)
    (junk::mail-draft-header-set-before-send)
    (save-excursion
      (junk::mail-save-buffer-create junk::*mail-draft-current*)
      (write-region (point-min) (point-max) path nil *encoding-sjis*))
    (unless (folder-select *account-current* folder)
      (kamailg-error "draft-save: folder-select error."))
    (long-operation
      (multiple-value-bind (flag return)
	  (gmail-append-file *account-current*
			     folder
			     path)
	(if flag
	    (progn
	      (when (and *draft-current-folder*
			 *draft-current-number*)
		(gmail-uid-delete-messages *account-current*
					   *draft-current-number*))
	      (junk::mail-draft-close t)
	      (message-close)
	      (delete-file path :if-does-not-exist :skip)
	      (gmail-noop *account-current*))
	  (kamailg-error "draft-save: append failed: ~S" return))))))

(defun draft-send ()
  (interactive)
  (junk::mail-draft-check)
  (junk::mail-draft-header-set-before-send)
  (account-check-password *account-current*)
  (save-excursion
    (junk::mail-save-buffer-create junk::*mail-draft-current*)
    (long-operation
      (multiple-value-bind (flag return)
	  (junk::smtp-send-buffer (account-smtpserver *account-current*)
				  :port (account-smtpport *account-current*)
				  :auth "LOGIN"
				  :user (account-username *account-current*)
				  :pass (account-password *account-current*)
				  :msgid-add t
				  :ssl (account-ssl *account-current*))
	(if flag
	    (junk::mail-draft-close t)
	  (kamailg-error "draft-send: failed: ~S" return))))))
