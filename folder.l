;;; -*- Mode: Lisp; Package: EDITOR -*-
;;;
;;; This file is not part of xyzzy.
;;;
; $Id: folder.l 782 2007-12-23 05:27:52Z torihat $
;
; kamailg/folder.l
;
; by HATTORI Masashi

(eval-when (:compile-toplevel :load-toplevel :execute)
  (require "kamailg/defs"))

(require "kamailg/account")

(provide "kamailg/folder")

(in-package "kamailg")

(defvar *folder-file-name* "folder.dat")
(defvar *folder-headers-file-name* "headers.dat")

(defvar *folder-inbox*   "INBOX")

(defvar *folder-archive* nil)
(defvar *folder-spam*    nil)
(defvar *folder-trash*   nil)
(defvar *folder-sent*    nil)
(defvar *folder-starred* nil)
(defvar *folder-draft*   nil)

(defstruct folder
  name
  alias
  (exists 0)
  (unseen 0)
  )

(defun folder-init (account)
  (cond ((equal (account-lang account) 'ja)
	 (setq *folder-archive* "[Gmail]/すべてのメール")
	 (setq *folder-spam*    "[Gmail]/迷惑メール")
	 (setq *folder-trash*   "[Gmail]/ゴミ箱")
	 (setq *folder-sent*    "[Gmail]/送信済みメール")
	 (setq *folder-starred* "[Gmail]/スターあり")
	 (setq *folder-draft*   "[Gmail]/下書き")
	 )
	(t
	 (setq *folder-archive* "[Gmail]/All Mail")
	 (setq *folder-spam*    "[Gmail]/Spam")
	 (setq *folder-trash*   "[Gmail]/Trash")
	 (setq *folder-sent*    "[Gmail]/Sent")
	 (setq *folder-starred* "[Gmail]/Starred")
	 (setq *folder-draft*   "[Gmail]/Drafts")
	 )))

(defun folder-file (account)
  (let ((dir (account-data-directory account)))
    (merge-pathnames
     *folder-file-name*
     dir)))

(defun folder-load-list (account)
  (let ((file (folder-file account)))
    (when (file-exist-p file)
      (junk::data-read-from-file file))))

(defun folder-save-list (account folder-list)
  (let ((dir (account-data-directory account))
	(file (folder-file account)))
    (junk::create-directory-if dir)
    (junk::data-write-to-file file folder-list)))

(defun folder-get (name folder-list)
  (car (member name
	       folder-list
	       :test #'equal
	       :key #'folder-name)))

(defun folder-add (account name)
  (account-connect account)
  (when (account-selected-p account)
    (folder-close account))
  (gmail-create account name))

(defun folder-delete (account name)
  (account-connect account)
  (when (account-selected-p account)
    (folder-close account))
  (gmail-delete account name))

(defun folder-select (account folder)
  (let ((name (folder-name folder)))
    (account-connect account)
    (if (account-selected-folder-p account name)
	t
      (progn
	(long-operation
	  (folder-close account)
	  (multiple-value-bind (res exists recent unseen)
	      (gmail-select account folder)
	    (progn
	      (when res
		(setq *folder-current* folder))
	      (return-from folder-select (values res exists recent unseen)))))))))

(defun folder-close (account)
  (gmail-close account))

(defun folder-list-get (account)
  (gmail-list account))

(defun folder-completing-read (&optional folder-list (must-match t) (prompt "Folder: "))
  (completing-read prompt
		   (mapcar #'folder-name (or folder-list *folder-list-current*))
		   :must-match must-match))

(defun folder-load (account)
  (or (setq *folder-list-current*
	    (folder-load-list account))
      (folder-list account)))

(defun folder-list (account)
  (setq *folder-list-current*
	(folder-list-get account))
  (folder-save-list account *folder-list-current*)
  *folder-list-current*)
