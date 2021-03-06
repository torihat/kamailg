; $Id: util.l 762 2007-12-14 10:36:54Z torihat $

(require "util")

(setq *util-name* "kamailg")
(setq *util-version* "0.0.0.1-alpha")
(setq *util-prog-name* "KaMailG")

(setq *util-dev-dir*
  (merge-pathnames (concat "dev/" *util-name*) (si:system-root)))
(setq *util-targ-dir*
  (merge-pathnames (concat "site-lisp/" *util-name*) (si:system-root)))
(setq *util-archive-dir*
  (merge-pathnames "mirai/xyzzy/" (si:system-root)))

(setq *make-root-directory* *util-dev-dir*)

(setq *util-archive-file*
  (format nil "~A-~A.lzh"
	  *util-name*
	  *util-version*))

(setq *util-file-list* '(
			 ("readme.html")
			 ("readme.css")
			 ("LICENSE.txt")
			 ("config.l.sample")
			 ("defs.l")
			 ("defs.lc")
			 ("gmail.l")
			 ("gmail.lc")
			 ("account.l")
			 ("account.lc")
			 ("message.l")
			 ("message.lc")
			 ("summary.l")
			 ("summary.lc")
			 ("fetch.l")
			 ("fetch.lc")
			 ("folder.l")
			 ("folder.lc")
			 ("search.l")
			 ("search.lc")
			 ("mhtml.l")
			 ("mhtml.lc")
			 ("autoload.l" . "site-lisp/ni-autoload/JunkScripts/kamailg.l")
			 ))

(require "ni/local")

(setq ni::*local-data-file* "C:/xyzzy/mirai/packages.l")
