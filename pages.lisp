;;; file: pages.lisp
;;;
;;; Copyright (c) 2007 Cyrus Harmon (ch-lisp@bobobeach.com)
;;; All rights reserved.
;;;
;;; Redistribution and use in source and binary forms, with or without
;;; modification, are permitted provided that the following conditions
;;; are met:
;;;
;;;   * Redistributions of source code must retain the above copyright
;;;     notice, this list of conditions and the following disclaimer.
;;;
;;;   * Redistributions in binary form must reproduce the above
;;;     copyright notice, this list of conditions and the following
;;;     disclaimer in the documentation and/or other materials
;;;     provided with the distribution.
;;;
;;; THIS SOFTWARE IS PROVIDED BY THE AUTHOR 'AS IS' AND ANY EXPRESSED
;;; OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
;;; WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
;;; ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
;;; DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
;;; DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
;;; GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
;;; INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
;;; WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
;;; NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
;;; SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
;;;

(in-package :nuclblog)

(defun entry-link (blog entry)
  (concatenate-url
   (blog-display-entry-url blog)
   "?id="
   (url-encode (prin1-to-string (blog-entry-number entry)))))

(defun archives-url (blog &key category rss)
  (if category
      (concatenate 'string
                   (if rss
                       (blog-rss-url blog)
                       (blog-archives-url))
                   (if rss "?" "/")
                   category)
      (if rss (blog-rss-url blog) (blog-archives-url blog))))

(defmacro box ((&key class id) head &rest body)
  `(with-html-output (*standard-output*)
     (:div :id ,id :class ,(concatenate 'string "box " class)
           ,(when head
                  `(:div :class "box-head"
                         ,head))
           (:div :class "box-body"
                 ,@body))))

(defun recent-entries (blog)
  (with-html
    (box (:class "nav-box" :id "nav-box-recent-entries")
         (:h2 "Recent entries")
         (:ul :class "recent-entries"
              (loop for i from 1 to 10
                 for j in (blog-entries blog)
                 do (htm
                     (:li
                      (:a :href (entry-link blog j)
                          (str (blog-entry-title j))))))))))

(defun categories (blog)
  (with-html
    (box (:class "nav-box" :id "nav-box-categories")
         (:h2 "Categories")
         (:ul
          (loop for i in (blog-categories blog)
             do (htm
                 (:li (:a :href (make-archives-url blog i)
                          (str i))
                      " "
                      (:a :href (make-archives-url blog i :rss t)
                          "(RSS)"))))))))

(defun buttons (blog)
  (with-html
    (box (:class "nav-box nav-button" :id "nav-box-buttons")
         nil
         (:ul :class "buttons"
              (loop for button in (blog-buttons blog)
                 do
                 (destructuring-bind (&key href-url id img-url alt) button
                   (htm
                    (:li
                     (:a :href href-url :class "button"
                         (:img :id id
                               :src img-url
                               :alt (escape-string alt)))))))))))

(defun main-nav (blog)
  (box (:class "nav-box" :id "nav-box-1")
               (:h2 (str (blog-short-name blog)))
               (:ul
                (:li (:a :href (blog-url-root blog) "Blog"))
                (:li (:a :href (blog-new-entry-url blog) "New entry"))
                (:li (:a :href (blog-archives-url blog) "Archives"))
                (:li (:a :href (archives-url blog :rss t) "Syndicate (RSS)"))
                (:li (:a :href (blog-email-redirect-url blog) "Send Comments"))
                (if (hunchentoot-auth:session-realm-user-authenticated-p (blog-realm blog))
                    (htm (:li (:a :href (blog-logout-url blog) "Logout")))
                    (htm (:li (:a :href (blog-login-url blog) "Login")))))))

(defgeneric nav-boxes (blog))

(defmethod nav-boxes ((blog blog))
  (main-nav blog)
  (recent-entries blog)
  (categories blog))

(defun nav (blog)
  (with-html-output (*standard-output*)
    (:div :id "nav" :class "nav"
          (nav-boxes blog)
          (buttons blog))))

(defun banner (blog)
  (with-html-output (*standard-output*)
    (:div :id "banner"                  
          (let ((url (blog-logo-img-url blog)))
            (when url
              (htm (:div :id "bannerleft"
                        (:img :class "titlelogo" :src url :alt ""))
                   "&nbsp;")))
          (:div :id "bannertext"
                (:h1 (str (blog-title blog)))
                (:h2 (str (blog-subtitle blog))))
          (:div :class "pad" "&nbsp;"))))

(defun blog-page (blog title body-function)
  (with-html-page
    (:html
     (:head (:title (str title))
            (loop for style in (blog-page-css blog)
               for primary = t then nil
               do
               (htm
                (:link :rel (if primary "stylesheet" "alternate stylesheet")
                       :title (car style) :type "text/css" :href (cdr style)))))
     (:body
      (banner blog)
      (:div :id "main"
            (nav blog)
            (:div :id "content"
                  (funcall body-function)))))))