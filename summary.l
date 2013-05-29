;;; -*- Mode: Lisp; Package: EDITOR -*-
;;;
;;; This file is not part of xyzzy.
;;;
; $Id: summary.l 776 2007-12-18 11:36:23Z torihat $
;
; kamailg/summary.l
;
; by HATTORI Masashi

(eval-when (:compile-toplevel :load-toplevel :execute)
  (require "kamailg/defs"))

(provide "kamailg/summary")

(in-package "kamailg")

(defvar *summary-print-thread* t)

(defvar-local *summary-last-result* nil)
(defvar-local *summary-item-list* nil)
(defvar-local *summary-mark-list* nil)

(defvar *summary-mode-hook* nil)
(defvar *summary-archive-seen-messages-hook* nil)

(defvar *summary-datetime-format* "%y/%m/%d %H:%M ")

(defvar *summary-buffer-partial-temp*
  (concat *buffer-prefix* "Partial Temp*"))
(defvar *summary-message-partial-temp*
  (merge-pathnames "message-partial.eml" *data-directory*))

(defvar *summary-map* nil)
(unless *summary-map*
  (setq *summary-map* (make-sparse-keymap))
  (define-key *summary-map* #\RET          'summary-view-mail-or-scroll)
  (define-key *summary-map* #\o            'summary-view-mail-or-scroll)
  (define-key *summary-map* #\SPC          'summary-view-mail-or-scroll)
  (define-key *summary-map* #\TAB          'summary-view-next-unseen)
  
  (define-key *summary-map* #\G            'summary-fetch-current-items)
  
  (define-key *summary-map* #\j            'summary-view-next)
  (define-key *summary-map* #\k            'summary-view-previous)
  (define-key *summary-map* #\n            'next-line)
  (define-key *summary-map* #\p            'previous-line)
  (define-key *summary-map* #\R            'summary-reload)
  
  (define-key *summary-map* #\/            'summary-search)
  
  (define-key *summary-map* #\Right        'summary-show-next)
  (define-key *summary-map* #\Left         'summary-show-prev)
  
  (define-key *summary-map* #\h            'summary-search-history-select)
  (define-key *summary-map* #\H            'summary-account-select)
  ;(define-key *summary-map* '(#\C-x #\C-s) 'summary-save-as-folder)
  
  (define-key *summary-map* #\e            'summary-open-folder-select)
  (define-key *summary-map* '(#\g #\i)     'summary-open-inbox)
  (define-key *summary-map* '(#\g #\d)     'summary-open-draft)
  (define-key *summary-map* '(#\g #\s)     'summary-open-starred)
  
  (define-key *summary-map* '(#\g #\r)     'summary-folder-reload)
  (define-key *summary-map* '(#\g #\a)     'summary-folder-add)
  (define-key *summary-map* '(#\g #\x)     'summary-folder-del)
  
  (define-key *summary-map* '(#\? #\f)     'summary-search-by-from)
  (define-key *summary-map* '(#\? #\F)     'summary-search-by-from-addr)
  (define-key *summary-map* '(#\? #\s)     'summary-search-by-subject)
  (define-key *summary-map* '(#\? #\m)     'summary-search-by-msgid)
  ;(define-key *summary-map* '(#\? #\t)     'summary-search-by-thread)
  
  (define-key *summary-map* #\s            'summary-flag-toggle)
  (define-key *summary-map* #\S            'summary-status-toggle)
  
  (define-key *summary-map* #\x            'summary-mark-toggle)
  (define-key *summary-map* '(#\m #\m)     'summary-mark-toggle)
  (define-key *summary-map* '(#\m #\a)     'summary-mark-all)
  (define-key *summary-map* '(#\m #\c)     'summary-mark-clear)
  (define-key *summary-map* '(#\m #\/)     'summary-mark-with-condition)
  
  (define-key *summary-map* #\c            'summary-draft-create)
  
  (define-key *summary-map* #\r            'summary-message-reply)
  (define-key *summary-map* #\a            'summary-message-reply-all)
  (define-key *summary-map* #\f            'summary-message-forward)
  (define-key *summary-map* #\F            'summary-message-forward-as-attachment)
  
  (define-key *summary-map* #\w            'summary-message-save-attachment)
  (define-key *summary-map* #\W            'summary-message-save-execute-attachment)
  (define-key *summary-map* #\J            'summary-show-message-partial)
  
  (define-key *summary-map* #\>            'summary-items-to-folder)
  (define-key *summary-map* #\y            'summary-items-to-archive)
  (define-key *summary-map* #\I            'summary-items-to-inbox)
  (define-key *summary-map* #\!            'summary-items-to-spam)
  (define-key *summary-map* #\#            'summary-items-to-trash)
  
  (define-key *summary-map* '(#\C-c #\a)   'summary-address-add)
  
  (define-key *summary-map* #\u            'message-close)
  (define-key *summary-map* #\q            'summary-close)
  (define-key *summary-map* #\Q            'finish)
  
  (define-key *summary-map* #\[            'summary-connect)
  (define-key *summary-map* #\]            'summary-disconnect)
  (define-key *summary-map* #\F1           'show-help)
  (define-key *summary-map* #\RBtnUp       'summary-mouse-right-press)
  )

(defun summary-menu-create ()
  (let ((menu (create-popup-menu)))
    (add-popup-menu menu
		    (summary-account-select-menu)
		    "アカウント選択")
    (add-popup-menu menu
		    (summary-open-folder-menu)
		    "フォルダ選択")
;;     (add-menu-item menu
;; 		   'summary-open-inbox
;; 		   "INBOXを開く"
;; 		   'summary-open-inbox)
;;     (add-menu-item menu
;; 		   'summary-open-draft
;; 		   "Draftsを開く"
;; 		   'summary-open-draft)
;;     (add-menu-item menu
;; 		   'summary-open-starred
;; 		   "Starredを開く"
;; 		   'summary-open-starred)
    (add-menu-item menu
		   'summary-folder-reload
		   "フォルダ一覧を更新"
		   'summary-folder-reload)
    (add-menu-item menu
		   'summary-folder-add
		   "フォルダを作成..."
		   'summary-folder-add)
    (add-menu-item menu
		   'summary-folder-del
		   "フォルダを削除..."
		   'summary-folder-del)
    (add-menu-separator menu)
    (add-menu-item menu
		   'summary-fetch-current-items
		   "一覧のメッセージを受信"
		   'summary-fetch-current-items)
    (add-menu-item menu
		   'summary-reload
		   "一覧を更新"
		   'summary-reload)
    (add-menu-item menu
		   'summary-show-next
		   (format nil "次の~D件を表示" *search-result-limit*)
		   'summary-show-next)
    (add-menu-item menu
		   'summary-show-prev
		   (format nil "前の~D件を表示" *search-result-limit*)
		   'summary-show-prev)
    (add-menu-separator menu)
    (add-menu-item menu
		   'summary-view-mail-or-scroll
		   "メールを表示/スクロール"
		   'summary-view-mail-or-scroll)
    (add-menu-item menu
		   'summary-view-next-unseen
		   "次の未読メールを表示"
		   'summary-view-next-unseen)
    (add-menu-item menu
		   'summary-view-next
		   "次の行のメールを表示"
		   'summary-view-next)
    (add-menu-item menu
		   'summary-view-previous
		   "前の行のメールを表示"
		   'summary-view-previous)
    (add-menu-item menu
		   'summary-message-save-attachment
		   "添付ファイルを選択して保存..."
		   'summary-message-save-attachment)
    (add-menu-item menu
		   'summary-message-save-execute-attachment
		   "添付ファイルを保存して実行..."
		   'summary-message-save-execute-attachment)
    (add-menu-item menu
		   'summary-show-message-partial
		   "partialメッセージを結合して表示"
		   'summary-show-message-partial)
    (add-menu-separator menu)
    (add-menu-item menu
		   'summary-search
		   "検索..."
		   'summary-search)
    (add-popup-menu menu
		    (summary-search-history-select-menu)
		    "検索履歴")
;    (add-menu-item menu
;		   'summary-save-as-folder
;		   "検索条件をフォルダとして登録..."
;		   'summary-save-as-folder)
;    (add-popup-menu menu
;		    (folder-delete-select-menu)
;		    "検索フォルダ削除")
    (add-menu-item menu
		   'summary-search-by-from
		   "メールの送信者で検索"
		   'summary-search-by-from)
    (add-menu-item menu
		   'summary-search-by-from-addr
		   "メールの送信者でメッセージを検索"
		   'summary-search-by-from-addr)
    (add-menu-item menu
		   'summary-search-by-subject
		   "メールの件名で検索..."
		   'summary-search-by-subject)
    (add-menu-item menu
		   'summary-search-by-msgid
		   "メールのIn-Reply-ToもしくはMessage-Idで検索"
		   'summary-search-by-msgid)
    (add-menu-separator menu)
    (add-menu-item menu
		   'summary-flag-toggle
		   "スターを付ける/外す"
		   'summary-flag-toggle)
    (add-menu-separator menu)
    (add-menu-item menu
		   'summary-mark-toggle
		   "マークを付ける/外す"
		   'summary-mark-toggle)
    (add-menu-item menu
		   'summary-mark-all
		   "全てマークする"
		   'summary-mark-all)
    (add-menu-item menu
		   'summary-mark-clear
		   "全てマークを外す"
		   'summary-mark-clear)
    (add-menu-item menu
		   'summary-mark-with-condition
		   "ヘッダの条件を指定してマーク..."
		   'summary-mark-with-condition)
    (add-menu-separator menu)
    (add-menu-item menu
		   'summary-draft-create
		   "メールを新規作成"
		   'summary-draft-create)
    (add-menu-item menu
		   'summary-message-reply
		   "メールに返信"
		   'summary-message-reply)
    (add-menu-item menu
		   'summary-message-reply-all
		   "全員に返信"
		   'summary-message-reply-all)
    (add-menu-item menu
		   'summary-message-forward
		   "メールを転送"
		   'summary-message-forward)
    (add-menu-item menu
		   'summary-message-forward-as-attachment
		   "メールを添付ファイルとして転送"
		   'summary-message-forward-as-attachment)
    (add-menu-separator menu)
    (add-menu-item menu
		   'summary-items-to-archive
		   "メールをアーカイブ"
		   'summary-items-to-archive)
    (add-menu-item menu
		   'summary-items-to-inbox
		   "メールをinboxへ移動"
		   'summary-items-to-inbox)
    (add-menu-item menu
		   'summary-items-to-spam
		   "メールをspamへ移動"
		   'summary-items-to-spam)
    (add-menu-item menu
		   'summary-items-to-trash
		   "メールをtrashへ移動"
		   'summary-items-to-trash)
    (add-menu-separator menu)
    (add-menu-item menu
		   'summary-address-add
		   "送信者をアドレス帳に登録..."
		   'summary-address-add)
    (add-menu-separator menu)
    (add-menu-item menu
		   'summary-connect
		   "サーバに接続"
		   'summary-connect)
    (add-menu-item menu
		   'summary-disconnect
		   "サーバ接続を終了"
		   'summary-disconnect)
    (add-menu-separator menu)
    (add-menu-item menu
		   'show-help
		   "readme.htmlを表示"
		   'show-help)
    (add-menu-item menu
		   'summary-close
		   "メッセージを閉じる/終了"
		   'summary-close)
    (add-menu-item menu
		   'finish
		   "終了"
		   'finish)
    menu))

(defun summary-mouse-right-press ()
  (interactive)
  (set-window *last-mouse-window*)
  (continue-pre-selection)
  (let ((menu (summary-menu-create)))
    (track-popup-menu menu)))

;;;
;;; Items
;;;
(defun summary-get-item (number)
  (assoc number *summary-item-list* :test #'equal))

(defmacro summary-item-number (msg)
  `(car ,msg))

(defmacro summary-item-header (msg)
  `(cadr ,msg))

(defmacro summary-item-flags (msg)
  `(caddr ,msg))

(defun summary-set-header (number header)
  (setf (summary-item-header
	 (assoc number *summary-item-list* :test #'equal)) header))

(defun summary-set-flags (number flags)
  (setf (summary-item-flags
	 (assoc number *summary-item-list* :test #'equal)) flags))

(defun summary-item-delete (num)
  (summary-mark-del num)
  (setq *summary-item-list*
	(delete num *summary-item-list* :key #'car :test #'equal)))

(defun summary-item-current ()
  (multiple-value-bind (from to tag foreground background bold underline strike-out prefix extend)
      (find-text-attribute-point (point))
    (when tag
      (summary-get-item tag))))

;;;
;;; Buffers
;;;
(defun summary-buffer-set ()
  (set-buffer (get-buffer-create *buffer-summary*)))

(defun summary-window-set ()
  (summary-buffer-set)
  (delete-other-windows))

(defun summary-mode ()
  (kill-all-local-variables)
  (make-local-variable 'mode-line-format)
  (make-local-variable 'indent-tabs-mode)
  (setq indent-tabs-mode nil)
  (setq *summary-mark-list* nil)
  (setq buffer-read-only t)
  (setq need-not-save t)
  (setq kept-undo-information nil)
  (setq auto-save nil)
  (toggle-ime nil)
  (set-local-window-flags (selected-buffer)
			  *window-flag-line-number* nil)
  (set-local-window-flags (selected-buffer)
			  *window-flag-newline* nil)
  (set-local-window-flags (selected-buffer)
			  *window-flag-eof* nil)
  (set-local-window-flags (selected-buffer)
			  *window-flag-cursor-line* t)
  (set-buffer-fold-width nil)
  (use-keymap *summary-map*)
  (title-mode-line)
  (run-hooks '*summary-mode-hook*))

;;;
;;; Printing
;;;
(defun summary-delete-backward-to-column (col)
  (while (< col (current-column))
    (delete-backward-char))
  (indent-to col))

(defun summary-print-list (item-list &optional thread-p)
  (junk::modify-read-only-buffer
    (erase-buffer (selected-buffer))
    (if thread-p
	(summary-print-thread item-list)
      (dolist (msg item-list)
	(multiple-value-bind (num header flags)
	    (values-list msg)
	  (summary-print-line num header))))
    (goto-char (point-min))))

(defun summary-print ()
  (summary-print-list *summary-item-list* *summary-print-thread*))

(defun summary-reprint ()
  (let ((line (current-line-number)))
    (summary-print)
    (goto-line line)))

(setq *summary-column-mark*           0)
(setq *summary-column-status*         1)
(setq *summary-column-flag*           2)
(setq *summary-column-multipart*      3)
(setq *summary-column-from-end*      45)

(defun summary-print-line (num header flags &optional indent-string)
  (let* ((path (junk::mail-get-header-value "_lpath" header))
	 (fromstr (junk::mail-get-header-value "from" header))
	 (from fromstr)
	 from-string
	 (title (junk::mail-get-header-value "subject" header))
	 (datestr (junk::mail-get-header-value "date" header))
	 (date (and datestr (junk::rfc822-parse-date (if (listp datestr)
							 (car datestr)
						       datestr))))
	 (multipart-p (junk::mail-multipart-p header))
	 (marked (summary-item-marked num))
	 )
    (multiple-value-bind (email name)
	(junk::parse-address from)
      (setq from-string (or name email from)))
    (apply #'set-text-attribute
	   (point)
	   (progn
	     (insert (summary-mark-string marked))
	     (point))
	   num
	   *summary-attribute-mark*)
    (apply #'set-text-attribute
	   (point)
	   (progn
	     (insert (summary-status-string flags))
	     (point))
	   num
	   *summary-attribute-status*)
    (apply #'set-text-attribute
	   (point)
	   (progn
	     (insert (summary-flag-string flags))
	     (point))
	   num
	   *summary-attribute-flag*)
    (apply #'set-text-attribute
	   (point)
	   (progn
	     (insert (if multipart-p
			 *summary-type-multipart*
		       *summary-type-normal*))
	     (point))
	   num
	   *summary-attribute-multipart*)
    (apply #'set-text-attribute
	   (point)
	   (progn
	     (insert (format-date-string *summary-datetime-format* (or date 0)))
	     (point))
	   num
	   *summary-attribute-date*)
    (apply #'set-text-attribute
	   (point)
	   (progn
	     (insert (format nil "~@[~A~]" from-string))
	     (point))
	   num
	   *summary-attribute-from*)
    (summary-delete-backward-to-column *summary-column-from-end*) ; 適当に桁揃え
    (apply #'set-text-attribute
	   (point)
	   (progn
	     (insert " ")
	     (when indent-string
	       (insert indent-string))
	     (insert (format nil "~@[~A~]" title))
	     (point))
	   num
	   *summary-attribute-title*)
    (insert "\n")))

(defun summary-print-thread (item-list)
  (when item-list
    (long-operation
      (kamailg-message "parsing thread ...")
      (multiple-value-bind (parent-list response-list)
	  (summary-thread-parse item-list)
	(progn
	  (when *debug-mode*
	    (msgbox "~S~%~%~S" parent-list response-list))
	  (kamailg-message "formatting thread ...")
	  (dolist (parent parent-list)
	    (summary-thread-print-recursive parent response-list "" ""))
	  (kamailg-message "formatting thread ... done.")
	  )))))

(defun summary-thread-parse (item-list)
  (let (id-alist
	rp-alist
	response-list
	parent-list)
    (dolist (x item-list)
      (let* ((num (summary-item-number x))
	     (h (summary-item-header x))
	     (message-id  (junk::mail-get-header-value "message-id" h))
	     (in-reply-to (junk::mail-get-header-value "in-reply-to" h))
	     (references  (junk::mail-get-header-value "references" h))
	     tmp
	     )
	(if (and (stringp in-reply-to)
		 (string-match "\\(<[^>]+>\\)" in-reply-to))
	    (setq in-reply-to (match-string 1))
	  (if (stringp references)
	      (progn
		(while (string-match "<[^>]+>" references)
		  (setq tmp (match-string 0))
		  (setq references (substring references (match-end 0) (length references))))
		(if tmp
		    (setq in-reply-to tmp)
		  (setq in-reply-to nil)))))
	(push (cons message-id num) id-alist)
	(push (cons num in-reply-to) rp-alist)))
    (dolist (x (reverse rp-alist))
      (let ((num (car x))
	    (in-reply-to (cdr x))
	    parent
	    )
	(if (and in-reply-to
		 (setq parent (cdr (assoc in-reply-to id-alist :test #'equal))))
	    (let ((childs (cdr (assoc parent response-list))))
	      (if childs
		  (progn
		    (pushnew num childs)
		    (rplacd (assoc parent response-list) childs))
		(push (cons parent (list num)) response-list)))
	  (push num parent-list))))
    (values (nreverse parent-list)
	    (nreverse response-list))))

(defun summary-thread-print-recursive (num response-list indent-prefix indent-string)
  (let ((msg (summary-get-item num)))
    (summary-print-line num
			(cadr msg)
			(nth 2 msg)
			indent-string))
  (let ((childs (reverse (cdr (assoc num response-list))))
	cnt)
    (when childs
      (setq cnt (list-length childs))
      (dotimes (i cnt)
	(let* ((terminate-p (= i (1- cnt)))
	       (child (nth i childs))
	       (next-prefix (if terminate-p
				(concat indent-prefix "   ")
			      (concat indent-prefix "┃ ")))
	       (next-string (if terminate-p
				(concat indent-prefix "┗ ")
			      (concat indent-prefix "┣ "))))
	  (summary-thread-print-recursive child
					  response-list
					  next-prefix
					  next-string))))))

(defun summary-char-update (column str)
  (save-excursion
    (junk::modify-read-only-buffer
      (goto-column column)
      (insert str)
      (delete-char 1)
      )))

;;;
;;; flags
;;;
(defun summary-flag-string (flags)
  (cond ((gmail-flag-flagged flags)
	 *summary-flag-string-flagged*)
	(t
	 *summary-flag-string-normal*)))

(defun summary-flag-update (flags)
  (let ((string (summary-flag-string flags)))
    (summary-char-update *summary-column-flag* string)))

(defun summary-flag-toggle ()
  (interactive)
  (let* ((item (summary-item-current))
	 (num (summary-item-number item))
	 (header (summary-item-header item))
	 (flags (summary-item-flags item))
	 (flagged (gmail-flag-flagged flags))
	 new
	 file)
    (folder-select *account-current* *folder-current*)
    (unless (gmail-uid-store-flagged *account-current*
				     num
				     (if flagged "-" "+"))
      (kamailg-error "gmail-uid-store-flagged: failed."))
    (setq new
	  (if flagged
	      (junk::imap4-flag-del flags junk::*imap4-flag-flagged*)
	    (junk::imap4-flag-add flags junk::*imap4-flag-flagged*)))
    (summary-flag-update new)
    (summary-set-flags num new)
    (summary-result-save)))

;;;
;;; status
;;;
(defun summary-status-string (flags)
  (cond ((junk::imap4-flag-answered flags)
	 *summary-status-answered*)
	((junk::imap4-flag-draft flags)
	 *summary-status-draft*)
	((junk::imap4-flag-recent flags)
	 *summary-status-recent*)
	((junk::imap4-flag-seen flags)
	 *summary-status-seen*)
	(t
	 *summary-status-unseen*)))

(defun summary-status-update (flags)
  (let ((string (summary-status-string flags)))
    (summary-char-update *summary-column-status* string)))

(defun summary-status-toggle ()
  (interactive)
  (let* ((item (summary-item-current))
	 (num (summary-item-number item))
	 (header (summary-item-header item))
	 (flags (summary-item-flags item))
	 (seen (junk::imap4-flag-seen flags))
	 new
	 file)
    (folder-select *account-current* *folder-current*)
    (unless (gmail-uid-store-seen *account-current*
				  num
				  (if seen "-" "+"))
      (kamailg-error "gmail-uid-store-seen: failed."))
    (setq new
	  (if seen
	      (junk::imap4-flag-del flags junk::*imap4-flag-seen*)
	    (junk::imap4-flag-add flags junk::*imap4-flag-seen*)))
    (summary-status-update new)
    (summary-set-flags num new)
    (summary-result-save)))

;;;
;;; Message
;;;
(defun summary-message-file (number)
  (fetch-file-path *account-current* *folder-current* number))

(defun summary-recenter ()
  (recenter))

(defun summary-view-next (&optional (n 1))
  (interactive "p")
  (if (and (forward-line n)
	   (not (eobp)))
      (summary-view-mail-or-scroll)
    (progn
      (when (message-window-get)
	(message-close))
      (if (> n 0)
	  (summary-show-next)
	(summary-show-prev)))))

(defun summary-view-previous (&optional (n -1))
  (interactive "p")
  (summary-view-next n))

(defun summary-view-mail-or-scroll (&optional force noscroll)
  (interactive "p")
  (let* ((msg (summary-item-current))
	 (num (summary-item-number msg))
	 (header (summary-item-header msg))
	 (file (summary-message-file num)))
    (unless file
      (return-from summary-view-mail-or-scroll))
    (multiple-value-bind (res result)
	(fetch-file *account-current*
		    *folder-current*
		    num
		    force)
      (unless res
	(kamailg-error "Fetch error: ~S" result)))
    (if (and (equal file *message-file-current*)
	     (message-window-get)
	     (not noscroll))
	(let (scroll-end)
	  (message-window-set)
	  (setq scroll-end (message-scroll-forward))
	  (other-window 1)
	  (when scroll-end
	    (summary-view-next)))
      (progn
	(summary-recenter)
	(when (message-show file)
	  (other-window 1)
	  (summary-message-seen-if msg)
	  (when (equal (folder-name *folder-current*) *folder-draft*)
	    (summary-message-edit))
	  )))))

(defun summary-view-next-unseen ()
  (interactive)
  (let (line)
    (save-excursion
      (goto-char (point-min))
      (loop
	(goto-column *summary-column-status*)
	(when (equal (format nil "~C" (char-after (point)))
		     *summary-status-unseen*)
	  (setq line (current-line-number))
	  (return))
	(or (forward-line) (return))))
    (if line
	(progn
	  (goto-line line)
	  (summary-view-mail-or-scroll))
      (kamailg-message "未読はありません。"))))

(defun summary-fetch-current-items ()
  (interactive)
  (let ((cnt 0))
    (dolist (item *summary-item-list*)
      (let* ((num (summary-item-number item))
	     (file (summary-message-file num)))
	(unless (file-exist-p file)
	  (incf cnt)
	  (multiple-value-bind (res result)
	      (fetch-file *account-current*
			  *folder-current*
			  num)
	    (unless res
	      (kamailg-error "Fetch error: ~S" result))))))
    (kamailg-message "Fetched ~D messages." cnt)))

(defun summary-close ()
  (interactive)
  (if (message-window-get)
      (message-close)
    (finish)))

;;;
;;; Mark
;;;
(defun summary-mark-string (marked)
  (if marked
      *summary-mark-string-marked*
    *summary-mark-string-normal*))

(defun summary-item-marked (num)
  (member num *summary-mark-list* :test #'equal))

(defun summary-mark-update (marked)
  (let ((string (summary-mark-string marked)))
    (summary-char-update *summary-column-mark* string)))

(defun summary-mark-add (num)
  (pushnew num *summary-mark-list* :test #'equal))

(defun summary-mark-del (num)
  (setq *summary-mark-list*
	(delete num *summary-mark-list* :test #'equal)))

(defun summary-mark-toggle ()
  (interactive)
  (let* ((msg (summary-item-current))
	 (num (car msg))
	 (marked (summary-item-marked num)))
    (when num
      (if marked
	  (progn
	    (summary-mark-del num)
	    (summary-mark-update (not marked)))
	(progn
	  (summary-mark-add num)
	  (summary-mark-update (not marked)))))))

(defun summary-mark-all ()
  (interactive)
  (dolist (msg *summary-item-list*)
    (let ((num (car msg)))
      (summary-mark-add num)))
  (summary-reprint))

(defun summary-mark-clear ()
  (interactive)
  (dolist (msg *summary-item-list*)
    (let ((num (car msg)))
      (summary-mark-del num)))
  (summary-reprint))

(defun summary-mark-with-condition ()
  (interactive)
  (let ((condition (read-string "Mark Condition: "))
	matched
	field
	regex)
    (when (stringp condition)
      (setq condition (string-trim " \t\n" condition)))
    (unless (string-match "^\\([-0-9a-zA-Z]+\\):\\(.+\\)$" condition)
      (kamailg-message "not condition: ~A" condition)
      (return-from summary-mark-with-condition))
    (setq field (match-string 1)
	  regex (match-string 2))
    (when (and field regex)
      (dolist (msg *summary-item-list*)
	(let* ((num (summary-item-number msg))
	       (header (summary-item-header msg))
	       (value (junk::mail-get-header-value field header)))
	  (when (and (stringp value)
		     (string-match regex value))
	    (summary-mark-add num)))))
    (summary-reprint)))

;;;
;;; Move messages
;;;
(defun summary-items-to-folder ()
  (interactive)
  (let ((folder-name (folder-completing-read)))
    (when folder-name
      (summary-item-move-to folder-name))))

(defun summary-items-to-archive ()
  (interactive)
  (summary-item-move-to *folder-archive*))

(defun summary-items-to-inbox ()
  (interactive)
  (summary-item-move-to *folder-inbox*))

(defun summary-items-to-spam ()
  (interactive)
  (summary-item-move-to *folder-spam*))

(defun summary-items-to-trash ()
  (interactive)
  (summary-item-move-to *folder-trash*))

(defun summary-item-move-to (folder-name)
  (let* ((msg (summary-item-current))
	 (num (summary-item-number msg))
	 (header (summary-item-header msg))
	 (file (summary-message-file num)))
    (unless file
      (return-from summary-item-move-to))
    (if (and (equal file *message-file-current*)
	     (message-window-get))
	(progn
	  (summary-move-folder folder-name)
	  (message-close))
      (summary-move-items-to-folder *summary-mark-list* folder-name))))

(defun summary-move-items-to-folder (uid-list folder-name)
  (let* ((tmp-list (copy-list uid-list))
	 (folder (folder-get folder-name *folder-list-current*)))
    (unless uid-list
      (return-from summary-move-items-to-folder))
    (unless folder
      (kamailg-error "summary-move-items-to-folder: unknown folder ~S" folder-name))
    (when (equal folder-name
		 (folder-name *folder-current*))
      (kamailg-message "~A is current folder." folder-name)
      (return-from summary-move-items-to-folder))
    (unless (folder-select *account-current* *folder-current*)
      (kamailg-error "summary-move-folder: folder-select error."))
    (multiple-value-bind (ok-p return)
	(gmail-uid-move-messages *account-current*
				 uid-list
				 folder)
      (unless ok-p
	(kamailg-error "summary-move-folder: error.~%~S" return)
	(return-from summary-move-items-to-folder)))
    (dolist (uid tmp-list)
      (summary-item-delete uid))
    (summary-result-save)
    (summary-reprint)
    ))

(defun summary-move-folder (folder-name)
  (let* ((msg (summary-item-current))
	 (num (summary-item-number msg)))
    (summary-move-items-to-folder (list num) folder-name)))

;;;
;;; Addresses
;;;
(defun summary-address-add ()
  (interactive)
  (let* ((msg (summary-item-current))
	 (num (summary-item-number msg))
	 (header (summary-item-header msg))
	 (from (junk::mail-get-header-value "from" header)))
    (when from
      (let ((from-list (junk::parse-addresses from)))
	(dolist (f from-list)
	  (let ((email (car f))
		(name (cdr f)))
	    (junk::mail-address-add email name)))))))

;;;
;;; Search
;;;
(defun summary-search-do (query &optional force)
  (let* ((folder (folder-get *folder-archive* *folder-list-current*))
	 result)
    (when (and query folder)
      (setf (query-folder query) folder)
      (account-connect *account-current*)
      (unless (setq result (search-execute *account-current*
					   query
					   force))
	(kamailg-message "No match.")
	(return-from summary-search-do))
      (summary-show result))))

(defun summary-search (&optional force)
  (interactive "p")
  (let* ((query-string
	  (read-string "Search: "
		       :default (search-history-current-strings)))
	 (query (search-string-parse query-string)))
    (when query
      (summary-search-do query force))))

(defun summary-search-history-select-menu (&optional add-header)
  (let ((menu (create-popup-menu)))
    (when add-header
      (add-menu-item menu
		     nil
		     "Search History"
		     nil
		     #'(lambda () :disable))
      (add-menu-separator menu))
    (dolist (q *search-history-current*)
      (let ((query q)
	    (name (query-string q)))
	(when name
	  (add-menu-item menu
			 nil
			 (junk::abbreviate-menu-string name)
			 #'(lambda ()
			     (interactive)
			     (summary-search-do query))))))
    menu))

(defun summary-search-history-select ()
  (interactive)
  (when *search-history-current*
    (let ((menu (summary-search-history-select-menu t)))
      (track-popup-menu menu))))

#|
(defun summary-save-as-folder ()
  (interactive)
  (when *query-last-folder*
    (kamailg-error "フォルダは保存できません。"))
  (let* ((prompt "Folder name: ")
	 (query *query-last-query*)
	 (name (read-string prompt
			    :default (query-folder-name-default query))))
    (while (or (not (query-string-or-null name))
	       (folder-get name))
      (setq name (read-string prompt :default name)))
    (folder-add name query)))
|#

(defun summary-search-by-from ()
  (interactive)
  (let* ((msg (summary-item-current))
	 (num (summary-item-number msg))
	 (header (summary-item-header msg))
	 (from (junk::mail-get-header-value "from" header))
	 query)
    (when from
      (multiple-value-bind (email name)
	  (junk::parse-address from)
	(when email
	  (when (setq query (search-string-parse (concat "from:" email)))
	    (summary-search-do query)))))))

(defun summary-search-by-from-addr ()
  (interactive)
  (let* ((msg (summary-item-current))
	 (num (summary-item-number msg))
	 (header (summary-item-header msg))
	 (from (junk::mail-get-header-value "from" header))
	 query)
    (when from
      (multiple-value-bind (email name)
	  (parse-address from)
	(when email
	  (summary-search-do (make-query :string email :words (list email))))))))

(defun summary-search-by-subject ()
  (interactive)
  (let* ((msg (summary-item-current))
	 (num (summary-item-number msg))
	 (header (summary-item-header msg))
	 (subject (junk::mail-get-header-value "subject" header)))
    (when subject
      (let ((str (read-string "Subject: "
			      :default subject)))
	(when str
	  (summary-search-do (make-query :string str :words (list str))))))))

(defun summary-search-by-msgid ()
  (interactive)
  (let* ((msg (summary-item-current))
	 (num (summary-item-number msg))
	 (header (summary-item-header msg))
	 (message-id (junk::mail-get-header-value "message-id" header))
	 (in-reply-to (junk::mail-get-header-value "in-reply-to" header))
	 ids)
    (when (or in-reply-to message-id)
      (setq ids (junk::rfc822-parse-msgid (or in-reply-to message-id)))
      (when (car ids)
	(let ((id (car ids)))
	  (setq id (string-trim "<>" id))
	  (summary-search-do (make-query :string id :words (list id))))))))

#|
(defun summary-search-by-thread ()
  (interactive)
  (let* ((msg (summary-item-current))
	 (num (summary-item-number msg))
	 (header (summary-item-header msg))
	 (message-id (junk::mail-get-header-value "message-id" header))
	 (references (junk::mail-get-header-value "references" header))
	 (in-reply-to (junk::mail-get-header-value "in-reply-to" header))
	 ids)
    (when (or message-id references in-reply-to)
      (dolist (f (list message-id references in-reply-to))
	(when f
	  (let ((tmp (junk::rfc822-parse-msgid f)))
	    (dolist (id tmp)
	      (pushnew id ids :test #'equal)))))
      (when ids
	(let ((fields "message-id,references,in-reply-to")
	      query)
	  (if (< 1 (list-length ids))
	      (let ((regexp (concat "("
				    (junk::string-join (mapcar #'(lambda (x)
								   (regexp-quote x))
							       ids)
						       "|")
				    ")")))
		(setq query
		      (make-query
		       :string (concat fields "~" regexp))))
	    (setq query
		  (make-query
		   :string (concat fields ":" (car ids)))))
	  (query-execute query)
	  )))))
|#

;;;
;;; partial messages
;;;
(defun summary-parse-partial-message (msg)
  (let* ((num (summary-item-number msg))
	 (header (summary-item-header msg))
	 (content-type (junk::mail-get-header-content "content-type" header)))
    (when content-type
      (let ((message (junk::mail-get-header-option-value "message" content-type))
	    (id (junk::mail-get-header-option-value "id" content-type))
	    (number (junk::mail-get-header-option-value "number" content-type))
	    (total (junk::mail-get-header-option-value "total" content-type)))
	(when (and (equalp message "partial")
		   id
		   number
		   total)
	  (values id
		  (parse-integer number)
		  (parse-integer total)))))))

(defun summary-search-partial-messages (partial-id)
  (let (msgs)
    (dolist (msg *summary-item-list*)
      (multiple-value-bind (id number total)
	  (summary-parse-partial-message msg)
	(when (and id
		   (equal partial-id id))
	  (push (cons number msg) msgs))))
    (sort msgs #'< :key #'car)))

(defun summary-show-message-partial ()
  (interactive)
  (let* ((msg (summary-item-current))
	 (num (summary-item-number msg))
	 (header (summary-item-header msg))
	 msgs)
    (multiple-value-bind (id number total)
	(summary-parse-partial-message msg)
      (when id
	(let ((msgs (summary-search-partial-messages id)))
	  (unless (= (length msgs) total)
	    (kamailg-error "total number mismatch: ~D != ~D"
			   total
			   (length msgs)
			   ))
	  (save-excursion
	    (set-buffer (get-buffer-create *summary-buffer-partial-temp*))
	    (erase-buffer (selected-buffer))
	    (dolist (m msgs)
	      (let* ((header (summary-item-header (cdr m)))
		     (file (summary-message-file (summary-item-number (cdr m))))
		     (beg (point))
		     end)
		(insert-file-noconv file)
		(when (junk::mail-goto-body-beg)
		(delete-region beg (point)))
		(goto-char (point-max))
		(loop
		  (setq end (point))
		  (or (forward-line -1) (return))
		  (or (eolp) (return)))
		(delete-region end (point-max))))
	    (write-region (point-min)
			  (point-max)
			  *summary-message-partial-temp*))
	  (delete-buffer *summary-buffer-partial-temp*)
	  (message-show *summary-message-partial-temp*)
	  )))))

(defun summary-folder-open (account folder-name &optional force)
  (let ((folder (folder-get folder-name *folder-list-current*)))
    (when folder
      (summary-show (search-folder account folder force)))))

(defun summary-show (result)
  (setq *summary-last-result* result)
  (setq *summary-item-list* (result-headers result))
  (setq *summary-mark-list* nil)
  (summary-print)
  (summary-mode-line))

(defun summary-result-save ()
  (setf (result-headers *summary-last-result*) *summary-item-list*)
  (search-result-save *account-current* *summary-last-result*))

(defun summary-reload ()
  (interactive)
  (unless *summary-last-result*
    (return-from summary-reload))
  (let ((query (result-query *summary-last-result*))
	(limit (result-limit *summary-last-result*))
	(offset (result-offset *summary-last-result*)))
    (when query
      (summary-show (search-execute *account-current*
				    query
				    t
				    :limit limit
				    :offset offset)))))

(defun summary-folder-reload ()
  (interactive)
  (folder-list *account-current*))

(defun summary-folder-add ()
  (interactive)
  (let ((folder-name (read-string "New folder: ")))
    (unless folder-name
      (return-from summary-folder-add))
    (when (folder-get folder-name *folder-list-current*)
      (kamailg-message "folder exists: ~A" folder-name)
      (return-from summary-folder-add))
    (multiple-value-bind (flag return)
	(folder-add *account-current* folder-name)
      (if flag
	  (progn
	    (summary-folder-reload)
	    (kamailg-message "folder added: ~A" folder-name))
	(kamailg-error "summary-folder-add: error: ~S" return)))))

(defun summary-folder-del ()
  (interactive)
  (let ((folder-name (folder-completing-read *folder-list-current* t "Delete folder: ")))
    (unless folder-name
      (return-from summary-folder-del))
    (multiple-value-bind (flag return)
	(folder-delete *account-current* folder-name)
      (if flag
	  (progn
	    (summary-folder-reload)
	    (kamailg-message "folder deleted: ~A" folder-name))
	(kamailg-error "summary-folder-del: error: ~S" return)))))

(defun summary-account-select-menu (&optional add-header)
  (let ((menu (create-popup-menu)))
    (when add-header
      (add-menu-item menu
		     nil
		     "Accounts"
		     nil
		     #'(lambda () :disable))
      (add-menu-separator menu))
    (dolist (account *account-list*)
      (let ((email (account-email account)))
	(add-menu-item menu
		       email
		       email
		       #'(lambda ()
			   (interactive)
			   (account-change email))
		       #'(lambda ()
			   (if (equal email (account-email *account-current*)) :check)))
	))
    menu))

(defun summary-account-select ()
  (interactive)
  (when (and *account-list*
	     (< 1 (length *account-list*)))
    (let ((menu (summary-account-select-menu t)))
      (track-popup-menu menu))))

(defun summary-open-folder-menu (&optional add-header)
  (let ((menu (create-popup-menu)))
    (when add-header
      (add-menu-item menu
		     nil
		     "Folders"
		     nil
		     #'(lambda () :disable))
      (add-menu-separator menu))
    (dolist (folder *folder-list-current*)
      (let ((folder-name (folder-name folder)))
	(add-menu-item menu
		       folder-name
		       folder-name
		       #'(lambda ()
			   (interactive)
			   (summary-folder-open *account-current* folder-name))
		       #'(lambda ()
			   (if (equal folder-name (folder-name *folder-current*)) :check)))
	))
    menu))

(defun summary-open-folder-select ()
  (interactive)
  (when *folder-list-current*
    (let ((menu (summary-open-folder-menu t)))
      (track-popup-menu menu))))

(defun summary-open-folder (&optional force)
  (interactive "p")
  (let ((folder-name (folder-completing-read nil t)))
    (when folder-name
      (summary-folder-open *account-current* folder-name force))))

(defun summary-open-inbox (&optional force)
  (interactive "p")
  (summary-folder-open *account-current* *folder-inbox* force))

(defun summary-open-draft (&optional force)
  (interactive "p")
  (summary-folder-open *account-current* *folder-draft* force))

(defun summary-open-starred (&optional force)
  (interactive "p")
  (summary-folder-open *account-current* *folder-starred* force))

(defun summary-open-spam (&optional force)
  (interactive "p")
  (summary-folder-open *account-current* *folder-spam* force))

(defun summary-open-trash (&optional force)
  (interactive "p")
  (summary-folder-open *account-current* *folder-trash* force))

(defun summary-open-sent (&optional force)
  (interactive "p")
  (summary-folder-open *account-current* *folder-sent* force))

(defun summary-show-next (&optional force)
  (interactive "p")
  (let ((result (search-execute-next *account-current*
				     *summary-last-result*
				     force)))
    (if result
	(summary-show result)
      (kamailg-message "No next messages."))))

(defun summary-show-prev (&optional force)
  (interactive "p")
  (let ((result (search-execute-prev *account-current*
				     *summary-last-result*
				     force)))
    (if result
	(summary-show result)
      (kamailg-message "No previous messages."))))

(defun summary-mode-line (&optional result)
  (setq result (or result *summary-last-result*))
  (let* ((query (result-query result))
	 (searched (result-searched result))
	 (limit (result-limit result))
	 (offset (result-offset result))
	 (folder (query-folder query))
	 (string (query-string query))
	 (folder-name (if (folder-p folder) (folder-name folder) nil)))
    (setq mode-line-format (format nil "%b: ~@[~A~]~@[ \"~A\"~] (~D-~D/~D)"
				   folder-name
				   string
				   (1+ offset)
				   (min (+ offset limit) searched)
				   searched))
    ))

(defun summary-message-seen-if (item &optional (update-server t))
  (let* ((num (summary-item-number item))
	 (header (summary-item-header item))
	 (flags (summary-item-flags item))
	 new
	 file)
    (unless (gmail-flag-seen flags)
      (when update-server
	(folder-select *account-current* *folder-current*)
	(multiple-value-bind (ok-p return)
	    (gmail-uid-store-seen *account-current* num)
	  (unless ok-p
	    (kamailg-error "gmail-uid-store-seen: failed: ~S" return))))
      (setq new (junk::imap4-flag-add flags junk::*imap4-flag-seen*))
      (summary-set-flags num new)
      (summary-status-update new)
      (summary-result-save))))

(defun summary-message-unseen-if (item &optional (update-server t))
  (let* ((num (summary-item-number item))
	 (header (summary-item-header item))
	 (flags (summary-item-flags item))
	 new
	 file)
    (when (gmail-flag-seen flags)
      (when update-server
	(folder-select *account-current* *folder-current*)
	(multiple-value-bind (ok-p return)
	    (gmail-uid-store-seen *account-current* num "-")
	  (unless ok-p
	    (kamailg-error "gmail-uid-store-seen: failed: ~S" return))))
      (setq new (junk::imap4-flag-del flags junk::*imap4-flag-seen*))
      (summary-set-flags num new)
      (summary-status-update new)
      (summary-result-save))))

;;;
;;; Attachments
;;;

(defun summary-message-save-attachment ()
  (interactive)
  (summary-view-mail-or-scroll nil t)
  (when (message-window-get)
    (message-window-set)
    (refresh-screen)
    (junk::mail-view-save-attachment-select)))

(defun summary-message-save-execute-attachment ()
  (interactive)
  (summary-view-mail-or-scroll nil t)
  (when (message-window-get)
    (message-window-set)
    (refresh-screen)
    (junk::mail-view-save-execute-attachment-select)))

;;;
;;; Draft
;;;

(defun summary-draft-create ()
  (interactive)
  (when (message-window-get)
    (message-window-set))
  (draft-create))

(defun summary-message-draft-func (func)
  (unless (message-window-get)
    (summary-view-mail-or-scroll nil t))
  (when (message-window-get)
    (message-window-set)
    (funcall func)))

(defun summary-message-edit ()
  (interactive)
  (let* ((item (summary-item-current))
	 (num (summary-item-number item))
	 (header (summary-item-header item)))
    (when num
      (summary-message-draft-func 'message-edit)
      (setq *draft-current-number* num)
      (setq *draft-current-folder* *folder-current*))))

(defun summary-message-reply ()
  (interactive)
  (summary-message-draft-func 'message-reply))

(defun summary-message-reply-all ()
  (interactive)
  (summary-message-draft-func 'message-reply-all))

(defun summary-message-forward ()
  (interactive)
  (summary-message-draft-func 'message-forward))

(defun summary-message-forward-as-attachment ()
  (interactive)
  (summary-message-draft-func 'message-forward-as-attachment))

(defun summary-connect ()
  (interactive)
  (account-connect *account-current*))

(defun summary-disconnect ()
  (interactive)
  (account-disconnect *account-current*))
