;;; -*- Mode: Lisp; Package: EDITOR -*-
;;;
;;; This file is not part of xyzzy.
;;;
; $Id: search.l 776 2007-12-18 11:36:23Z torihat $
;
; kamailg/search.l
;
; by HATTORI Masashi

(eval-when (:compile-toplevel :load-toplevel :execute)
  (require "kamailg/defs"))

(require "kamailg/account")
(require "kamailg/folder")

(provide "kamailg/search")

(in-package "kamailg")

(defvar *search-header-part* "BODY[HEADER.FIELDS (DATE FROM TO SUBJECT REFERENCES IN-REPLY-TO MESSAGE-ID CONTENT-TYPE)]")

(defvar *search-history-limit* 30)
(defvar *search-history-current* nil)

(defvar *search-result-directory-name* "query/")
(defvar *search-result-file-suffix* "dat")
(defvar *search-query-file-suffix* "qer")

(defvar *search-result-limit* 50)
(defvar *search-result-offset* 0)

(defvar *search-date-format* "%d-%b-%Y")

(defvar *search-date-operator-list*
  '(("<"  . "BEFORE")
    (">"  . "AFTER")
    (">=" . "SINCE")
    ("=>" . "SINCE")
    ("="  . "ON")
    ))

;;;
;;; query
;;;
(defstruct query
  folder
  string
  conditions
  words)

(defun query-equal (a b)
  (let ((fa (query-folder a))
	(fb (query-folder b)))
    (and (equal (and (folder-p fa) (folder-name fa))
		(and (folder-p fb) (folder-name fb)))
	 (equal (query-string a)
		(query-string b)))))

(defun query-folder-p (query)
  (and (query-folder query)
       (not (query-string query))
       (not (query-conditions query))
       (not (query-words query))))

;;;
;;; search
;;;
(defun search-parse-date-range (num type)
  (let* ((days (* (if (< 0 num)
		      num
		    (- 0 num))
		  (cond ((equal "d" type)
			 1)
			((equal "w" type)
			 7)
			((equal "m" type)
			 30) ; –Ê“|‚È‚Ì‚ÅŒÅ’è‚Å
			((equal "y" type)
			 365))))
	 (start-time (- (get-universal-time)
			(* days 24 60 60))))
    (cons (if (< 0 num) "SINCE" "BEFORE")
	  (format-date-string *search-date-format* start-time))))

(defun search-date-operator (type)
  (cdr (assoc type *search-date-operator-list* :test #'equal)))

(defun search-parse-date-condition (type datestr)
  (let ((operator (search-date-operator type)))
    (when operator
      (let ((y (parse-integer (substring datestr 0 4)))
	    (m (parse-integer (substring datestr 4 6)))
	    (d (parse-integer (substring datestr 6 8))))
	(cons operator
	      (format-date-string *search-date-format*
				  (encode-universal-time 0 0 0 d m y)))))))

(defun search-string-parse (search-string)
  (let (rest
	search-list
	attr-list
	)
    (dolist (part (split-string search-string " "))
      (cond ((string-match "flag:\\([a-zA-Z]+\\)" part)
	     (let ((cond (string-upcase (match-string 1))))
	       (push (cons cond nil) attr-list)))
	    ((string-match "flag!\\([a-zA-Z]+\\)" part)
	     (let ((cond (concat "NOT "(string-upcase (match-string 1)))))
	       (push (cons cond nil) attr-list)))
	    ((string-match "date:\\(-?[0-9]+\\)\\([dwmy]\\)" part)
	     (let ((cond (search-parse-date-range (parse-integer (match-string 1))
						  (match-string 2))))
	       (if cond
		   (push cond attr-list)
		 (kamailg-msgbox "unknown phrase: ~A" part))))
	    ((string-match "date\\([<>=]+\\)\\([0-9]\\{8\\}\\)" part)
	     (let ((cond (search-parse-date-condition (match-string 1)
						      (match-string 2))))
	       (if cond
		   (push cond attr-list)
		 (kamailg-msgbox "unknown phrase: ~A" part))))
	    ((string-match "\\([-0-9a-z,@]+\\):\\([^ ]+\\)" part)
	     (push (cons (string-upcase (match-string 1))
			 (match-string 2)) attr-list))
	    ((string-match "\\([-0-9a-z,@]+\\)!\\([^ ]+\\)" part)
	     (push (cons (format nil "NOT ~A" (string-upcase (match-string 1)))
			 (match-string 2)) attr-list))
	    (t
	     (push part search-list))))
    (when (or search-list attr-list)
      (make-query :string     search-string
		  :conditions (nreverse attr-list)
		  :words      (nreverse search-list)))
    ))

(defun search-history-file (account)
  (merge-pathnames "search-history.dat"
		   (account-data-directory account)))

(defun search-history-load (account)
  (let ((file (search-history-file account)))
    (setq *search-history-current* nil)
    (when (file-exist-p file)
      (setq *search-history-current*
	    (junk::data-read-from-file file)))))

(defun search-history-save (account)
  (let ((file (search-history-file account)))
    (junk::data-write-to-file file *search-history-current*)))

(defun search-history-add (account query)
  (pushnew query *search-history-current*
	   :test #'query-equal)
  (when (> (length *search-history-current*) *search-history-limit*)
    (setq *search-history-current*
	  (subseq *search-history-current* 0 *search-history-limit*)))
  (search-history-save account))

(defun search-history-current-strings ()
  (mapcar #'query-string *search-history-current*))

(defun search-folder-file (account)
  (merge-pathnames "search-folder.dat"
		   (account-data-directory account)))

(defun search-result-file (account query limit offset)
  (let ((dir (merge-pathnames *search-result-directory-name*
			      (account-data-directory account))))
    (junk::create-directory-if dir)
    (merge-pathnames
     (format nil "~A.~A"
	     (si:md5 (format nil "~S:~D:~D" query limit offset))
	     *search-result-file-suffix*)
     dir)))

(defun search-result-load (account query limit offset)
  (let ((file (search-result-file account query limit offset)))
    (when (file-exist-p file)
      (car (junk::data-read-from-file file)))))

(defun search-result-save (account result)
  (let* ((query (result-query result))
	 (limit (result-limit result))
	 (offset (result-offset result))
	 (file (search-result-file account query limit offset)))
    (junk::data-write-to-file file (list result))))

(defun search-query-file (account query)
  (let ((dir (merge-pathnames *search-result-directory-name*
			      (account-data-directory account))))
    (junk::create-directory-if dir)
    (merge-pathnames
     (format nil "~A.~A"
	     (si:md5 (format nil "~S" query))
	     *search-query-file-suffix*)
     dir)))

(defun search-query-load (account query)
  (let ((file (search-query-file account query)))
    (when (file-exist-p file)
      (junk::data-read-from-file file))))

(defun search-query-save (account query searched)
  (let ((file (search-query-file account query)))
    (junk::data-write-to-file file searched)))

(defun search-execute-query (account query &optional force)
  (let ((folder (query-folder query))
	(words (junk::string-join (query-words query)))
	(conditions (query-conditions query))
	(file (search-query-file account query))
	res
	searched)
    (setq searched (search-query-load account query))
    (when (and searched
	       (not force))
      (return-from search-execute-query (values t searched)))
    (unless (folder-select account folder)
      (kamailg-error "search-execute: folder-select error."))
    (long-operation
      (multiple-value-setq (res searched)
	(gmail-uid-search account
			  conditions
			  words)))
    (search-query-save account query searched)
    (values res (nreverse searched))))

(defun search-folder (account folder &optional force &key limit offset)
  (search-execute account (make-query :folder folder) force :limit limit :offset offset))

(defstruct result
  query
  searched
  headers
  limit
  offset)

(defun search-execute-next (account result &optional force)
  (let ((limit (result-limit result))
	(last-offset (result-offset result))
	(last-searched (result-searched result))
	query
	offset)
    (when (< (+ limit last-offset) last-searched)
      (setq offset (+ last-offset limit))
      (setq query (result-query result))
      (search-execute account query force
		      :limit limit
		      :offset offset))))

(defun search-execute-prev (account result &optional force)
  (let ((limit (result-limit result))
	(last-offset (result-offset result))
	(last-searched (result-searched result))
	query
	offset)
    (when (< 0 last-offset)
      (setq offset (max 0 (- last-offset limit)))
      (setq query (result-query result))
      (search-execute account query force
		      :limit limit
		      :offset offset))))

(defun search-execute (account query &optional force &key limit offset)
  (setq limit  (or limit  *search-result-limit*))
  (setq offset (or offset *search-result-offset*))
  (let ((result-file (search-result-file account query limit offset))
	res
	searched
	uids
	headers
	(folder (query-folder query))
	(result (search-result-load account query limit offset)))
    (unless (equal folder *folder-current*)
      (setq *folder-current* folder))
    (when (and result
	       (not force))
      (return-from search-execute result))
    (unless (folder-select account folder)
      (kamailg-error "search-execute: folder-select error."))
    (multiple-value-setq (res searched)
      (search-execute-query account query force))
    (unless res
      (kamailg-error "search-execute: search-execute-query error."))
    (when searched
      (let ((beg (min (1- (length searched)) offset))
	    (end (1+ (min (1- (length searched)) (+ offset limit)))))
	(when (< beg end)
	  (setq uids (subseq searched beg end)))))
    (when uids
      (long-operation
	(setq headers (gmail-uid-fetch-headers account
					       uids
					       :part *search-header-part*))))
    (setq result (make-result :query query
			      :searched (length searched)
			      :headers (nreverse headers)
			      :limit limit
			      :offset offset))
    (search-result-save account result)
    (unless (query-folder-p query)
      (search-history-add account query))
    result))
