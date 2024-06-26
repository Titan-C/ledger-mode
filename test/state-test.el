;;; state-test.el --- ERT for ledger-mode  -*- lexical-binding: t; -*-

;; Copyright (C) 2003-2017 John Wiegley <johnw AT gnu DOT org>

;; Author: Thierry <thdox AT free DOT fr>
;; Keywords: languages
;; Homepage: https://github.com/ledger/ledger-mode

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify it under
;; the terms of the GNU General Public License as published by the Free Software
;; Foundation; either version 2 of the License, or (at your option) any later
;; version.
;;
;; This program is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
;; FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
;; details.
;;
;; You should have received a copy of the GNU General Public License along with
;; this program; if not, write to the Free Software Foundation, Inc., 51
;; Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

;;; Commentary:
;;  Regression tests for ledger-state

;;; Code:
(require 'test-helper)


(ert-deftest ledger-state/test-001 ()
  "Regress test for Bug 1030
http://bugs.ledger-cli.org/show_bug.cgi?id=1030"
  :tags '(state regress)

  (ledger-tests-with-temp-file
"2013/06/09 * 4 Saisons
    Dépense:Alimentation:Restaurant          23,00 €
    Passif:Crédit:BanqueAccord
"
    (forward-line 1)
    (ledger-toggle-current)             ; C-c C-c
    (should
     (equal (buffer-string)
      "2013/06/09 4 Saisons
    Dépense:Alimentation:Restaurant          23,00 €
    * Passif:Crédit:BanqueAccord
" ))
    (ledger-toggle-current)             ; C-c C-c
    (should
     (equal (buffer-string)
      "2013/06/09 * 4 Saisons
    Dépense:Alimentation:Restaurant          23,00 €
    Passif:Crédit:BanqueAccord
" ))))


(ert-deftest ledger-state/test-002 ()
  "General tests for various behaviors of `ledger-toggle-current'."
  :tags '(state)

  (ledger-tests-with-temp-file
      "\
2024-01-01 * Grocery
    Expenses:Groceries    50.00 USD
    Expenses:Household    20.00 USD
    Liabilities:Credit Card
"
    ;; toggling posting while xact is cleared causes other postings to be
    ;; individually cleared
    (forward-line)
    (ledger-toggle-current)
    (should (equal (buffer-string)
                   "\
2024-01-01 Grocery
    Expenses:Groceries    50.00 USD
    * Expenses:Household  20.00 USD
    * Liabilities:Credit Card
"))

    ;; when state char is removed, amounts remain in the original column
    (forward-line)
    (ledger-toggle-current)
    (forward-line)
    (ledger-toggle-current)
    (should (equal (buffer-string)
                   "\
2024-01-01 Grocery
    Expenses:Groceries    50.00 USD
    Expenses:Household    20.00 USD
    Liabilities:Credit Card
"))

    ;; when state char is inserted, amounts remain in the original column
    (forward-line -1)
    (ledger-toggle-current)
    (forward-line -1)
    (ledger-toggle-current)
    (should (equal (buffer-string)
                   "\
2024-01-01 Grocery
    * Expenses:Groceries  50.00 USD
    * Expenses:Household  20.00 USD
    Liabilities:Credit Card
"))

    ;; toggling on xact causes the post state chars to be cleared
    (forward-line -1)
    (ledger-toggle-current)
    (should (equal (buffer-string)
                   "\
2024-01-01 * Grocery
    Expenses:Groceries    50.00 USD
    Expenses:Household    20.00 USD
    Liabilities:Credit Card
"))))


(ert-deftest ledger-state/test-003 ()
  "Regression test for #274
https://github.com/ledger/ledger-mode/issues/274"
  :tags '(state regress)

  ;; deliberately no newline at the end of the file
  (ledger-tests-with-temp-file
   "2011/01/19 Grocery Store
  Expenses:Food:Groceries             $ 44.00 ; hastag: not block
  Assets:Checking"
   (goto-char (point-min))
   (ledger-toggle-current)
   (should
    (equal (buffer-string)
           "2011/01/19 * Grocery Store
  Expenses:Food:Groceries             $ 44.00 ; hastag: not block
  Assets:Checking"))))

(provide 'state-test)

;;; state-test.el ends here
