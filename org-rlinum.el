;;; org-rlinum.el --- display relative line correctly for org-mode

;; Author: Rui Zhao
;; Version: 0.0.1
;; Keywords: convenience

;;; Code:

(eval-when-compile (require 'cl))
(require 'linum)

(defgroup org-rlinum nil
  "Show relative line number on fringe, espically for org-mode."
  :group 'convenience)

(defcustom org-rlinum-format-str "%3d"
  "Format for displaying relative line numbers."
  :type 'string
  :group 'org-rlinum)

(defcustom org-rlinum-current-marker " ~>"
  "Current line marker."
  :type 'string
  :group 'org-rlinum)

;; Internal Variables
(defvar org-rlinum-last-pos 0
  "Store last position.")

(defvar org-rlinum-pcounter 0
  "Store number of positive lines.")

(defvar org-nlinum-ncounter 0
  "Store number of negative lines.")

(defvar org-rlinum-plist '()
  "Store line number of positive lines.")

(defvar org-rlinum-nlist '()
  "Store line number of negative lines.")

(defun org-rlinum-build-plist ()
  "Build positive lines' list in the windows from bottom up."
  (save-excursion
    (beginning-of-line)
    (setq org-rlinum-pcounter 0)
    (setq org-rlinum-plist '())
    (let ((rsize 0))
      (while (and (<= (point) (window-end))
                  (< (point) (point-max)))
        (incf rsize)
        (line-move-visual 1 t)
        (add-to-list 'org-rlinum-plist (line-number-at-pos)))
      (setq org-rlinum-plist (reverse org-rlinum-plist)))))

(defun org-rlinum-build-nlist ()
  "Build negative lines' list in the windows from top down."
  (save-excursion
    (beginning-of-line)
    (setq org-rlinum-ncounter 0)
    (setq org-rlinum-nlist '())
    (let ((rsize 0))
      (while (and (>= (point) (window-start))
                  (> (point) (point-min)))
        (incf rsize)
        (add-to-list 'org-rlinum-nlist (line-number-at-pos))
        (line-move-visual -1 t)
        (incf org-rlinum-ncounter)))))

(defun org-rlinum-update-face (line)
  "Update face according to line numbers."
  (cond ((eq line -1)
         (propertize "" 'face 'linum))
        ((eq line 0)
         (propertize org-rlinum-current-marker 'face 'linum))
        (t
         (propertize
          (format org-rlinum-format-str line)
          'face
          'linum))))

(defun org-rlinum-org (line)
  "Update relative line number for org mode."
  (if (> org-rlinum-ncounter 0)
      (if (eq line (car-safe org-rlinum-nlist))
          (progn
            (setq org-rlinum-nlist (cdr-safe org-rlinum-nlist))
            (org-rlinum-update-face (decf org-rlinum-ncounter)))
        (org-rlinum-update-face -1))
    (if (eq line (car-safe org-rlinum-plist))
        (progn
          (setq org-rlinum-plist (cdr-safe org-rlinum-plist))
          (org-rlinum-update-face (incf org-rlinum-pcounter)))
      (org-rlinum-update-face -1))))

(defun org-rlinum-normal (line)
  "Update relative line number for normal mode."
  (org-rlinum-update-face (abs (- line org-rlinum-last-pos))))

(defadvice linum-update (before org-rlinum-update activate)
  "This advice get the last pos and build positive and negative
list."
  (setq org-rlinum-last-pos (line-number-at-pos))
  (when (eq linum-format 'org-rlinum-org)
    (org-rlinum-build-nlist)
    (org-rlinum-build-plist)))

(defun org-rlinum-toggle ()
  "Toggle between org-rlinum mode and normal relative line mode."
  (interactive)
  (if (eq linum-format 'org-rlinum-normal)
      (setq linum-format 'org-rlinum-org)
    (setq linum-format 'org-rlinum-normal)))

(defun org-rlinum-relative-toggle ()
  "Display non-relative number on fringe."
  (interactive)
  (if (eq linum-format 'dynamic)
      (setq linum-format 'org-rlinum-normal)
    (setq linum-format 'dynamic)))

(setq linum-format 'org-rlinum-normal)

(provide 'org-rlinum)
