;;; -*- lexical-binding: t -*-
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(column-number-mode t)
 '(cua-mode t)
 '(custom-enabled-themes '(modus-vivendi-tinted))
 '(custom-safe-themes
   '("47642859840064c0e0b31748c12667af79627e95bd78990128c4e6d061164a97"
     "a12f585b1ff1b35f4000eab71f9f20a784b94f797296de13d467f9b3021b9a8b"
     "6ac2faf17d4d37b6f4bc08203b70e82f4b3b5ce76f102fb4802b3f6c74460743"
     "2902694c7ef5d2a757146f0a7ce67976c8d896ea0a61bd21d3259378add434c4"
     "13e625c72dbb6e887fbebd72687228939c8025d73a78962790a66d0a83f2bc3a"
     "e1da45d87a83acb558e69b90015f0821679716be79ecb76d635aafdca8f6ebd4"
     default))
 ;; '(global-display-line-numbers-mode t)
 '(package-selected-packages '(base16-theme leuven-theme vterm xah-fly-keys))
 '(warning-suppress-log-types '((initialization))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
(setq package-archives '(("melpa-stable" . "https://stable.melpa.org/packages/")))
(setq custom-safe-themes t)

;;
(hs-minor-mode 1)

;; Completion for M-x
(ido-mode 1)
(ido-everywhere 1)

;; Line Number
(column-number-mode 1)
(global-display-line-numbers-mode 1)

;; xah-fly-keys
(require 'xah-fly-keys)
(xah-fly-keys-set-layout "colemak")
(xah-fly-keys 1)
