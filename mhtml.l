;;; -*- Mode: Lisp; Package: EDITOR -*-
;;;
;;; This file is not part of xyzzy.
;;;
; $Id: mhtml.l 766 2007-12-14 18:50:27Z torihat $
;
; kamailg/mhtml.l
;
; by HATTORI Masashi

(eval-when (:compile-toplevel :load-toplevel :execute)
  (require "kamailg/defs"))

(provide "kamailg/mhtml")

(in-package "kamailg")

(defvar *mhtml-browser-position* bx::XPIS_BOTTOM)
(defvar *mhtml-browser-height* 400)

(defvar *mhtml-temp-filename* "mhtml-temp.mht")
(defvar *mhtml-current-file* nil)

(define-key *summary-map* #\v            'summary-view-html-mail-or-scroll)
(define-key *summary-map* #\q            'mhtml-close-browser-if)

(defun summary-view-html-mail-or-scroll (&optional shell-exec)
  (interactive "p")
  (let* ((msg (summary-item-current))
	 (num (summary-item-number msg))
	 (header (summary-item-header msg))
	 (file (summary-message-file num)))
    (unless file
      (return-from summary-view-html-mail-or-scroll))
    (if (and (mhtml-browser-open-p)
	     (equal file *mhtml-current-file*))
	(bx:browserex-scroll-down)
      (progn
	(when (mhtml-browser-open-p)
	  (mhtml-close-browser))
	(summary-view-mail-or-scroll nil t)
	(when (message-window-get)
	  (message-close))
	(mhtml-view file shell-exec)))))

(defun mhtml-temp-file (account)
  (merge-pathnames *mhtml-temp-filename* (account-data-directory account)))

(defun mhtml-view (file &optional shell-exec)
  (let ((tmpfile (mhtml-temp-file *account-current*)))
    (when (copy-file file tmpfile
		     :if-exists :overwrite)
      (setq *mhtml-current-file* file)
      (if shell-exec
	  (shell-execute tmpfile)
	(mhtml-view-html-mail tmpfile)))))

(defun mhtml-browser-open-p ()
  (bx::browser-open-p))

(defun mhtml-view-html-mail (file)
  (bx::navigate file
		:position *mhtml-browser-position*
		:size *mhtml-browser-height*))

(defun mhtml-close-browser-if ()
  (interactive)
  (if (mhtml-browser-open-p)
      (mhtml-close-browser)
    (summary-close)))

(defun mhtml-close-browser ()
  (bx::close-browser))
