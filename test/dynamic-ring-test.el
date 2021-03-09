;; Note: we want to retain dynamic binding for these tests because the
;; ERT "fixtures" rely on it.

;; Add source paths to load path so the tests can find the source files
;; Adapted from:
;; https://github.com/Lindydancer/cmake-font-lock/blob/47687b6ccd0e244691fb5907aaba609e5a42d787/test/cmake-font-lock-test-setup.el#L20-L27
(defvar dynamic-ring-test-setup-directory
  (if load-file-name
      (file-name-directory load-file-name)
    default-directory))

(dolist (dir '("." ".."))
  (add-to-list 'load-path
               (concat dynamic-ring-test-setup-directory dir)))

;;

(require 'dynamic-ring)
(require 'cl-lib)

;;
;; Fixtures
;;

;; fixture recipe from:
;; https://www.gnu.org/software/emacs/manual/html_node/ert/Fixtures-and-Test-Suites.html
(defun fixture-0-ring (body)
  (let ((ring nil))
    (unwind-protect
        (progn (setq ring (make-dyn-ring))
               (funcall body))
      (dyn-ring-destroy ring))))

(defun fixture-1-ring (body)
  (let ((ring nil))
    (unwind-protect
        (progn
          (setq ring (make-dyn-ring))
          (let ((segment (dyn-ring-insert ring 1)))
            (funcall body)))
      (dyn-ring-destroy ring))))

(defun fixture-2-ring (body)
  ;; [2] - 1 - [2]
  (let ((ring nil))
    (unwind-protect
        (progn
          (setq ring (make-dyn-ring))
          (let ((seg1 (dyn-ring-insert ring 1))
                (seg2 (dyn-ring-insert ring 2)))
            (funcall body)))
      (dyn-ring-destroy ring))))

(defun fixture-3-ring (body)
  ;; [3] - 2 - 1 - [3]
  (let ((ring nil))
    (unwind-protect
        (progn
          (setq ring (make-dyn-ring))
          (let ((seg1 (dyn-ring-insert ring 1))
                (seg2 (dyn-ring-insert ring 2))
                (seg3 (dyn-ring-insert ring 3)))
            (funcall body)))
      (dyn-ring-destroy ring))))

;;
;; Test utilities
;;

(defun segments-are-linked-p (previous next)
  (and (eq (dyn-ring-segment-next previous) next)
       (eq (dyn-ring-segment-previous next) previous)))

(defun segment-is-free-p (segment)
  (and (null (dyn-ring-segment-next segment))
       (null (dyn-ring-segment-previous segment))))

;;
;; Tests
;;

(ert-deftest dyn-ring-test ()
  ;; null constructor
  (should (make-dyn-ring))

  ;; dyn-ring-empty-p
  (should (dyn-ring-empty-p (make-dyn-ring)))
  (let ((ring (make-dyn-ring)))
    (dyn-ring-insert ring 1)
    (should-not (dyn-ring-empty-p ring)))

  ;; dyn-ring-size
  (should (= 0 (dyn-ring-size (make-dyn-ring))))
  (let ((ring (make-dyn-ring)))
    (dyn-ring-insert ring 1)
    (should (= 1 (dyn-ring-size ring))))

  ;; dyn-ring-head
  (should (null (dyn-ring-head (make-dyn-ring))))
  (let* ((ring (make-dyn-ring))
         (segment (dyn-ring-insert ring 1)))
    (should (equal segment (dyn-ring-head ring))))

  ;; dyn-ring-value
  (should (null (dyn-ring-value (make-dyn-ring))))
  (let ((ring (make-dyn-ring)))
    (dyn-ring-insert ring 1)
    (should (= 1 (dyn-ring-value ring)))))

(ert-deftest dyn-ring-segment-test ()
  ;; constructor
  (should (dyn-ring-make-segment 1))

  ;; dyn-ring-segment-value
  (should (= 1
             (dyn-ring-segment-value
              (dyn-ring-make-segment 1))))

  ;; dyn-ring-segment-set-value
  (let ((segment (dyn-ring-make-segment 1)))
    (dyn-ring-segment-set-value segment 2)
    (should (= 2
               (dyn-ring-segment-value segment))))

  ;; dyn-ring-segment-previous and dyn-ring-segment-next
  (let* ((ring (make-dyn-ring))
         (head (dyn-ring-insert ring 1)))
    (should (eq head (dyn-ring-segment-previous head)))
    (should (eq head (dyn-ring-segment-next head))))
  (let* ((ring (make-dyn-ring))
         (seg1 (dyn-ring-insert ring 1))
         (seg2 (dyn-ring-insert ring 2)))
    (should (eq seg2 (dyn-ring-segment-previous seg1)))
    (should (eq seg2 (dyn-ring-segment-next seg1)))
    (should (eq seg1 (dyn-ring-segment-previous seg2)))
    (should (eq seg1 (dyn-ring-segment-next seg2)))))

(ert-deftest dyn-ring-equal-p-test ()
  ;; empty ring
  (fixture-0-ring
   (lambda ()
     (let* ((r2 (make-dyn-ring))
            (r3 (make-dyn-ring)))
       (dyn-ring-insert r3 1)
       (should (dyn-ring-equal-p ring r2))
       (should-not (dyn-ring-equal-p ring r3)))))

  ;; 1-element ring
  (fixture-1-ring
   (lambda ()
     (let* ((r2 (make-dyn-ring))
            (r3 (make-dyn-ring)))
       (dyn-ring-insert r2 1)
       (dyn-ring-insert r3 1)
       (dyn-ring-insert r3 1)
       (should (dyn-ring-equal-p ring r2))
       (should-not (dyn-ring-equal-p ring r3)))))

  ;; 2-element ring
  (fixture-2-ring
   (lambda ()
     (let* ((r2 (make-dyn-ring))
            (r3 (make-dyn-ring)))
       (dyn-ring-insert r2 1)
       (dyn-ring-insert r2 2)
       (dyn-ring-insert r3 1)
       (dyn-ring-insert r3 1)
       (should (dyn-ring-equal-p ring r2))
       (should-not (dyn-ring-equal-p ring r3)))))

  ;; 3-element ring
  (fixture-3-ring
   (lambda ()
     (let* ((r2 (make-dyn-ring))
            (r3 (make-dyn-ring)))
       (dyn-ring-insert r2 1)
       (dyn-ring-insert r2 2)
       (dyn-ring-insert r2 3)
       (dyn-ring-insert r3 1)
       (dyn-ring-insert r3 3)
       (dyn-ring-insert r3 2)
       (should (dyn-ring-equal-p ring r2))
       (should-not (dyn-ring-equal-p ring r3))))))

(ert-deftest dyn-ring-traverse-test ()
  ;; empty ring
  (fixture-0-ring
   (lambda ()
     (let ((memo (list)))
       (cl-letf ((memofn (lambda (arg)
                           (push arg memo))))
         (should-not (dyn-ring-traverse ring memofn))
         (should (null memo))))))

  ;; one-element ring
  (fixture-1-ring
   (lambda ()
     (let ((memo (list)))
       (cl-letf ((memofn (lambda (arg)
                           (push arg memo))))
         (should (dyn-ring-traverse ring memofn))
         (should (equal memo (list 1)))))))

  ;; two-element ring
  (fixture-2-ring
   (lambda ()
     (let ((memo (list)))
       (cl-letf ((memofn (lambda (arg)
                           (push arg memo))))
         (should (dyn-ring-traverse ring memofn))
         (should (equal memo (list 1 2)))))))

  ;; 3-element ring
  (fixture-3-ring
   (lambda ()
     (let ((memo (list)))
       (cl-letf ((memofn (lambda (arg)
                           (push arg memo))))
         (should (dyn-ring-traverse ring memofn))
         (should (equal memo (list 1 2 3))))))))

(ert-deftest dyn-ring-traverse-collect-test ()
  ;; empty ring
  (fixture-0-ring
   (lambda ()
     (let ((result (dyn-ring-traverse-collect ring #'1+)))
       (should (null result)))))

  ;; one-element ring
  (fixture-1-ring
   (lambda ()
     (let ((result (dyn-ring-traverse-collect ring #'1+)))
       (should (equal result (list 2))))))

  ;; two-element ring
  (fixture-2-ring
   (lambda ()
     (let ((result (dyn-ring-traverse-collect ring #'1+)))
       (should (equal result (list 2 3))))))

  ;; 3-element ring
  (fixture-3-ring
   (lambda ()
     (let ((result (dyn-ring-traverse-collect ring #'1+)))
       (should (equal result (list 2 3 4)))))))

(ert-deftest dyn-ring-insert-test ()
  ;; empty ring
  (fixture-0-ring
   (lambda ()
     (should (dyn-ring-insert ring 1))
     (should (= 1 (dyn-ring-value ring)))
     (let ((head (dyn-ring-head ring)))
       (should (segments-are-linked-p head head)))))

  ;; one-element ring
  (fixture-1-ring
   (lambda ()
     (let ((new (dyn-ring-insert ring 2)))
       (should new)
       (should (= 2 (dyn-ring-value ring)))
       (should (segments-are-linked-p segment new))
       (should (segments-are-linked-p new segment)))))

  ;; two-element ring
  (fixture-2-ring
   (lambda ()
     (let ((new (dyn-ring-insert ring 3)))
       (should new)
       (should (= 3 (dyn-ring-value ring)))
       (should (segments-are-linked-p seg1 new))
       (should (segments-are-linked-p new seg2))
       (should (segments-are-linked-p seg2 seg1))))))

(ert-deftest dyn-ring-break-insert-test ()
  ;; empty ring
  (fixture-0-ring
   (lambda ()
     (should (dyn-ring-break-insert ring 1))
     (should (= 1 (dyn-ring-value ring)))
     (let ((head (dyn-ring-head ring)))
       (should (segments-are-linked-p head head)))))

  ;; one-element ring
  (fixture-1-ring
   (lambda ()
     (let ((new (dyn-ring-break-insert ring 2)))
       (should new)
       (should (= 2 (dyn-ring-value ring)))
       (should (segments-are-linked-p segment new))
       (should (segments-are-linked-p new segment)))))
  (fixture-1-ring
   (lambda ()
     (let ((new (dyn-ring-break-insert ring 1)))
       (should new)
       (should (= 1 (dyn-ring-value ring)))
       (should (= 1 (dyn-ring-size ring))))))

  ;; two-element ring
  (fixture-2-ring
   (lambda ()
     (let ((new (dyn-ring-break-insert ring 3)))
       (should new)
       (should (= 3 (dyn-ring-value ring)))
       (should (segments-are-linked-p seg1 new))
       (should (segments-are-linked-p new seg2))
       (should (segments-are-linked-p seg2 seg1)))))
  (fixture-2-ring
   (lambda ()
     (let ((new (dyn-ring-break-insert ring 2)))
       (should new)
       (should (= 2 (dyn-ring-value ring)))
       (should (segments-are-linked-p seg1 new))
       (should (segments-are-linked-p new seg1)))))
  (fixture-2-ring
   (lambda ()
     (let ((new (dyn-ring-break-insert ring 1)))
       (should new)
       (should (= 1 (dyn-ring-value ring)))
       (should (segments-are-linked-p seg2 new))
       (should (segments-are-linked-p new seg2)))))

  ;; 3-element ring
  (fixture-3-ring
   (lambda ()
     (let ((new (dyn-ring-break-insert ring 3)))
       (should new)
       (should (= 3 (dyn-ring-value ring)))
       (should (segments-are-linked-p seg1 new))
       (should (segments-are-linked-p new seg2)))))
  (fixture-3-ring
   (lambda ()
     (let ((new (dyn-ring-break-insert ring 2)))
       (should new)
       (should (= 2 (dyn-ring-value ring)))
       (should (segments-are-linked-p seg1 new))
       (should (segments-are-linked-p new seg3)))))
  (fixture-3-ring
   (lambda ()
     (let ((new (dyn-ring-break-insert ring 1)))
       (should new)
       (should (= 1 (dyn-ring-value ring)))
       (should (segments-are-linked-p seg2 new))
       (should (segments-are-linked-p new seg3))))))

(ert-deftest dyn-ring-rotate-test ()
  ;; empty ring
  (fixture-0-ring
   (lambda ()
     (should (null (dyn-ring-rotate-left ring)))
     (should (null (dyn-ring-rotate-right ring)))))

  ;; 1-element ring
  (fixture-1-ring
   (lambda ()
     (should (eq segment (dyn-ring-rotate-left ring)))
     (should (eq segment (dyn-ring-rotate-right ring)))))

  ;; 2-element ring
  (fixture-2-ring
   (lambda ()
     (should (eq seg1 (dyn-ring-rotate-left ring)))
     (should (eq seg2 (dyn-ring-rotate-left ring)))
     (should (eq seg1 (dyn-ring-rotate-right ring)))
     (should (eq seg2 (dyn-ring-rotate-right ring)))))

  ;; 3-element ring
  (fixture-3-ring
   (lambda ()
     (should (eq seg1 (dyn-ring-rotate-left ring)))
     (should (eq seg2 (dyn-ring-rotate-left ring)))
     (should (eq seg3 (dyn-ring-rotate-left ring)))
     (should (eq seg2 (dyn-ring-rotate-right ring)))
     (should (eq seg1 (dyn-ring-rotate-right ring)))
     (should (eq seg3 (dyn-ring-rotate-right ring))))))

(ert-deftest dyn-ring-delete-segment-test ()
  ;; empty ring
  (let ((ring (make-dyn-ring))
        (segment (dyn-ring-make-segment 1)))
    (should (null (dyn-ring-delete-segment ring segment)))
    (should (dyn-ring-empty-p ring)))

  ;; 1-element ring
  (fixture-1-ring
   (lambda ()
     (should (dyn-ring-delete-segment ring segment))
     (should (dyn-ring-empty-p ring))))

  ;; 2-element ring
  (fixture-2-ring
   (lambda ()
     ;; delete head
     (should (dyn-ring-delete-segment ring seg2))
     (should (= 1 (dyn-ring-size ring)))
     (should (eq seg1 (dyn-ring-head ring)))
     (should (segments-are-linked-p seg1 seg1))))
  (fixture-2-ring
   (lambda ()
     ;; delete non-head
     (should (dyn-ring-delete-segment ring seg1))
     (should (= 1 (dyn-ring-size ring)))
     (should (eq seg2 (dyn-ring-head ring)))
     (should (segments-are-linked-p seg2 seg2))))

  ;; 3-element ring
  (fixture-3-ring
   (lambda ()
     ;; delete head
     (should (dyn-ring-delete-segment ring seg3))
     (should (= 2 (dyn-ring-size ring)))
     (should (eq seg2 (dyn-ring-head ring)))
     (should (segments-are-linked-p seg2 seg1))
     (should (segments-are-linked-p seg1 seg2))))
  (fixture-3-ring
   (lambda ()
     ;; delete right
     (should (dyn-ring-delete-segment ring seg2))
     (should (= 2 (dyn-ring-size ring)))
     (should (eq seg3 (dyn-ring-head ring)))
     (should (segments-are-linked-p seg3 seg1))
     (should (segments-are-linked-p seg1 seg3))))
  (fixture-3-ring
   (lambda ()
     ;; delete left
     (should (dyn-ring-delete-segment ring seg1))
     (should (= 2 (dyn-ring-size ring)))
     (should (eq seg3 (dyn-ring-head ring)))
     (should (segments-are-linked-p seg3 seg2))
     (should (segments-are-linked-p seg2 seg3)))))

(ert-deftest dyn-ring-delete-test ()
  ;; empty ring
  (let ((ring (make-dyn-ring)))
    (should-not (dyn-ring-delete ring 1))
    (should (dyn-ring-empty-p ring)))

  ;; 1-element ring
  (fixture-1-ring
   (lambda ()
     (should (dyn-ring-delete ring 1))
     (should (dyn-ring-empty-p ring))))
  (fixture-1-ring
   (lambda ()
     ;; non-element
     (should-not (dyn-ring-delete ring 2))
     (should (= 1 (dyn-ring-size ring)))))

  ;; 2-element ring
  (fixture-2-ring
   (lambda ()
     ;; delete head
     (should (dyn-ring-delete ring 2))
     (should (= 1 (dyn-ring-size ring)))))
  (fixture-2-ring
   (lambda ()
     ;; delete non-head
     (should (dyn-ring-delete ring 1))
     (should (= 1 (dyn-ring-size ring)))))
  (fixture-2-ring
   (lambda ()
     ;; non-element
     (should-not (dyn-ring-delete ring 3))
     (should (= 2 (dyn-ring-size ring)))))

  ;; 3-element ring
  (fixture-3-ring
   (lambda ()
     ;; delete head
     (should (dyn-ring-delete ring 3))
     (should (= 2 (dyn-ring-size ring)))))
  (fixture-3-ring
   (lambda ()
     ;; delete right
     (should (dyn-ring-delete ring 2))
     (should (= 2 (dyn-ring-size ring)))))
  (fixture-3-ring
   (lambda ()
     ;; delete left
     (should (dyn-ring-delete ring 1))
     (should (= 2 (dyn-ring-size ring)))))
  (fixture-3-ring
   (lambda ()
     ;; non-element
     (should-not (dyn-ring-delete ring 4))
     (should (= 3 (dyn-ring-size ring))))))

(ert-deftest dyn-ring-destroy-test ()
  ;; empty ring
  (fixture-0-ring
   (lambda ()
     (should-not (dyn-ring-destroy ring))))

  ;; 1-element ring
  (fixture-1-ring
   (lambda ()
     (should (dyn-ring-destroy ring))
     (should (null (dyn-ring-head ring)))
     (should (= 0 (dyn-ring-size ring)))
     (should (segment-is-free-p segment))))

  ;; 2-element ring
  (fixture-2-ring
   (lambda ()
     (should (dyn-ring-destroy ring))
     (should (null (dyn-ring-head ring)))
     (should (= 0 (dyn-ring-size ring)))
     (should (segment-is-free-p seg1))
     (should (segment-is-free-p seg2))))

  ;; 3-element ring
  (fixture-3-ring
   (lambda ()
     (should (dyn-ring-destroy ring))
     (should (null (dyn-ring-head ring)))
     (should (= 0 (dyn-ring-size ring)))
     (should (segment-is-free-p seg1))
     (should (segment-is-free-p seg2))
     (should (segment-is-free-p seg3)))))

(ert-deftest dyn-ring-rotate-until-test ()
  ;; empty ring
  (fixture-0-ring
   (lambda ()
     (should-not (dyn-ring-rotate-until ring
                                        #'dyn-ring-rotate-left
                                        (lambda (element)
                                          t)))))

  ;; 1-element ring
  (fixture-1-ring
   (lambda ()
     (should (dyn-ring-rotate-until ring
                                    #'dyn-ring-rotate-left
                                    (lambda (element)
                                      t)))
     (should (eq segment (dyn-ring-head ring)))))
  (fixture-1-ring
   (lambda ()
     (should-not (dyn-ring-rotate-until ring
                                        #'dyn-ring-rotate-left
                                        (lambda (element)
                                          nil)))
     (should (eq segment (dyn-ring-head ring)))))

  ;; 2-element ring
  (fixture-2-ring
   (lambda ()
     (should (dyn-ring-rotate-until ring
                                    #'dyn-ring-rotate-left
                                    (lambda (element)
                                      (not (= 2 element)))))
     (should (eq seg1 (dyn-ring-head ring)))))
  (fixture-2-ring
   (lambda ()
     (should (dyn-ring-rotate-until ring
                                    #'dyn-ring-rotate-right
                                    (lambda (element)
                                      (not (= 2 element)))))
     (should (eq seg1 (dyn-ring-head ring)))))

  ;; 3-element ring
  (fixture-3-ring
   (lambda ()
     (should (dyn-ring-rotate-until ring
                                    #'dyn-ring-rotate-left
                                    (lambda (element)
                                      (not (= 3 element)))))
     (should (eq seg1 (dyn-ring-head ring)))))
  (fixture-3-ring
   (lambda ()
     (should (dyn-ring-rotate-until ring
                                    #'dyn-ring-rotate-right
                                    (lambda (element)
                                      (not (= 3 element)))))
     (should (eq seg2 (dyn-ring-head ring)))))
  ;; non-trivial predicate
  (fixture-3-ring
   (lambda ()
     (should (dyn-ring-rotate-until ring
                                    #'dyn-ring-rotate-left
                                    (lambda (element)
                                      (= element 2))))
     (should (eq seg2 (dyn-ring-head ring)))))
  (fixture-3-ring
   (lambda ()
     (should (dyn-ring-rotate-until ring
                                    #'dyn-ring-rotate-right
                                    (lambda (element)
                                      (= element 2))))
     (should (eq seg2 (dyn-ring-head ring)))))
  ;; predicate never satisfied
  (fixture-3-ring
   (lambda ()
     (should-not (dyn-ring-rotate-until ring
                                        #'dyn-ring-rotate-left
                                        (lambda (element)
                                          nil)))
     (should (eq seg3 (dyn-ring-head ring)))))
  (fixture-3-ring
   (lambda ()
     (should-not (dyn-ring-rotate-until ring
                                        #'dyn-ring-rotate-right
                                        (lambda (element)
                                          nil)))
     (should (eq seg3 (dyn-ring-head ring)))))
  ;; if predicate is true on the head, it does not rotate the ring
  (fixture-2-ring
   (lambda ()
     (should (dyn-ring-rotate-until ring
                                    #'dyn-ring-rotate-left
                                    (lambda (element)
                                      t)))
     (should (eq seg2 (dyn-ring-head ring)))))
  (fixture-2-ring
   (lambda ()
     (should (dyn-ring-rotate-until ring
                                    #'dyn-ring-rotate-right
                                    (lambda (element)
                                      t)))
     (should (eq seg2 (dyn-ring-head ring))))))

(ert-deftest dyn-ring-find-test ()
  ;; empty ring
  (fixture-0-ring
   (lambda ()
     (should-not (dyn-ring-find ring
                                (lambda (element)
                                  t)))))

  ;; 1-element ring
  (fixture-1-ring
   (lambda ()
     (should (equal (list 1)
                    (dyn-ring-find ring
                                   (lambda (element)
                                     (= 1 element)))))
     (should-not (dyn-ring-find ring
                                (lambda (element)
                                  nil)))))

  ;; 2-element ring
  (fixture-2-ring
   (lambda ()
     (should (equal (list 1)
                    (dyn-ring-find ring
                                   (lambda (element)
                                     (= 1 element)))))
     (let ((result (dyn-ring-find ring
                                  (lambda (element)
                                    (> element 0)))))
       (should (member 1 result))
       (should (member 2 result)))
     (should-not (dyn-ring-find ring
                                (lambda (element)
                                  nil)))))

  ;; 3-element ring
  (fixture-3-ring
   (lambda ()
     (should (equal (list 1)
                    (dyn-ring-find ring
                                   (lambda (element)
                                     (= 1 element)))))
     (let ((result (dyn-ring-find ring
                                  (lambda (element)
                                    (> element 1)))))
       (should (member 2 result))
       (should (member 3 result))
       (should-not (member 1 result)))
     (should-not (dyn-ring-find ring
                                (lambda (element)
                                  nil))))))

(ert-deftest dyn-ring-find-forwards-test ()
  ;; empty ring
  (fixture-0-ring
   (lambda ()
     (should-not (dyn-ring-find-forwards ring
                                         (lambda (element)
                                           t)))))

  ;; 1-element ring
  (fixture-1-ring
   (lambda ()
     (should (eq segment
                 (dyn-ring-find-forwards ring
                                         (lambda (element)
                                           (= 1 element)))))
     (should-not (dyn-ring-find-forwards ring
                                         (lambda (element)
                                           nil)))))

  ;; 2-element ring
  (fixture-2-ring
   (lambda ()
     (should (eq seg1
                 (dyn-ring-find-forwards ring
                                         (lambda (element)
                                           (= 1 element)))))
     (should (eq seg2 (dyn-ring-find-forwards ring
                                              (lambda (element)
                                                (< element 3)))))
     (should (eq seg1 (dyn-ring-find-forwards ring
                                              (lambda (element)
                                                (< element 2)))))
     (should-not (dyn-ring-find-forwards ring
                                         (lambda (element)
                                           nil)))))

  ;; 3-element ring
  (fixture-3-ring
   (lambda ()
     (should (eq seg1
                 (dyn-ring-find-forwards ring
                                         (lambda (element)
                                           (= 1 element)))))
     (should (eq seg3 (dyn-ring-find-forwards ring
                                              (lambda (element)
                                                (< element 4)))))
     (should (eq seg2 (dyn-ring-find-forwards ring
                                              (lambda (element)
                                                (< element 3)))))
     (should-not (dyn-ring-find-forwards ring
                                         (lambda (element)
                                           nil))))))

(ert-deftest dyn-ring-find-backwards-test ()
  ;; empty ring
  (fixture-0-ring
   (lambda ()
     (should-not (dyn-ring-find-backwards ring
                                          (lambda (element)
                                            t)))))

  ;; 1-element ring
  (fixture-1-ring
   (lambda ()
     (should (eq segment
                 (dyn-ring-find-backwards ring
                                          (lambda (element)
                                            (= 1 element)))))
     (should-not (dyn-ring-find-backwards ring
                                          (lambda (element)
                                            nil)))))

  ;; 2-element ring
  (fixture-2-ring
   (lambda ()
     (should (eq seg1
                 (dyn-ring-find-backwards ring
                                          (lambda (element)
                                            (= 1 element)))))
     (should (eq seg2 (dyn-ring-find-backwards ring
                                               (lambda (element)
                                                 (< element 3)))))
     (should (eq seg1 (dyn-ring-find-backwards ring
                                               (lambda (element)
                                                 (< element 2)))))
     (should-not (dyn-ring-find-backwards ring
                                          (lambda (element)
                                            nil)))))

  ;; 3-element ring
  (fixture-3-ring
   (lambda ()
     (should (eq seg1
                 (dyn-ring-find-backwards ring
                                          (lambda (element)
                                            (= 1 element)))))
     (should (eq seg3 (dyn-ring-find-backwards ring
                                               (lambda (element)
                                                 (< element 4)))))
     (should (eq seg1 (dyn-ring-find-backwards ring
                                               (lambda (element)
                                                 (< element 3)))))
     (should-not (dyn-ring-find-backwards ring
                                          (lambda (element)
                                            nil))))))

(ert-deftest dyn-ring-contains-p-test ()
  ;; empty ring
  (fixture-0-ring
   (lambda ()
     (should-not (dyn-ring-contains-p ring 1))))

  ;; 1-element ring
  (fixture-1-ring
   (lambda ()
     (should (dyn-ring-contains-p ring 1))
     (should-not (dyn-ring-contains-p ring 2))))

  ;; 2-element ring
  (fixture-2-ring
   (lambda ()
     (should (dyn-ring-contains-p ring 1))
     (should (dyn-ring-contains-p ring 2))
     (should-not (dyn-ring-contains-p ring 3))))

  ;; 3-element ring
  (fixture-3-ring
   (lambda ()
     (should (dyn-ring-contains-p ring 1))
     (should (dyn-ring-contains-p ring 2))
     (should (dyn-ring-contains-p ring 3))
     (should-not (dyn-ring-contains-p ring 4)))))

(ert-deftest dyn-ring-values-test ()
  ;; empty ring
  (fixture-0-ring
   (lambda ()
     (should (null (dyn-ring-values ring)))))

  ;; 1-element ring
  (fixture-1-ring
   (lambda ()
     (should (equal (list 1) (dyn-ring-values ring)))))

  ;; 2-element ring
  (fixture-2-ring
   (lambda ()
     (should (equal (list 1 2) (dyn-ring-values ring)))))

  ;; 3-element ring
  (fixture-3-ring
   (lambda ()
     (should (equal (list 1 2 3) (dyn-ring-values ring))))))

(ert-deftest dyn-ring-map-test ()
  ;; empty ring
  (fixture-0-ring
   (lambda ()
     (let ((result (dyn-ring-map ring #'1+)))
       (should (dyn-ring-empty-p result)))))

  ;; one-element ring
  (fixture-1-ring
   (lambda ()
     (let ((result (dyn-ring-map ring #'1+)))
       (should (equal (dyn-ring-values result)
                      (seq-map #'1+ (dyn-ring-values ring)))))))

  ;; two-element ring
  (fixture-2-ring
   (lambda ()
     (let ((result (dyn-ring-map ring #'1+)))
       (should (equal (dyn-ring-values result)
                      (seq-map #'1+ (dyn-ring-values ring)))))))

  ;; 3-element ring
  (fixture-3-ring
   (lambda ()
     (let ((result (dyn-ring-map ring #'1+)))
       (should (equal (dyn-ring-values result)
                      (seq-map #'1+ (dyn-ring-values ring)))))))
  ;; copy ring
  (fixture-3-ring
   (lambda ()
     (let ((result (dyn-ring-map ring #'identity)))
       (should (dyn-ring-equal-p result ring))))))

(ert-deftest dyn-ring-transform-map-test ()
  ;; empty ring
  (fixture-0-ring
   (lambda ()
     (should-not (dyn-ring-transform-map ring #'1+))))

  ;; one-element ring
  (fixture-1-ring
   (lambda ()
     (should (dyn-ring-transform-map ring #'1+))
     (should (equal (list 2) (dyn-ring-values ring)))))

  ;; two-element ring
  (fixture-2-ring
   (lambda ()
     (should (dyn-ring-transform-map ring #'1+))
     (should (equal (list 2 3) (dyn-ring-values ring)))))

  ;; 3-element ring
  (fixture-3-ring
   (lambda ()
     (should (dyn-ring-transform-map ring #'1+))
     (should (equal (list 2 3 4) (dyn-ring-values ring))))))

(ert-deftest dyn-ring-filter-test ()
  ;; empty ring
  (fixture-0-ring
   (lambda ()
     (let ((result (dyn-ring-filter ring #'cl-oddp)))
       (should (dyn-ring-equal-p result ring)))))

  ;; one-element ring
  (fixture-1-ring
   (lambda ()
     (let ((result (dyn-ring-filter ring #'cl-oddp)))
       (should (dyn-ring-equal-p result ring)))))
  (fixture-1-ring
   (lambda ()
     (let ((result (dyn-ring-filter ring #'cl-evenp)))
       (should (dyn-ring-empty-p result)))))

  ;; two-element ring
  (fixture-2-ring
   (lambda ()
     (let ((result (dyn-ring-filter ring #'cl-oddp)))
       (should (equal (list 1) (dyn-ring-values result))))))
  (fixture-2-ring
   (lambda ()
     (let ((result (dyn-ring-filter ring #'cl-evenp)))
       (should (equal (list 2) (dyn-ring-values result))))))

  ;; 3-element ring
  (fixture-3-ring
   (lambda ()
     (let ((result (dyn-ring-filter ring #'cl-oddp)))
       (should (equal (list 1 3) (dyn-ring-values result))))))

  ;; filter out all
  (fixture-3-ring
   (lambda ()
     (let ((result (dyn-ring-filter ring (lambda (elem) nil))))
       (should (dyn-ring-empty-p result)))))

  ;; filter out none
  (fixture-3-ring
   (lambda ()
     (let ((result (dyn-ring-filter ring (lambda (elem) t))))
       (should (dyn-ring-equal-p result ring)))))

  ;; filter should behave the same as deletion for unique elements
  (fixture-3-ring
   (lambda ()
     (let ((result (dyn-ring-filter ring
                                    (lambda (elem)
                                      (not (= elem 1))))))
       (dyn-ring-delete ring 1)
       (should (dyn-ring-equal-p result ring)))))
  (fixture-3-ring
   (lambda ()
     (let ((result (dyn-ring-filter ring
                                    (lambda (elem)
                                      (not (= elem 2))))))
       (dyn-ring-delete ring 2)
       (should (dyn-ring-equal-p result ring))))))

(ert-deftest dyn-ring-transform-filter-test ()
  ;; empty ring
  (fixture-0-ring
   (lambda ()
     (should-not (dyn-ring-transform-filter ring #'cl-oddp))))

  ;; one-element ring
  (fixture-1-ring
   (lambda ()
     (should (dyn-ring-transform-filter ring #'cl-oddp))
     (should (= 1 (dyn-ring-value ring)))
     (should (= 1 (dyn-ring-size ring)))))
  (fixture-1-ring
   (lambda ()
     (should (dyn-ring-transform-filter ring #'cl-evenp))
     (should (dyn-ring-empty-p ring))))

  ;; two-element ring
  (fixture-2-ring
   (lambda ()
     (should (dyn-ring-transform-filter ring #'cl-oddp))
     (should (equal (list 1) (dyn-ring-values ring)))))
  (fixture-2-ring
   (lambda ()
     (should (dyn-ring-transform-filter ring #'cl-evenp))
     (should (equal (list 2) (dyn-ring-values ring)))))

  ;; 3-element ring
  (fixture-3-ring
   (lambda ()
     (should (dyn-ring-transform-filter ring #'cl-oddp))
     (should (equal (list 1 3) (dyn-ring-values ring)))))

  ;; filter out all
  (fixture-3-ring
   (lambda ()
     (should (dyn-ring-transform-filter ring (lambda (elem) nil)))
     (should (dyn-ring-empty-p ring))))

  ;; filter out none
  (fixture-3-ring
   (lambda ()
     (let ((ring-copy (dyn-ring-map ring #'identity)))
       (should (dyn-ring-transform-filter ring (lambda (elem) t)))
       (should (dyn-ring-equal-p ring ring-copy)))))

  ;; filter should behave the same as deletion for unique elements
  (fixture-3-ring
   (lambda ()
     (let ((ring-copy (dyn-ring-map ring #'identity)))
       (dyn-ring-transform-filter ring-copy
                                  (lambda (elem)
                                    (not (= elem 1))))
       (dyn-ring-delete ring 1)
       (should (dyn-ring-equal-p ring ring-copy)))))
  (fixture-3-ring
   (lambda ()
     (let ((ring-copy (dyn-ring-map ring #'identity)))
       (dyn-ring-transform-filter ring-copy
                                  (lambda (elem)
                                    (not (= elem 2))))
       (dyn-ring-delete ring 2)
       (should (dyn-ring-equal-p ring ring-copy))))))
