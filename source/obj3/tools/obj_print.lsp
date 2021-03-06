;; OBJ3 version 2
;; Copyright (c) 2000, Joseph Kiniry, Joseph Goguen, Sula Ma
;; Copyright (c) 1988,1991,1993 SRI International
;; All Rights Reserved
;;
;; Redistribution and use in source and binary forms, with or without
;; modification, are permitted provided that the following conditions are
;; met:
;; 
;;   o Redistributions of source code must retain the above copyright
;;   notice, this list of conditions and the following disclaimer.
;; 
;;   o Redistributions in binary form must reproduce the above copyright
;;   notice, this list of conditions and the following disclaimer in the
;;   documentation and/or other materials provided with the distribution.
;; 
;;   o Neither name of the Joseph Kiniry, Joseph Goguen, Sula Ma, or SRI
;;   International, nor the names of its contributors may be used to
;;   endorse or promote products derived from this software without
;;   specific prior written permission.
;; 
;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
;; ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
;; LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
;; FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL SRI
;; INTERNATIONAL OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
;; INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
;; (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
;; SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
;; HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
;; STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
;; ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
;; OF THE POSSIBILITY OF SUCH DAMAGE.

;; $Id: obj_print.lsp,v 206.1 2003/09/29 12:46:22 kiniry Exp $

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;                    obj_print
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;; Tim Winkler ;;;; Created: 7/8/86

;;; lower-level object printing functions -- debugging or internal use

;;;;;;;;;;;;;;;; Summary ;;;;;;;;;;;;;;;;
; omitted

(defvar *print$indent* 0)
(defvar *print$indent_increment* 2)
(defvar *print$explicit* nil) ;if t then give more detail on sorts, etc.
(defvar *print$abbrev_mod* nil) ; abbreviate module names
(defvar *print$abbrev_num* 0)
(defvar *print$abbrev_table* nil)
(defvar *print$operator_table* nil)
(defvar *print$flag_module_values* nil)
(defvar *print$indent_contin* t)
(defvar *print$mode* nil)
(defvar *print$all_eqns* nil)
(defvar *print$ignore_mods* nil)

(defun print$abbrev_table ()
  (let ((*print$abbrev_mod* nil))
  (dolist (m (reverse *print$abbrev_table*))
    (princ "MOD-") (princ (cdr m)) (princ " -->")
    (print$mod_name (car m)) (terpri)
  )))

(defun print$module (mod &optional (*print$indent* *print$indent*))
  (print$indent) (princ "module ") (print$mod_name mod) (print$next)
  (princ "kind: ") (prin1 (module$kind mod)) (print$next)
  (when (or *print$explicit* (module$parameters mod))
  (princ "parameters: ") (print$name (module$parameters mod)) (print$next))
  (when (or *print$explicit* (module$sub_modules mod))
  (princ "sub-modules: ") (print$brief (module$sub_modules mod)) (print$next))
  (when (or *print$explicit* (module$sorts mod))
  (princ "principal sort: ")
  (let ((modprs (module$principal_sort mod)))
    (if modprs (print$full modprs) (princ "NONE")))
  (print$next)
  (princ "sorts: ") (print$nested_list (module$sorts mod)) (print$next))
  (when (or *print$explicit* (module$sort_relation mod))
  (princ "sort relation: ")
      (print$list (module$sort_relation mod)) (print$next))
  (when (or *print$explicit* (module$operators mod))
  (let ((obj$current_module mod))
  (princ "operators: ") (print$nested_list (module$operators mod)) (print$next)
  ))
  (when (or *print$explicit* (module$sort_constraints mod))
  (princ "sort constraints: ")
      (print$nested_list_as 'sort_constraint (module$sort_constraints mod))
      (print$next))
  (when (or *print$explicit* (module$variables mod))
  (princ "variables: ")
      (print$list_as 'variable (module$variables mod)) (print$next))
  (when (or *print$explicit* (module$equations mod))
  (princ "equations: ")
      (print$nested_list_as 'rule (module$equations mod)) (print$next))
  (when (or *print$explicit* (module$sort_order mod))
  (princ "sort order: ") (print$next)
      (let ((*print$indent* (1+ *print$indent*)))
      (print$sort_order (module$sort_order mod))) (print$indent))
  (when (or *print$explicit*
	  (let ((dict (module$parse_dictionary mod)))
	  (and dict
	    (if (typep dict 'hash-table)
		(< 0 (hash-table-count dict))
	      (or (< 0 (hash-table-count (dictionary$table dict)))
		  (dictionary$built_ins dict))))))
  (princ "parse dictionary: ")
      (print$print_as 'parse_dictionary (module$parse_dictionary mod))
      (print$indent))
  (when (or *print$explicit* (module$juxtaposition mod))
  (princ "juxtaposition operators: ")
      (print$name (module$juxtaposition mod)) (print$next))
  (when (and *print$operator_table*
	     (or *print$explicit* (module$operator_table mod)))
  (princ "operator table: ") (print$next)
      (print$operator_table (module$operator_table mod)))
  (when (or *print$explicit* (module$rules mod))
  (princ "rules: ")
      (print$nested_list_as 'rule (module$rules mod)) (print$next))
  (when (or *print$explicit* (module$assertions mod))
  (princ "assertions: ")
      (print$list_as 'assertions (module$assertions mod))
      (print$next))
  (when (or *print$explicit* (module$status mod))
  (princ "status: ") (print$brief (module$status mod)) (print$next))
  (princ "end of module ") (print$mod_name mod) (print$next)
)

(defun print$list (x) (print$obj x t))

(defun print$nested_list (x)
  (let ((*print$indent* (1+ *print$indent*)))
  (print$next)
  (print$obj x t)))

(defun print$nested_list_as (typ x)
  (let ((*print$indent* (1+ *print$indent*)))
  (print$next)
  (print$list_as typ x)))

(defun print$list_as (typ lst)
  (princ "(")
  (let ((flag nil))
    (do ((l lst (cdr l)))
	((atom l) (unless (null l) (princ " . ") (print$obj l nil)))
      (if flag (print$next) (setq flag t))
      (print$print_as typ (car l))))
  (princ ")"))

(defun print$num_list_as (typ lst)
  (princ "(")
  (let ((flag nil))
    (do ((l lst (cdr l))
	 (i 0 (1+ i)))
	((atom l) (unless (null l) (princ " . ") (print$obj l nil)))
      (if flag (print$next) (setq flag t))
      (prin1 i) (princ ": ")
      (print$print_as typ (car l))))
  (princ ")"))

(defun print$name_list (lst)
  (princ "(")
  (let ((flag nil))
    (do ((l lst (cdr l)))
	((atom l) (unless (null l) (princ " . ") (print$name l)))
      (if flag (print$next) (setq flag t))
      (print$name (car l))))
  (princ ")"))

(defun print$brief (x) (print$obj x nil))

(defun print$full (x) (print$obj x t))

(defun print$obj (x verb?)
  (if (is-illegal-type x) (progn (princ "illegal#") (print$addr x))
  (print$print_as (type-of x) x verb?)))

(defun print$print_as (typ x &optional (verb? t) (label nil))
  (when label (princ typ) (princ ":"))
  (when (and (eq 'vector typ) (= 26 (length x)) (eq 'ac-state (aref x 25)))
     (setq typ 'ac_state)) ;@@@ temp patch
  (case typ
    ((symbol fixnum string simple-string) (prin1 x))
    (cons
      (princ "(")
      (let ((flag nil))
	(do ((lst x (cdr lst)))
	    ((atom lst) (unless (null lst) (princ " . ") (print$obj lst nil)))
	  (if flag (princ " ") (setq flag t))
	  (print$obj (car lst) verb?)))
      (princ ")"))
    (operator (if verb? (print$operator x) (print$name x)))
    (operator_info (print$operator_info x))
    (variable (print$variable x))
    (sort (print$sort x))
    (module
      (if verb? (print$module x)
	(print$mod_name x)))
    (parse_dictionary (print$parse_dictionary x))
    (sort_constraint (print$sort_constraint x))
;    (equation (print$equation x))
    (rule (print$rule x))
    (rule_ring (print$rule_ring x))
    (theory (print$theory x))
    (theory_info (print$theory_info x))
    (term (print$term x))
    (assertions (print$assertions x))
    (state (print$state x))
    (match_system (print$match_system x))
    (c_state (print$theory_state_as the_C_property x))
    (a_state (print$theory_state_as the_A_property x))
    (az_state (print$theory_state_as the_AZ_property x))
    (ac_state (print$theory_state_as the_AC_property x))
    (acz-state (print$theory_state_as the_ACZ_property x))
    (empty$state (print$theory_state_as the_empty_property x))
    (equation_comp (print$equation_comp x))
    (substitution (print$substitution x))
    ((bignum standard-char string-char) (prin1 x))
    (otherwise
     (cond
      ((null x) (prin1 x))
      #+(or CMU CLISP) ((typep x 'string) (prin1 x))
      (t
       (princ typ) (princ ":")
       (let ((*print-level* 2)
	     (*print-length* 20))
	 (prin1 x))
       )))
  ))

(defun print$name (x)
  (print$chk)
  (if (is-illegal-type x) (progn (princ "illegal#") (print$addr x))
  (let ((typ (type-of x)))
  (when (and (eq 'vector typ) (= 26 (length x)) (eq 'ac-state (aref x 25)))
     (setq typ 'ac_state)) ;@@@ temp patch
  (case typ
    ((symbol fixnum string simple-string) (prin1 x))
    (cons
      (princ "(")
      (let ((flag nil))
	(do ((lst x (cdr lst)))
	    ((atom lst) (unless (null lst) (princ " . ") (print$name lst)))
	  (if flag (princ " ") (setq flag t))
	  (print$name (car lst))))
      (princ ")"))
    (operator (mapc #'princ (operator$name x))
	      (princ ":")
	      (mapc #'(lambda (y) (princ " ")
			(print$sort_name (operator$module x) y))
		    (operator$arity x))
	      (princ "->")
	      (print$sort_name (operator$module x) (operator$coarity x))
	      (princ ".") (print$name (operator$module x)))
    (operator_info (print$operator_info x))
    (variable (print$safe (variable$name x))
	      (princ ":")
	      (when (variable$is_general_variable x) (princ "^"))
	      (print$sort_name nil (variable$initial_sort x)))
    (sort (princ (sort$name x))
	  (when *print$explicit*
	  (princ ".")
	  (print$name (sort$module x))))
    (module (print$mod_name x))
    (rule (princ "rule:") (print$rule x)) ;&&&& 21 May 87
    ((bignum standard-char string-char) (prin1 x))
    (otherwise
     (cond
      ((null x) (prin1 x))
      #+(or CMU CLISP) ((typep x 'string) (prin1 x))
      (t (princ "Name? ")
	 (princ typ) (princ ":")
	 (prin1 x))))
  ))))

(defun print$operator (op &optional (*print$indent* *print$indent*))
  (let ((haveinfo (and obj$current_module
		       (module$operator_table obj$current_module)
		       (optable$operator_info
			(module$operator_table obj$current_module) op))))
  (princ "op " ) (princ (operator$name op)) (princ " of ")
      (print$mod_name (operator$module op))
  (print$next)
  (princ "rank: ")
      (when (operator$arity op) (print$name (operator$arity op)))
      (princ " -> ")
      (print$name (operator$coarity op))
  (let ((*print$indent* (1+ *print$indent*)))
  (print$next)
  (when (or *print$explicit* (not (zerop (operator$precedence op))))
  (princ "precedence: ") (prin1 (operator$precedence op)) (princ "  "))
      (princ "syntactic type: ")
          (prin1 (operator$syntactic_type op))
	  (when (or *print$explicit* (operator$is_standard op))
	  (princ "  ")
	  (princ "standard: ") (prin1 (operator$is_standard op)))
  (print$next)
  (princ "form: ") (print$name (operator$form op))
  (print$next)
  (when haveinfo
  (print$operator_info haveinfo))
  ) ;...let ((*print$indent* ))
  (print$next)
  ))

(defun print$variable (var)
  (print$safe (variable$name var))
  (princ ":")
  (when (variable$is_general_variable var) (princ "^"))
  (let ((val (variable$sorts var)))
    (print$sort_name nil (if (null (cdr val)) (car val) val)))
  )

(defun print$sort (srt)
  (princ (sort$name srt))
  (when (sort$info srt) (princ "^"))
  (princ ".")
  (print$name (sort$module srt))
  )

(defun print$sort_order (so)
  (dolist (e so)
    (print$indent)
    (print$name (car e)) (princ "  ")
    (princ "lower:")
	(dolist (i (cadr e)) (princ " ") (print$name i))
    (princ "  ")
    (princ "higher:")
	(dolist (i (cddr e)) (princ " ") (print$name i))
    (terpri)
  ))

(defun print$sort_constraint (sc)
  (print$name (sort_constraint$operator sc)) (princ " => ")
  (print$name (sort_constraint$constrained_operator sc)) (princ " for ")
  (print$list (sort_constraint$variables sc)) (princ " in ")
  (print$term (sort_constraint$condition sc))
  )

(defun print$rule (rul)
  (when (rule$labels rul) (print$rule_labels rul) (princ " "))
  (let ((bi (rule$is_built_in rul)))
    (if bi (princ "b-rule ") (princ "rule "))
    (print$term (rule$lhs rul)) (princ " => ")
    (let ((rul_rhs (rule$rhs rul)))
    (if bi
      (let ((lam (function_lambda_expression rul_rhs)))
	(pr (function_lambda_expression (cadr (cadr (caddr lam))))))
      (print$term (rule$rhs rul))))
    (unless (term$similar *obj_BOOL$true* (rule$condition rul))
      (princ " if ") (print$term (rule$condition rul)))
    (when (rule$id_condition rul)
      (princ " if.id ") (print$id_condition (rule$id_condition rul)))
    (when (rule$end_reduction rul)
    (princ " end: ")
    (print$simple (rule$end_reduction rul))) ;27 Mar 87 was prin1
    (when (rule$kind rul)
    (princ " ")
    (print$simple (rule$kind rul)))
    (when (rule$method rul)
    (princ " method: ")
    (let* ((m (rule$method rul))
	   (nm (match$method_name m)))
    (if nm (princ nm)
      (print$simple m))))
    (when (and (rule$AC_extension rul)
	       (not (equal '(nil) (rule$AC_extension rul))))
      (print$next)
      (princ "  AC: ")
      (print$rule (car (rule$AC_extension rul))))
    (when (and (rule$A_extensions rul)
	       (not (equal (rule$A_extensions rul) '(nil nil nil))))
      (dolist (r (rule$A_extensions rul))
	 (print$next)
	 (princ "  A: ")
	 (if (typep r 'rule)
	     (print$rule r)
	    (print$struct r))))
  ))

(defun print$pterm (term)
  (if (is-illegal-type term) (progn (princ "illegal#") (print$addr term))
  (cond
   ((null term) (princ "%NIL"))
   ((atom term) (princ "%") (print$brief term))
   ((term$is_var term) (print$safe (variable$name term))
              (princ ":")
    (when (variable$is_general_variable term) (princ "^"))
    (let ((srt (variable$initial_sort term)))
      (if (eq 'sort (type-of srt))
	  (print$sort_name nil (variable$initial_sort term))
	(print$obj srt nil))))
   ((or (eq 'error (term$head term))
	(not (typep (term$head term) 'operator)))
    (pr term))
   ((term$is_built_in_constant term)
    (pr (term$built_in_value term)) (princ ":")
    (let ((op (term$head term)))
      (print$sort_name (operator$module op) (operator$coarity op))))
   ((and (null (term$subterms term))
	 (eq 'constant (car (operator$name (term$head term)))))
    (princ "#")
    (prin1 (cdr (operator$name (term$head term)))))
   ((operator$is_a_retract (term$head term))
    (let ((op (term$head term)))
    (princ "(retract:") (print$sort_name nil (car (operator$arity op)))
    (princ "->") (print$sort_name nil (operator$coarity op)) (princ ")")
    (print$pterm (term$arg_1 term))))
   (t
    (let* ((hd (if (consp (car term)) (term$head term) 'fail))
	  (nm (if (eq 'operator (type-of hd)) (operator$name hd) 'fail)))
      (if (eq 'fail nm) (print$brief term)
	(progn
	  (if (and (equal "_" (cadr nm)) (null (cdr nm))) (princ (car nm))
	    (dolist (i nm) (princ i)))
	  (princ "(")
	  (let ((comma_flag nil))
	  (dolist (st (term$subterms term))
	    (if comma_flag (princ ",") (setq comma_flag t))
	    (print$pterm st)))
	  (princ ")"))))
    ))))

(defun print$rule_ring (rr)
  (if (typep rr 'rule_ring) (progn
    (princ "rule ring: ")
    (do ((rule (rule_ring$initialize rr) (rule_ring$next rr))
	 )
	; avoid end_test so can trace it
	((eq (rule_ring-current rr) (rule_ring-mark rr)))
	(print$rule rule) (print$next)
	)
    )
    (progn (print$brief rr) (print$next)))
  )

(defun print$theory (th)
  (if (typep th 'theory) (progn
    (print$theory_info (theory$name th))
    (princ " zero: ")
    (let* ((zs (theory$zero th))
	   (flag (and (consp zs) (eq 'to_rename (car zs)))))
      (when flag (princ "to rename: ")
	(setq zs (cadr zs)))
      (if zs
	  (progn
	    (if *print$explicit*
		(print$struct (car zs))
	      (print$term (car zs)))
	    (when (cdr zs) (princ " rule-only")))
	(princ "NONE"))
      ))
   (print$brief th)))

(defun print$theory_info (thinf)
  (if (typep thinf 'theory_info) (progn
    (prin1 (theory_info$name thinf))
    (princ "[") (prin1 (theory_info$code thinf)) (princ ",")
    (print$chk)
    (unless (theory_info$empty_for_matching thinf) (princ "not "))
    (princ "empty for matching,equal:")
    (prin1 (theory_info$equal thinf))
    (princ ",")
    (print$next)
    (princ "init:")
    (prin1 (theory_info$init thinf))
    (princ ",")
    (print$chk)
    (princ "next:")
    (prin1 (theory_info$next thinf))
    (princ "]"))
    (print$brief thinf))
  )
    
(defun print$assertions (as)
  (princ "From ") (print$name (car as))
      (princ "  Mode: ") (princ (cadr as))
      (princ "  Assertions: ") (print$next)
  (print$list_as 'rule (caddr as)))

(defun print$struct (x)
  (if (is-illegal-type x) (progn (princ "illegal#") (print$addr x))
  (let ((typ (type-of x)))
  (case typ
    ((symbol fixnum string) (prin1 x))
    (cons
      (if (null x) (prin1 nil)
      (if (null (cdr x))
	  (progn (princ "(") (print$struct (car x)) (princ ")"))
	(progn (let ((*print$indent* (1+ *print$indent*)))
	  (princ "(")
	  (print$struct (car x))
	  (do ((lst (cdr x) (cdr lst)))
	      ((atom lst)
	       (unless (null lst) (princ " . ") (print$struct lst)))
	      (print$next)
	      (print$struct (car lst)))
	  (princ ")"))))))
    (operator
              (let ((val (operator$name x)))
		(if (not (consp val)) (princ val)
		  (mapc #'princ (operator$name x))))
	      (princ ":")
	      (let ((mod (operator$module x)))
	      (mapc #'(lambda (x) (princ " ")
			(if (typep x 'sort) (print$sort_name mod x)
			  (pr x)))
		    (operator$arity x))
	      (princ "->")
	      (print$sort_name mod (operator$coarity x)))
	      (princ ".") (print$name (operator$module x)))
    (variable (print$safe (variable$name x))
	      (princ ":")
	      (when (variable$is_general_variable x) (princ "^"))
	      (print$sort_name nil (variable$initial_sort x)))
    (sort (princ (sort$name x))
	  (princ ".")
	  (print$name (sort$module x)))
    (rule
      (let ((bi (rule$is_built_in x)))
	(if bi (princ "b-rule ") (princ "rule "))
	(print$struct (rule$lhs x)) (princ " => ") (print$next)
	(let ((rul_rhs (rule$rhs x)))
	(if bi
	    (pr (function_lambda_expression
		 (cadr (cadr (caddr
			      (function_lambda_expression rul_rhs))))))
	  (print$struct (rule$rhs x))))
	(unless (term$similar *obj_BOOL$true* (rule$condition x))
	  (princ " if ") (print$struct (rule$condition x)))
	(when (rule$id_condition x)
	  (princ " if.id ")
	  (print$struct
	   (rule$id_condition x)))
	(when (rule$end_reduction x)
	  (princ " end: ")
	  (print$simple (rule$end_reduction x)))
	(when (rule$kind x)
	  (princ " ")
	  (print$simple (rule$kind x)))
	(when (rule$method x)
	  (princ " method: ")
	  (let* ((m (rule$method x))
		 (nm (match$method_name m)))
	    (if nm (princ nm)
	      (print$simple m))))
	(when (rule$labels x) (princ " ") (print$rule_labels x))
	(when (and (rule$AC_extension x)
		   (not (equal '(nil) (rule$AC_extension x))))
	(print$next) (princ "AC:") (print$next)
	(print$struct (rule$AC_extension x)))
	(when (and (rule$A_extensions x)
		   (not (equal (rule$A_extensions x) '(nil nil nil))))
	(print$next) (princ "A:") (print$next)
	(print$struct (rule$A_extensions x)))
	))
    (module (print$mod_name x))
    (state (print$state x))
    (match_system (print$match_system x))
    (c_state (print$theory_state_as the_C_property x))
    (a_state (print$theory_state_as the_A_property x))
    (az_state (print$theory_state_as the_AZ_property x))
    (ac_state (print$theory_state_as the_AC_property x))
    (ac-state (print$theory_state_as the_AC_property x))
    (acz-state (print$theory_state_as the_ACZ_property x))
    (empty$state (print$theory_state_as the_empty_property x))
    (equation_comp (print$equation_comp x))
    ((bignum standard-char string-char) (prin1 x))
    (otherwise
     (cond
      ((null x) (prin1 x))
      #+(or CMU CLISP) ((typep x 'string) (prin1 x))
      (t (print$brief x))
      ))
  ))))

(defun print$rules_detail (mod)
  (let ((module (if (stringp mod) (modexp_eval$eval mod) mod)))
  (let ((rules (module$rules module)))
    (dolist (r rules)
      (print$struct r) (terpri))
  )))

(defun print$parse_dictionary (dict)
  (if (null dict) (progn (princ "NULL") (print$next))
  (if (typep dict 'hash-table) (progn
     (terpri)
     (let ((*print$indent* (1+ *print$indent*)))
     (maphash #'(lambda (x y) (print$indent) (princ x) (princ "  ")
		  (print$name y) (terpri))
	      dict)))
    (progn
      (print$parse_dictionary (dictionary$table dict))
      (princ "dictionary built-ins: ")
          (print$brief (dictionary$built_ins dict))
      (terpri)))))

(defun print$state (st)
  (princ "[state new: ") (prin1 (state-new st))
  (let ((*print$indent* (1+ *print$indent*)))
  (print$next)
  (princ "match_system:") (print$next)
  (print$match_system (state$match_system st)) (print$next)
  (princ "system to solve:") (print$next)
  (print$match_equations (state$sys_to_solve st))
  (princ "theory: ")  (print$theory_info (state-th_name st)) (print$next) ;@
  (princ "theory_state:") (print$next)
  (print$theory_state_as (state-th_name st) (state-theory_state st))
  (princ "]")
  );; let
  )

(defun print$match_system (s)
  (princ "[match_system system:") (print$next)
  (print$match_equations (match_system$system s))
  (princ "environment:") (print$next)
  (print$match_equations (match_system$env s)) (princ "]")
  )

(defun print$match_equations (eqs)
  (dolist (e eqs)
    (if (null e) (princ "NIL")
      (print$match_equation e))
    (print$next))
  )

(defun print$match_equation (eqn)
  (princ "eqn ")
  (print$term (car eqn))
  (princ " = ")
  (print$term (cdr eqn))
  )

(defun print$theory_state_as (nm st)
  (princ "[theory_state ")
  (cond
    ((or (eq the_empty_property nm) (eq the_I_property nm))
     (princ "empty: flag: ") (prin1 (empty$state-flag st)) (print$next)
     (princ "sys:") (print$next)
     (print$match_equations (empty$state-sys st))
     )
    ((or (eq the_Z_property nm) (eq the_IZ_property nm))
     (princ "Z: n: ") (prin1 (z-state-n st)) (print$next)
     (princ "sys: ") (print$next)
     (print$match_equations (z-state-sys st))
     )
    ((or (eq the_C_property nm) (eq the_CI_property nm))
     (princ "C: count: ") (prin1 (C_state-count st)) (print$next)
     (princ "sys:") (print$next)
     (print$match_equations (C_state-sys st))
     )
     ((or (eq the_CZ_property nm) (eq the_CIZ_property nm))
      (princ "CZ: n: ") (prin1 (cz-state-n st)) (print$next)
      (princ "sys: ") (print$next)
      (print$match_equations (cz-state-sys st))
      )
     ((or (eq the_A_property nm) (eq the_AI_property nm))
     (princ "A: size: ") (prin1 (A_state-size st)) (print$next)
     (princ "operator: ") (print$name (A_state-operator st)) (print$next)
     (princ "no more: ") (prin1 (A_state-no_more st)) (print$next)
     (princ "sys:") (print$next)
     (map nil #'(lambda (e_c) (print$equation_comp e_c) (print$next))
	  (A_state-sys st))
     )
    ((or (eq the_AZ_property nm) (eq the_AIZ_property nm))
     (princ "AZ: size: ") (prin1 (AZ_state-size st)) (print$next)
     (princ "operator: ") (print$name (AZ_state-operator st)) (print$next)
     (princ "no more: ") (prin1 (AZ_state-no_more st)) (print$next)
     (princ "sys:") (print$next)
     (map nil #'(lambda (e_c) (print$equation_comp e_c) (print$next))
	  (AZ_state-sys st))
     )
    ((or (eq the_AC_property nm) (eq the_ACI_property nm))
     (princ "AC:") (terpri)
     (AC$unparse_AC-state st)
     (print$indent)
     )
    ((or (eq the_ACZ_property nm) (eq the_ACIZ_property nm))
     (princ "ACZ:") (terpri)
     (ACZ$unparse_ACZ-state st)
     (print$indent)
     )
    (t
     (princ "Unknown theory: ") (prin1 nm) (princ "  ") (pr st)
     )
    )
  (princ "]")
  )

(defun print$term_seq (x)
  (if (null x) (princ "NULL")
  (let ((flg nil))
  (dotimes (i (length x))
    (if flg (princ ",") (setq flg t))
    (princ " ")
    (let ((e (aref x i)))
      (if (and (consp e) (eq 'restr (car e)))
	(progn (princ "Restr:") (print$term (cdr e)))
      (print$term e)))
    ))))

(defun print$equation_comp (e_c)
  (princ "[equation_comp size left: ") (prin1 (equation_comp-sz_left e_c))
  (print$next)
  (princ "left:")
  (print$term_seq (equation_comp-left e_c))
  (print$next)
  (princ "right:")
  (print$term_seq (equation_comp-right e_c))
  (print$next)
  (princ " comp: ") (prin1 (equation_comp-comp e_c))
  (princ "]")
  )

(defun print$substitution (s)
  (if (null s)
      (progn (princ "empty substitution") (print$next))
  (if (or (null (car s)) (null (caar s)) (null (cdar s)))
      (progn (princ "substitution: ") (print$struct s) (print$next))
  (dolist (m s)
    (let ((src (car m)))
      (if (term$is_var src)
	  (print$variable src)
	(print$term src)))
    (princ " --> ")
    (print$term (cdr m))
    (print$next)
  ))))

(defun print$term_detailed (term)
  (if (is-illegal-type term) (progn (princ "illegal#") (print$addr term))
  (cond
   ((null term) (princ "%NIL"))
   ((atom term) (princ "%") (print$brief term))
   ((term$is_var term) (print$safe (variable$name term))
                (princ ":")
    (let ((srt (variable$initial_sort term)))
      (if (eq 'sort (type-of srt))
	  (print$sort_name nil (variable$initial_sort term))
	(print$obj srt nil))))
   ((eq 'error (term$head term))
    (prin1 term))
   ((term$is_built_in_constant term)
    (pr (term$built_in_value term)) (princ ":")
    (print$sort_name nil (operator$coarity (term$head term)))
    )
   ((and (null (term$subterms term))
	 (eq 'constant (car (operator$name (term$head term)))))
    (princ "#") ;&&&&
    (prin1 (cdr (operator$name (term$head term))))
    (princ ":")
    (print$sort_name nil (operator$coarity (term$head term))))
   (t
    (let* ((hd (if (consp (car term)) (term$head term) 'fail))
	  (nm (if (eq 'operator (type-of hd)) (operator$name hd) 'fail)))
      (if (eq 'fail nm) (print$brief term)
	(progn
	  (print$name hd)
	  (princ "(")
	  (let ((comma_flag nil))
	  (dolist (st (term$subterms term))
	    (if comma_flag (princ ",") (setq comma_flag t))
	    (print$term_detailed st)))
	  (princ ")"))))
    ))))

(defun print$mapping (mppg)
  (princ "name: ") (print$name (mapping$name mppg)) (princ " ")
  (princ "sort: ")
  (dolist (i (mapping$sort mppg))
    (print$name (car i)) (princ "-->") (print$name (cdr i)) (princ " "))
  (princ "op: ")
  (dolist (i (mapping$op mppg))
    (print$name (car i)) (princ "-->") (print$name (cdr i)) (princ " "))
  (princ "module: ")
  (dolist (i (mapping$module mppg))
    (print$name (car i)) (princ "-->") (print$name (cdr i)) (princ " "))
  )

(defun print$sort_name_3 (s str depth)
  (declare (ignore depth))
  (let ((*standard-output* str))
    (print$sort_name nil s)
  ))

(defun print$operator_table (tbl)
  (if (null tbl) (progn (princ "NULL") (print$next))
  (maphash #'(lambda (x y)
      (princ "operator info: ") (print$name x) (print$next)
      (print$operator_info y) (print$next))
    tbl)
  ))

(defun print$operator_info_3 (y str depth)
  (declare (ignore depth))
  (let ((*standard-output* str))
    (print$operator_info y)))

(defun print$operator_info (y)
  (if (null y)
      (princ "NULL")
  (progn
  (princ "strat: ") (prin1 (operator_info$rew_strategy y))
      (when (operator_info$user_rew_strategy y)
	(princ "  user strat: ") (prin1 (operator_info$rew_strategy y)))
      (when (or *print$explicit* (operator_info$memo y))
      (princ "  ") (princ "memo: ") (prin1 (operator_info$memo y)))
      (when (or *print$explicit* (operator_info$strictly_overloaded y))
      (princ "  ") (princ "overloaded: ")
          (prin1 (operator_info$strictly_overloaded y)))
  (when (or *print$explicit*
	  (or (eq 'void (operator_info$equational_theory y))
	      (not (eq the_empty_property
		       (theory$name (operator_info$equational_theory y))))))
  (if (eq 'void (operator_info$equational_theory y))
    (progn (print$next) (princ "theory: VOID"))
    (progn
      (print$next)
      (princ "theory: ")
	  (print$list (operator_info$equational_theory y))
	  (princ "  ")
	  (princ "error strategy: ")
	    (prin1 (operator_info$error_strategy y)))))
  (when (or *print$explicit* (operator_info$polymorphic y))
  (print$next) (princ "polymorphic: ") (pr (operator_info$polymorphic y)))
  (print$next)
  (let ((*print$indent* (1+ *print$indent*)))
  (when (or *print$explicit*
	    (and
	     (operator_info$rules_with_same_top y)
	     (not (rule_ring$is_empty
		  (operator_info$rules_with_same_top y)))))
  (princ "rules wst: ")
  (if (null (operator_info$rules_with_same_top y))
      (princ "NULL")
      (let ((*print$indent* (1+ *print$indent*)))
	(print$next)
	(print$rule_ring (operator_info$rules_with_same_top y))))
  ) ;when
  (when (or *print$explicit* (operator_info$rules_with_different_top y))
  (princ "rules wdt: ")
      (print$nested_list_as 'rule
	(operator_info$rules_with_different_top y))
  (print$next))
  ) ;...let ((*print$indent* ))
  (princ "  lowest: ") (print$name (operator_info$lowest y)) (print$next)
  (princ "  highest: ") (print$name (operator_info$highest y))
  (when (or *print$explicit* (operator_info$sort_constraint y))
  (print$next)
  (princ "  sort constraint: ")
      (let ((val (operator_info$sort_constraint y)))
	(if val (print$sort_constraint val)
	  (princ "none"))))
  )))

(defun print$op (mod op)
  (let ((obj$current_module mod))
  (print$operator op))
  )

(defun print$jammed (x)
  (if (consp x)
    (mapc #'princ x)
    (print$name x)))
