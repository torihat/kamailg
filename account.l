;;; -*- Mode: Lisp; Package: EDITOR -*-
;;;
;;; This file is not part of xyzzy.
;;;
; $Id: account.l 777 2007-12-21 18:39:28Z torihat $
;
; kamailg/account.l
;
; by HATTORI Masashi

(eval-when (:compile-toplevel :load-toplevel :execute)
  (require "kamailg/defs"))

(require "kamailg/gmail")

(provide "kamailg/account")

(in-package "kamailg")

(defstruct account
  email
  name
  username
  password
  server
  port
  stream
  auth
  smtpserver
  smtpport
  lang)

(defun account-data-directory (account)
  (merge-pathnames
   (concat (account-email account) "/")
   *data-directory*))

(defun account-connected-p (account)
  (gmail-connected-p account))

(defun account-selected-p (account)
  (gmail-selected-p account))

(defun account-selected-folder-p (account folder-name)
  (gmail-selected-folder-p account folder-name))

(defun account-check-password (account)
  (unless (account-password account)
    (let ((prompt (format nil "Password for ~@[~A~]: " (account-username account))))
      (setf (account-password account)
	    (junk::read-password prompt)))))

(defun account-connect (account)
  (gmail-connect account))

(defun account-disconnect (account)
  (gmail-disconnect account))

(defun account-get (email account-list)
  (car (member email account-list
	       :test #'equal
	       :key #'account-email)))

(defun account-change (email)
  (when (equal email (account-email *account-current*))
    (return-from account-change))
  (let ((account (account-get email *account-list*)))
    (when account
      (account-disconnect *account-current*))
    (setq *account-current* account)
    (init-account *account-current*)
    (summary-window-set)
    (summary-mode)
    (summary-folder-open *account-current* *folder-inbox*)))

(defun account-select ()
  (interactive)
  (let ((new-account-email
	 (completing-read "Account: "
			  (mapcar #'account-email *account-list*)
			  :must-match t)))
    (when new-account-email
      (account-change new-account-email))))
