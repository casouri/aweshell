Note from casouri: This fork (master branch) is not going to follow Andy's master branch anymore. For the latest version please visit his page.

# What is aweshell?

Andy created `multi-term.el` and used it for many years.

Now he is a big fans of `eshell`.

So he wrote `aweshell.el` to extend `eshell` with these features:

1. Create and manage multiple eshell buffers.
2. Add some useful commands, such as: clear buffer, toggle sudo etc.
3. Display extra information and color like zsh, powered by `eshell-prompt-extras'
4. Add Fish-like history autosuggestions, powered by `esh-autosuggest', support histories from bash/zsh/eshell.
5. Validate and highlight command before post to eshell.
6. Change buffer name by directory change.
7. Add completions for git command.
8. Fix error `command not found' in MacOS.
9. Integrate `eshell-up'.
10. Unpack archive file.
11. Open file with alias e.
12. Output "did you mean ..." helper when you typo.
13. Make cat file with syntax highlight.
14. Alert user when background process finished or aborted.
15. IDE-like completion for shell commands.
16. Borrow fish completions
17. Robust prompt

# Installation

Put all elisp files to your load-path.
The load-path is usually `~/elisp/`.
It's set in your `~/.emacs` like this:
```emacs-lisp
(add-to-list 'load-path (expand-file-name "~/elisp"))
(require 'aweshell)
```

Bind your favorite key to functions:

# Usage

| Commands                | Description                                                   |
|-------------------------|---------------------------------------------------------------|
| `aweshell-new`          | create a new eshell buffer                                    |
| `aweshell-next`         | switch to next aweshell buffer                                |
| `aweshell-prev`         | switch to previous aweshell buffer                            |
| `aweshell-clear-buffer` | clear eshell buffer                                           |
| `aweshell-sudo-toggle`  | toggle sudo                                                   |
| `aweshell-toggle`       | switch back and forth between eshell buffer and normal buffer |


# Customize

## Variables

Customize variables by
```emacs-lisp
M-x customize-group RET aweshell RET
```
| Variables                    | Description                               |
|------------------------------|-------------------------------------------|
| `aweshell-eof-before-return` | go to end of buffer before sending return |

## Customize shell prompt

Aweshell uses eshell-prompt-extra to prettify shell prompt.
Consult [eshell-prompt-extra's README](https://github.com/kaihaosw/eshell-prompt-extras#themes) on how to customize shell prompt.

## Customize eshell-up

```emacs-lisp
(setq eshell-up-ignore-case nil)
(setq eshell-up-print-parent-dir t)
```

Checkout [homepage of eshell-up](https://github.com/peterwvj/eshell-up) for more information.


## Aliases

Suggested alias for [eshell-up](https://github.com/peterwvj/eshell-up) and other eshell commands:

Put in alias file:
```
alias up eshell-up $1
alias pk eshell-up-peek $1
alias ff find-file $1
alias ll ls -al
alias dd dired $1
alias fo find-file-other-window $1
alias gs magit-status
```
