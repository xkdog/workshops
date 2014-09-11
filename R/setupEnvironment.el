;; make R save and restore instead of using sessions; this gives the input and output as displayed by the R console
(set (make-local-variable 'org-babel-R-command) "R --silent --save --restore")

;; set up syntax highlighting (requires the "pygments" python package and the "minted" latex package installed on your system)
(set (make-local-variable 'org-latex-listings) 'minted)
(set (make-local-variable 'org-latex-minted-options) '(("fontsize" "\\scriptsize")))

;; make sure latex is run enough times, and enable shell-escape so that pygments syntax highlighting works
(set (make-local-variable 'org-latex-pdf-process) '("pdflatex -shell-escape -interaction nonstopmode -output-directory %o %f" 
						    "pdflatex -shell-escape -interaction nonstopmode -output-directory %o %f"))
(set (make-local-variable 'LaTeX-command) "pdflatex -shell-escape")

;; don't let orgmode resize images (this means you must set them to the correct size when generating!)
(set (make-local-variable 'org-latex-image-default-option) "")

;; present all output in blocks
(set (make-local-variable 'org-babel-min-lines-for-block-output) 0)

;; do not re-evaluate source code on export
(set (make-local-variable 'org-export-babel-evaluate) nil)

;; enable source code support in orgmode
(org-babel-do-load-languages
 'org-babel-load-languages
 '(;(stata . t) ;; requires custom ob-stata.el
   (emacs-lisp . t)
   (sh . t)
   (R . t)
   (latex . t)
   (octave . t)
   (ditaa . t)
   (org . t)
   (perl . t)
   (python . t)
   (matlab . t)))

;; tell minted that R blocks should be highighted using r syntax
(add-to-list 'org-latex-minted-langs '(R "r"))

;; display images in the orgmode buffer automatically
(add-hook 'org-babel-after-execute-hook 'org-display-inline-images)

;; wrap results blocks in minted for syntax highlighting
(defun my-latex-fixed-width-start (fixed-width backend info)
  (when (org-export-derived-backend-p backend 'latex)
    (replace-regexp-in-string
     "\\(begin{verbatim\\)}"
     "vspace{-.5em}
\\\\begin{columns}
\\\\column{.95\\\\linewidth}
\\\\begin{block}{}
\\\\begin{minted}[linenos=false, fontsize=\\\\footnotesize]{rconsole" fixed-width nil nil 1)))

(defun my-latex-fixed-width-end (fixed-width backend info)
  (when (org-export-derived-backend-p backend 'latex)
    (replace-regexp-in-string
     "\\(end\\){\\(verbatim\\)}"
     "minted}
\\\\end{block}
\\\\end{columns}
\\\\vspace{.5em" fixed-width nil nil 2)))

(make-local-variable 'org-export-filter-final-output-functions)

(add-to-list 'org-export-filter-final-output-functions
             'my-latex-fixed-width-start)
(add-to-list 'org-export-filter-final-output-functions
             'my-latex-fixed-width-end)

;; convenience function to export headings to markdown chapters for upload to datacamp
(defun my-exp-to-datacamp (course)
  "Export org mode file to form suitable for upload to datacamp.org."
  (interactive "sEnter course name: ")
  ;; make datacamp directory if it doesn't exist
  (if (file-directory-p "datacamp") nil (make-directory "datacamp"))
  ;; demarcate code blocks on markdown export (needed for datacamp)
  (defun my-md-src-block-replace (text backend info)
    (when (org-export-derived-backend-p backend 'md)
      (concat "```{r eval = FALSE}\n" text "```\n")))
  (add-to-list 'org-export-filter-src-block-functions
	       'my-md-src-block-replace)
  ;; include html comments
  (defun my-md-keyword-replace (text backend info)
    (when (org-export-derived-backend-p backend 'md)
      (replace-regexp-in-string
       "\\(<!-- MD: \\)\\(.*\\)\\(-->\\)"
       "\\2" text nil nil)))
  (make-local-variable 'org-export-filter-keyword-functions)
  (add-to-list 'org-export-filter-keyword-functions
               'my-md-keyword-replace)
  ;; export headings to separate files
  (org-map-entries
   (lambda ()
     ;; some magic I don't understand written by John Kitchin on the orgmode mailing list
     (let ((level (nth 1 (org-heading-components)))
           (title (nth 4 (org-heading-components))))
       (when (= level 1)
	 ;; add meta data to top of each exported file
	 (defun my-md-filter-add-meta-data (text backend info)
	   "Ensure \" \" are properly handled in Md export."
	   (when (org-export-derived-backend-p backend 'md)
	     (concat 
"--- 
courseTitle       : " course "
chapterTitle      : " title "
description       : 
framework         : datamind
mode              : selfcontained
---

" text)))
	 (add-to-list 'org-export-filter-final-output-functions
		      'my-md-filter-add-meta-data)
	 ;; set up export file names and turn of table of contents 
         (org-entry-put (point) "EXPORT_FILE_NAME" (concat "datacamp/" title))
	 (org-entry-put (point) "EXPORT_OPTIONS" "num:nil toc:nil")
	 ;; export each heading
         (org-md-export-to-markdown nil 1 nil)
	 ;; rename files with .Rmd extension
	 (rename-file (concat "datacamp/" title ".md") (concat "datacamp/" title ".Rmd") t)))))
  ;; remove changed settings
  (setq org-export-filter-final-output-functions (delete 'my-md-filter-add-meta-data org-export-filter-final-output-functions))
  (setq org-export-filter-src-block-functions (delete 'my-md-src-block-replace org-export-filter-src-block-functions))
  (setq org-export-filter-keyword-functions (delete 'my-md-keyword-replace org-export-filter-keyword-functions))
  nil nil)


	       