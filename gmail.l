;;; -*- Mode: Lisp; Package: EDITOR -*-
;;;
;;; This file is not part of xyzzy.
;;;
; $Id: gmail.l 740 2006-10-22 17:32:24Z torihat $
;
; kamailg/gmail.l
;
; by HATTORI Masashi

(eval-when (:compile-toplevel :load-toplevel :execute)
  (require "kamailg/defs"))

(require "junk/imap4")

(provide "kamailg/gmail")

(in-package "kamailg")

(defun gmail-connected-p (account)
  (junk::imap4-authenticated-p (account-stream account)))

(defun gmail-selected-p (account)
  (junk::imap4-selected-p (account-stream account)))

(defun gmail-selected-folder-p (account folder-name)
  (junk::imap4-selected-folder-p (account-stream account) folder-name))

(defun account-check-password (account)
  (unless (account-password account)
    (let ((prompt (format nil "Password for ~@[~A~]: " (account-username account))))
      (setf (account-password account)
	    (junk::read-password prompt)))))

(defun gmail-connect (account)
  (unless (gmail-connected-p account)
    (account-check-password account)
    (let (stream)
      (long-operation
	(setq stream (junk::imap4-open (account-server account)
				       (account-port account)
				       nil
				       :ssl (account-ssl account)))
	(unless stream
	  (kamailg-error "gmail-connect: imap4-open error."))
	(unless (junk::imap4-login stream
				   (account-username account)
				   (account-password account)
				   ;(account-auth account)
				   )
	  (kamailg-error "gmail-connect: imap4-login error."))
	(setf (account-stream account) stream))
      t)))

(defun gmail-disconnect (account)
  (let ((stream (account-stream account)))
    (when stream
      (unwind-protect
	  (long-operation
	    (junk::imap4-logout stream))
	(setf (account-stream account) nil)))))

(defun gmail-uid-fetch-to-stream (account number os)
  (junk::imap4-uid-fetch-to-stream (account-stream account) number os))

(defun gmail-create (account name)
  (junk::imap4-create (account-stream account) name))

(defun gmail-delete (account name)
  (junk::imap4-delete (account-stream account) name))

(defun gmail-select (account folder)
  (junk::imap4-select (account-stream account) (folder-name folder)))

(defun gmail-close (account)
  (when (gmail-selected-p account)
    (long-operation
      (junk::imap4-close (account-stream account)))))

(defun gmail-list (account)
  (let (folder-list)
    (long-operation
      (account-connect account)
      (when (gmail-selected-p account)
	(gmail-close account))
      (multiple-value-bind (res folders)
	  (junk::imap4-list (account-stream account) "" "*")
	(when res
	  (dolist (f folders)
	    (let ((props (cadr f))
		  (folder-name (car f)))
	      (unless (string-matchp "noselect" props)
		(push (make-folder :name folder-name) folder-list)))))))
    (nreverse folder-list)))

(defun gmail-append-file (account folder path)
  (junk::imap4-append-file (account-stream *account-current*)
			   (folder-name folder)
			   path))

(defun gmail-uid-delete-messages (account numbers)
  (junk::imap4-uid-delete-messages (account-stream account)
				   numbers))

(defun gmail-noop (account)
  (junk::imap4-noop (account-stream account)))

(defun gmail-uid-search (account conditions words)
  (junk::imap4-uid-search (account-stream account)
			  conditions
			  words))

(defun gmail-uid-fetch-headers (account uid-list &key part)
  (junk::imap4-uid-fetch-headers (account-stream account)
				 (junk::imap4-uid-join uid-list)
				 :part part))

(defun gmail-flag-flagged (flags)
  (junk::imap4-flag-flagged flags))

(defun gmail-flag-seen (flags)
  (junk::imap4-flag-seen flags))

(defun gmail-uid-store-flagged (account num &optional (prefix "+"))
  (junk::imap4-uid-store-flagged (account-stream account)
				 num
				 prefix))

(defun gmail-uid-store-seen (account num &optional (prefix "+"))
  (junk::imap4-uid-store-seen (account-stream account)
			      num
			      prefix))

(defun gmail-uid-move-messages (account uid-list folder)
  (junk::imap4-uid-move-messages (account-stream account)
				 (junk::imap4-uid-join uid-list)
				 (folder-name folder)))
