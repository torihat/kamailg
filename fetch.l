;;; -*- Mode: Lisp; Package: EDITOR -*-
;;;
;;; This file is not part of xyzzy.
;;;
; $Id: fetch.l 774 2007-12-15 18:01:24Z torihat $
;
; kamailg/fetch.l
;
; by HATTORI Masashi

(eval-when (:compile-toplevel :load-toplevel :execute)
  (require "kamailg/defs"))

(require "kamailg/account")
(require "kamailg/folder")

(provide "kamailg/fetch")

(in-package "kamailg")

;;; •Û‘¶ƒtƒ@ƒCƒ‹
;;; Mail/00/00/00/00000001.eml <= 00000001 <=   1
;;; Mail/00/00/00/00000099.eml <= 00000099 <=  99
;;; Mail/00/00/01/00000000.eml <= 00000100 <= 100

(defvar *fetch-file-suffix* "eml")

(defun fetch-file-base-directory (account folder)
  (merge-pathnames (concat (si:md5 (or (folder-name folder) "")) "/")
		   (merge-pathnames (concat (account-email account) "/") *mail-directory*)))

(defun fetch-file-path (account folder number)
  (setq number (if (numberp number) number (parse-integer number)))
  (let* ((file (format nil "~8,'0D.~A" number *fetch-file-suffix*))
	 (dir (format nil "~A/~A/~A"
		      (substring file 0 2)
		      (substring file 2 4)
		      (substring file 4 6))))
    (merge-pathnames (concat dir "/" file)
		     (fetch-file-base-directory account folder))))

(defun fetch-file-number (path)
  (let ((file (file-namestring path)))
    (when (string-match "[0-9]\\{8\\}" file)
      (parse-integer (match-string 0)))))

(defun fetch-create-directory-if (path)
  (let ((dir (directory-namestring path)))
    (junk::create-directory-if dir)))

(defun fetch-file (account folder number &optional force)
  (let ((path (fetch-file-path account folder number))
	res
	return)
    (when (and (file-exist-p path)
	       (not force))
      (return-from fetch-file t))
    (fetch-create-directory-if path)
    (unless (folder-select account folder)
      (kamailg-error "fetch-file: folder-select error."))
    (with-open-file (os path
			:direction :output
			:if-exists :overwrite
			:if-does-not-exist :create)
      (long-operation
	(multiple-value-setq (res return)
	  (gmail-uid-fetch-to-stream account number os))))
    (unless res
      (delete-file path
		   :if-does-not-exist :skip
		   :if-access-denied :force))
    (values res return)))
