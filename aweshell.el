;;; aweshell.el --- Awesome eshell

;; Filename: aweshell.el
;; Description: Awesome eshell
;; Author: Andy Stewart <lazycat.manatee@gmail.com>
;; Maintainer: Yuan Fu <casouri@gmail.com>
;; Copyright (C) 2018, Andy Stewart, all rights reserved.
;; Created: 2018-08-13 23:18:35
;; Version: 2.9
;; URL: https://github.com/casouri/aweshell
;; Keywords:
;; Compatibility: GNU Emacs 27.0.50

;;; This file is NOT part of GNU Emacs

;;; License
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.

;;; Commentary:
;;
;; Andy created `multi-term.el' and used it for many years.
;; Now he is a big fans of `eshell'.
;;
;; So he write `aweshell.el' to extension `eshell' with below features:
;; 1. Create and manage multiple eshell buffers.
;; 2. Add some useful commands, such as: clear buffer, toggle sudo etc.
;; 3. Display extra information and color like zsh, powered by `eshell-prompt-extras'
;; 4. Add Fish-like history autosuggestions, powered by `esh-autosuggest', support histories from bash/zsh/eshell.
;; 5. Validate and highlight command before post to eshell.
;; 6. Change buffer name by directory change.
;; 7. Add completions for git command.
;; 8. Fix error `command not found' in MacOS.
;; 9. Integrate `eshell-up'.
;; 10. Unpack archive file.
;; 11. Open file with alias e.
;; 12. Output "did you mean ..." helper when you typo.
;; 13. Make cat file with syntax highlight.
;; 14. Alert user when background process finished or aborted.
;; 15. IDE-like completion for shell commands.
;; 16. Borrow fish completions
;; 17. Robust prompt

;;; Installation:
;;
;; Put all elisp files to your load-path.
;; The load-path is usually ~/elisp/.
;; It's set in your ~/.emacs like this:
;; (add-to-list 'load-path (expand-file-name "~/elisp"))
;;
;; And the following to your ~/.emacs startup file.
;;
;; (require 'aweshell)
;;
;; Binding your favorite key to functions:
;;
;; `aweshell-new'
;; `aweshell-next'
;; `aweshell-prev'
;; `aweshell-clear-buffer'
;; `aweshell-sudo-toggle'
;;

;;; Customize:
;;
;; `aweshell-eof-before-return'
;;
;; All of the above can customize by:
;;      M-x customize-group RET aweshell RET
;;

;;; Change log:
;;;
;; 2019/01/11
;;      * Remove key variables, instead use `aweshell-mode-map'
;;      * Replace color variables with faces
;;      * Many other changes...
;; 2018/12/14
;;      * Change option `aweshell-autosuggest-backend' to `aweshell-autosuggest-frontend' for clarity.
;;
;; 2018/12/14
;;      * Add new option `aweshell-autosuggest-backend' to swtich between fish-style and company-style.
;;
;; 2018/11/12
;;	* Remove Mac color, use hex color instead.
;;
;; 2018/10/19
;;      * Alert user when background process finished or aborted.
;;
;; 2018/09/19
;;      * Make `exec-path-from-shell' optional. Disable with variable`aweshell-use-exec-path-from-shell'.
;;
;; 2018/09/17
;;      * Use `ido-completing-read' instead `completing-read' to provide fuzz match.
;;
;; 2018/09/10
;;      * Built-in `eshell-did-you-mean' plugin.
;;
;; 2018/09/07
;;      * Add docs about `eshell-up', `aweshell-emacs' and `aweshell-unpack'
;;      * Add `aweshell-cat-with-syntax-highlight' make cat file with syntax highlight.
;;
;; 2018/09/06
;;      * Require `cl' to fix function `subseq' definition.
;;
;; 2018/08/16
;;      * Just run git relative code when git in exec-path.
;;      * Use `esh-parse-shell-history' refacotry code.
;;      * Try to fix error "Shell command failed with code 1 and no output" cause by LANG environment variable.
;;
;; 2018/08/15
;;      * Remove face settings.
;;      * Add `aweshell-search-history' and merge bash/zsh history in `esh-autosuggest' .
;;      * Fix history docs.
;;
;; 2018/08/14
;;      * Save buffer in `aweshell-buffer-list', instead save buffer name.
;;      * Change aweshell buffer name by directory change.
;;      * Refacotry code.
;;      * Fix error "wrong-type-argument stringp nil" by `aweshell-validate-command'
;;      * Add some handy aliases.
;;      * Make `aweshell-validate-command' works with eshell aliases.
;;      * Synchronal buffer name with shell path by `epe-fish-path'.
;;      * Use `epe-theme-pipeline' as default theme.
;;      * Complete customize options in docs.
;;      * Redirect `clear' alias to `aweshell-clear-buffer'.
;;      * Add completions for git command.
;;      * Adjust `ls' alias.
;;
;; 2018/08/13
;;      * First released.
;;

;;; Acknowledgements:
;;
;; Samray: copy `aweshell-clear-buffer', `aweshell-sudo-toggle' and `aweshell-search-history'
;; casouri: copy `aweshell-validate-command' and `aweshell-sync-dir-buffer-name'
;;

;;; Require

(require 'eshell)
(require 'cl-lib)
(require 'subr-x)
(require 'seq)

(require 'eshell-up)
(require 'eshell-prompt-extras)
(require 'esh-autosuggest)
(require 'eshell-did-you-mean)
(require 'fish-completion)


;;; Code:

;;;; Customize

(defgroup aweshell nil
  "Multi eshell manager."
  :group 'aweshell)

(defface aweshell-valid-command-face
  '((((background dark)) (:foreground "green"))
    (((background light)) (:foreground "DarkGreen")))
  "Face of a valid command in `aweshell-mode.'")

(defface aweshell-invalid-command-face
  '((t (:inherit 'error)))
  "Face of a valid command in `aweshell-mode.'")

(defface aweshell-alert-buffer-face
  '((t (:inherit 'error)))
  "Alert buffer face."
  :group 'aweshell)

(defface aweshell-alert-command-face
  '((t (:inherit 'warning)))
  "Alert command face."
  :group 'aweshell)

(defvar aweshell-eof-before-return t
  "If set to t, go to end of buffer before hitting return.")

(define-minor-mode aweshell-mode
  "Aweshell."
  :lighter ""
  :keymap (let ((map (make-sparse-keymap)))
            (define-key map (kbd "C-c C-l") #'aweshell-clear-buffer)
            (define-key map (kbd "C-M-l") #'aweshell-sudo-toggle)
            (define-key map (kbd "M-'") #'aweshell-search-history)
            (define-key map (kbd "C-c C-b") #'aweshell-switch-buffer)
            map)
  (if aweshell-mode
      (progn
        (esh-autosuggest-companyless-mode)
        (add-hook 'post-command-hook #'aweshell-validate-command t t)
        (aweshell-sync-dir-buffer-name)
        (add-hook 'eshell-directory-change-hook #'aweshell-sync-dir-buffer-name t t)
        (add-hook 'eshell-kill-hook #'eshell-command-alert t t)
        (when (featurep 'company)
          (company-mode)
          (setq-local company-auto-complete nil)
          (setq-local company-idle-delay 99999999))
        (esh-autosuggest-companyless-mode)
        (eshell-did-you-mean-setup)
        (fish-completion-mode)
        (advice-add #'eshell-send-input :before #'aweshell-eof-before-ret))))

;;;; Helpers

(defun aweshell-buffer-list ()
  "Return a list of eshell buffers."
  (cl-remove-if-not
   (lambda (buf)
     (eq (buffer-local-value 'major-mode buf)
         'eshell-mode))
   (buffer-list)))

;;;; Commands

(defun aweshell-switch-buffer (buffer)
  "Switch to an aweshell buffer BUFFER."
  (require 'cl-lib)
  (interactive
   (list (completing-read "Choose buffer: "
                          (mapcar (lambda (buf)
                                    (buffer-name buf))
                                  (aweshell-buffer-list)))))
  (switch-to-buffer buffer))

(defun aweshell-toggle (&optional arg)
  "Toggle Aweshell.

ARG: C-u: open the aweshell buffer with the same dir of current buffer
If there exists an Aweshell buffer with current directory, use that,
otherwise create one.

C-u C-u: same as C-u, but reuse a existing aweshell buffer instead of
creating one."
  (interactive "p")
  (if (equal major-mode 'eshell-mode)
      ;; toggle off
      (while (equal major-mode 'eshell-mode)
        (switch-to-prev-buffer))
    ;; toggle on
    (let ((buffer-list (aweshell-buffer-list)))
      (cond ((or (eq arg 4) ; C-u
                 (eq arg 16)) ; C-u C-u
             ;; open in current dir
             (let* ((dir default-directory)
                    (buffer-with-same-dir
                     (catch 'found
                       (dolist (buffer buffer-list)
                         (when (equal dir (buffer-local-value 'default-directory
                                                              buffer))
                           (throw 'found buffer))))))
               ;; found the buffer with the same dir
               ;; or create a new one
               (if buffer-with-same-dir
                   (switch-to-buffer buffer-with-same-dir)
                 (switch-to-buffer (if (eq arg 4)
                                       (progn (message "No valid aweshell buffer found, reuse one.")
                                              (car buffer-list))
                                     (message "No valid aweshell buffer found, create a new one.")
                                     (aweshell-new)))
                 (eshell/cd dir))))
            ;; simply open
            (t (switch-to-buffer (or (car buffer-list)
                                     (aweshell-new))))))))

(defun aweshell-new ()
  "Create new eshell buffer."
  (interactive)
  (save-excursion
    (eshell t)
    (aweshell-mode)
    (current-buffer)))

(defun aweshell-next ()
  "Select next eshell buffer.
Create new one if no eshell buffer exists."
  (interactive)
  (let ((bufname (buffer-name)))
    (next-buffer)
    (while (and (not (eq major-mode 'eshell-mode))
                (not (string= (buffer-name) bufname)))
      (next-buffer))))

(defun aweshell-prev ()
  "Select previous eshell buffer.
Create new one if no eshell buffer exists."
  (interactive)
  (let ((bufname (buffer-name)))
    (previous-buffer)
    (while (and (not (eq major-mode 'eshell-mode))
                (not (string= (buffer-name) bufname)))
      (previous-buffer))))

(defun aweshell-clear-buffer ()
  "Clear eshell buffer."
  (interactive)
  (let ((inhibit-read-only t))
    (erase-buffer)
    (eshell-send-input)))

(defun aweshell-sudo-toggle ()
  "Toggle sudo with current command."
  (interactive)
  (save-excursion
    (let ((commands (buffer-substring-no-properties
                     (eshell-bol) (point-max))))
      (if (string-match-p "^sudo " commands)
          (progn
            (eshell-bol)
            (while (re-search-forward "sudo " nil t)
              (replace-match "" t nil)))
        (progn
          (eshell-bol)
          (insert "sudo ")
          )))))

(defun aweshell-search-history ()
  "Interactive search eshell history."
  (interactive)
  (save-excursion
    (let* ((start-pos (eshell-beginning-of-input))
           (input (eshell-get-old-input))
           (all-shell-history (esh-parse-shell-history)))
      (let* ((command (ido-completing-read "Search history: " all-shell-history)))
        (eshell-kill-input)
        (insert command)
        )))
  ;; move cursor to eol
  (end-of-line))

;;;; Extensions

;;;;; eshell-up
;;
;; Quickly go to a specific parent directory in eshell
(defalias 'eshell/up 'eshell-up)
(defalias 'eshell/up-peek 'eshell-up-peek)

;;;;; Validate command

(defun aweshell-validate-command ()
  "Validate current command."
  ;; overlay is slow, so we use text property here
  (save-excursion
    (beginning-of-line)
    (re-search-forward (format "%s\\([^ \t\r\n\v\f]*\\)" eshell-prompt-regexp)
                       (line-end-position)
                       t)
    (let ((beg (match-beginning 1))
          (end (match-end 1))
          (command (match-string 1)))
      (when command
        (put-text-property
         beg end
         'face (if (or
                    ;; Command exists?
                    (executable-find command)
                    ;; Or command is an alias?
                    (seq-contains (eshell-alias-completions "") command)
                    ;; Or it is ../. ?
                    (or (equal command "..")
                        (equal command ".")
                        (equal command "exit"))
                    ;; Or it is a file in current dir?
                    (member (file-name-base command) (directory-files default-directory))
                    ;; Or it is a elisp function
                    (functionp (intern command)))
                   'aweshell-valid-command-face
                 'aweshell-invalid-command-face))
        (put-text-property beg end 'rear-nonsticky t)))))

;;;;; Emacs

(defun aweshell-emacs (&rest args)
  "Open a file in Emacs with ARGS, Some habits die hard."
  (if (null args)
      ;; If I just ran "emacs", I probably expect to be launching
      ;; Emacs, which is rather silly since I'm already in Emacs.
      ;; So just pretend to do what I ask.
      (bury-buffer)
    ;; We have to expand the file names or else naming a directory in an
    ;; argument causes later arguments to be looked for in that directory,
    ;; not the starting directory
    (mapc #'find-file (mapcar #'expand-file-name (eshell-flatten-list (reverse args))))))

(defalias 'eshell/e 'aweshell-emacs)

;;;;; Unpack

(defun aweshell-unpack (file &rest args)
  "Unpack FILE with ARGS."
  (let ((command (some (lambda (x)
                         (if (string-match-p (car x) file)
                             (cadr x)))
                       '((".*\.tar.bz2" "tar xjf")
                         (".*\.tar.gz" "tar xzf")
                         (".*\.bz2" "bunzip2")
                         (".*\.rar" "unrar x")
                         (".*\.gz" "gunzip")
                         (".*\.tar" "tar xf")
                         (".*\.tbz2" "tar xjf")
                         (".*\.tgz" "tar xzf")
                         (".*\.zip" "unzip")
                         (".*\.Z" "uncompress")
                         (".*" "echo 'Could not unpack the file:'")))))
    (let ((unpack-command(concat command " " file " " (mapconcat 'identity args " "))))
      (eshell/printnl "Unpack command: " unpack-command)
      (eshell-command-result unpack-command))
    ))

(defalias 'eshell/unpack 'aweshell-unpack)

;;;;; Sync buffer name with current directory

(defun aweshell-sync-dir-buffer-name ()
  "Change aweshell buffer name by directory change."
  (rename-buffer (format "eshell @ %s" (epe-fish-path default-directory))
                 t))

;;;;; Completions for git command

(when (executable-find "git")
  (defun pcmpl-git-commands ()
    "Return the most common git commands by parsing the git output."
    (with-temp-buffer
      (call-process-shell-command "git" nil (current-buffer) nil "help" "--all")
      (goto-char 0)
      (search-forward "\n\n")
      (let (commands)
        (while (re-search-forward
                "^[[:blank:]]+\\([[:word:]-.]+\\)[[:blank:]]*\\([[:word:]-.]+\\)?"
                nil t)
          (push (match-string 1) commands)
          (when (match-string 2)
            (push (match-string 2) commands)))
        (sort commands #'string<))))

  (defconst pcmpl-git-commands (pcmpl-git-commands)
    "List of `git' commands.")

  (defvar pcmpl-git-ref-list-cmd "git for-each-ref refs/ --format='%(refname)'"
    "The `git' command to run to get a list of refs.")

  (defun pcmpl-git-get-refs (type)
    "Return a list of `git' refs filtered by TYPE."
    (with-temp-buffer
      (insert (shell-command-to-string pcmpl-git-ref-list-cmd))
      (goto-char (point-min))
      (let (refs)
        (while (re-search-forward (concat "^refs/" type "/\\(.+\\)$") nil t)
          (push (match-string 1) refs))
        (nreverse refs))))

  (defun pcmpl-git-remotes ()
    "Return a list of remote repositories."
    (split-string (shell-command-to-string "git remote")))

  (defun pcomplete/git ()
    "Completion for `git'."
    ;; Completion for the command argument.
    (pcomplete-here* pcmpl-git-commands)
    (cond
     ((pcomplete-match "help" 1)
      (pcomplete-here* pcmpl-git-commands))
     ((pcomplete-match (regexp-opt '("pull" "push")) 1)
      (pcomplete-here (pcmpl-git-remotes)))
     ;; provide branch completion for the command `checkout'.
     ((pcomplete-match "checkout" 1)
      (pcomplete-here* (append (pcmpl-git-get-refs "heads")
                               (pcmpl-git-get-refs "tags"))))
     (t
      (while (pcomplete-here (pcomplete-entries)))))))


;;;;; Add syntax highlight to cat

(defun aweshell-cat-with-syntax-highlight (filename)
  "Like cat(1) but with syntax highlighting."
  (let ((existing-buffer (get-file-buffer filename))
        (buffer (find-file-noselect filename)))
    (eshell-print
     (with-current-buffer buffer
       (if (fboundp 'font-lock-ensure)
           (font-lock-ensure)
         (with-no-warnings
           (font-lock-fontify-buffer)))
       (buffer-string)))
    (unless existing-buffer
      (kill-buffer buffer))
    nil))

(advice-add 'eshell/cat :override #'aweshell-cat-with-syntax-highlight)

;;;;; Alert user when background process finished or aborted

(defun eshell-command-alert (process status)
  "Send `alert' with severity based on STATUS when PROCESS finished."
  (let* ((cmd (process-command process))
         (buffer (process-buffer process))
         (msg (replace-regexp-in-string "\n" " " (string-trim (format "%s: %s" (mapconcat 'identity cmd " ")  status))))
         (buffer-visible (member buffer (mapcar #'window-buffer (window-list)))))
    (unless buffer-visible
      (message "%s %s"
               (propertize (format "[Aweshell Alert] %s" (string-remove-prefix "Aweshell: " (buffer-name buffer))) 'face 'aweshell-alert-buffer-face)
               (propertize msg 'face 'aweshell-alert-command-face)))))

;;;;; (Maybe) goto eof before return

(defun aweshell-eof-before-ret (&rest _)
  "Goto eof before ret."
  (when aweshell-eof-before-return
    (goto-char (point-max))))

(provide 'aweshell)

;;; aweshell.el ends here
