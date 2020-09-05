"Core macros for building Lemma definitions and expressions."

(require [hy.contrib.walk [let]])
(import [hy.models [HyExpression HySymbol HyString]]
        [hy.contrib.hy-repr [hy-repr]]
        [lemma.exceptions [*]]
        [lemma.precedence [FUNCTION-CALL-PRECEDENCE]]
        [lemma.lang [LatexString gen-latex listy?]]
        [collections [Counter]])

(eval-and-compile

  (setv ARG-GROUP-KEYS #{:paren :super :sub})

  (defn pair? [arg]
    (and (listy? arg) (= (len arg) 2)))

  (defn parse-arglist [arglist]
    "Given the list of raw (syntax) for a Lemma argument specification,
     returns a dictionary of useful components."
    ;; Check the syntax of each item in arglist.
    (for [arg arglist]
      (if-not (or
                ;; Symbol
                (isinstance arg HySymbol)
                ;; Pair of symbol and default value
                (and (pair? arg)
                     (isinstance (first arg) HySymbol))
                ;; arg group key
                (in arg ARG-GROUP-KEYS)
                ;; (type) annotation
                (and (isinstance arg HyExpression)
                     (= (first (arg)) (HySymbol "annotate*"))))
              (raise (LeSyntaxError f"Cannot parse argument: {arg}"))))
    (setv next-is-rest False)
    (setv next-is-kwargs False)
    (setv rest-sym None)
    (setv kwargs-sym None)
    (setv current-arg-group :paren)
    (setv sym-group-pairs [])
    ;; Walk through the arglist to parse it, tracking state with vars
    ;; above.
    (for [arg arglist]
      (if (in arg ARG-GROUP-KEYS)
        (setv current-arg-group arg)
        (let [single-arg (if (pair? arg) (first arg) arg)]
          (if
            ;; &kwonly unsupported
            (= single-arg '&kwonly)
            (raise (LeSyntaxError "&kwonly is not currently supported in Lemma parameter lists."))
            ;; Handle &rest
            (= single-arg '&rest)
            (setv next-is-rest True)
            ;; Handle &kwargs
            (= single-arg '&kwargs)
            (setv next-is-kwargs True)
            ;; Handle all other symbols
            (and (isinstance single-arg HySymbol)
                 (not (.startswith (name single-arg) "&")))
            (do
              (when next-is-rest
                (setv rest-sym single-arg)
                (setv next-is-rest False))
              (when next-is-kwargs
                (setv kwargs-sym single-arg)
                (setv next-is-kwargs False))
              (.append sym-group-pairs [single-arg current-arg-group]))))))
    (setv argsyms (list (map first sym-group-pairs)))
    {;; List of argument name symbols
     :syms argsyms
     ;; The symbol representing &rest args.
     :rest-sym rest-sym
     ;; The symbol representing &kwargs kwargs.
     :kwargs-sym kwargs-sym
     ;; Arglist that is valid syntax for a Hy function.
     :arglist (->> arglist
                   ;; Remove arg group keys.
                   (remove (fn [arg] (in arg ARG-GROUP-KEYS)))
                   ;; Ensure default Lemma values are wrapped as expressions.
                   (map (fn [arg]
                          (if (pair? arg)
                              [(first arg) `(lemma.core.expr ~(second arg))]
                              arg)))
                   (list))
     ;; A list of arg groups, where the each index contains the group
     ;; for the corresponding argsym/identifier.
     :groups (->> sym-group-pairs
                  (map second)
                  (list))
     ;; A dict that can be used as the raw syntax for bindings (maps
     ;; string names to unquoted symbols).
     :bindings (->> argsyms
                    (map (juxt name identity))
                    dict)
     ;; A list of Hy forms that will provide either the value that the
     ;; argsym resolves to, or a Lemma identifier.
     :identifiers-or-vals-hy
     (->> argsyms
          (map
            (fn [sym]
              `(try
                 (eval '~sym)
                 (except [NameError]
                   (lemma.lang.make-identifier '~sym)))))
          (list))})

  (defn symbol-arg-check [symbol calling-macro-name]
    "Raises LeSyntaxError with the calling-macro-name if symbol is not a symbol."
    (if-not (isinstance symbol str)
            (raise (LeSyntaxError f"The first argument to {calling-macro-name} must be a symbol."))))

  (defn capture-docstring [parts]
    "Return a tuple of a docstring (or None if there is no docstring)
     and the remaining parts."
    (if (isinstance (first parts) HyString)
        (, (first parts) (list (rest parts)))
        (, None parts)))

  (defn formula-call-latex [latex-name arg-groups arg-vals]
    "Generate a LatexString to represent the call of a Formula with the
     given latex-name, where arg-groups is a list provided by parse-arglist, and
     arg-vals contains Lemma values (including possibly identfiers) that
     represent the args. arg-groups is used to format arguments as subscripts,
     superscripts, or in-parens."
    ;; Create lists of arg latex for each arg group.
    (setv arg-grouping-dict {:sub [] :super [] :paren []})
    (for [[arg group] (zip arg-vals arg-groups)]
      (.append (get arg-grouping-dict group)
               (gen-latex arg)))
    ;; Format groups of args.
    (let [sub-args (if (empty? (get arg-grouping-dict :sub))
                       ""
                       (+ "_{" (.join ", " (get arg-grouping-dict :sub)) "}"))
          super-args (if (empty? (get arg-grouping-dict :super))
                         ""
                         (+ "^{" (.join ", " (get arg-grouping-dict :super)) "}"))
          paren-args (if (empty? (get arg-grouping-dict :paren))
                         ""
                         (+ r"\left(" (.join ", " (get arg-grouping-dict :paren)) r"\right)"))]
      ;; Generate final LatexString.
      (LatexString (+ latex-name sub-args super-args paren-args)
                   FUNCTION-CALL-PRECEDENCE))))

(defmacro/g! latexstr [latex &optional [precedence None]]
  "Return a LatexString for the given latex (str or another
   LatexString), with an optionally set precedence."
  `(do
     (import lemma.lang)
     (lemma.lang.make-latex-string ~latex ~precedence)))

(defmacro expr [form]
  "Return a Lemma expression for the given Lemma form."
  `(do
     (import lemma.lang)
     ;; Resolve symbols inside form in the global scope where this
     ;; expr is built.
     (.bind (lemma.lang.LeExpression '~form) (globals))))

(defmacro exprs [&rest forms]
  "Return a list of Lemma expressions for the given Lemma forms."
  (let [expr-forms (->> forms
                        (map (fn [form] `(lemma.core.expr ~form)))
                        (list))]
   `(do
      (require lemma.core)
      ~expr-forms)))

(defmacro def-identifier [symbol latex &optional doc]
  "Assign a Lemma identifier to symbol with the given latex
   representation (with optional doc string)."
  (symbol-arg-check symbol "def-identifier")
  `(do
     (import lemma.lang)
     (import lemma.docmd)
     (setv ~symbol (lemma.lang.make-identifier '~symbol ~latex))
     ;; Set name.
     (setv (. ~symbol name) (name '~symbol))
     ;; Set docstring.
     (if-not (none? ~doc)
             (setv (. ~symbol --doc--) ~doc))
     ;; Set _docmd.
     (setv (. ~symbol _docmd) (fn [] (lemma.docmd.identifier-docmd ~symbol)))))

(defmacro def-constant [symbol latex value &optional doc]
  "Assign a Lemma constant to symbol with the given latex
   representation and Hy value (with optional doc string)"
  (symbol-arg-check symbol "def-constant")
  `(do
     (require lemma.core)
     (import lemma.lang)
     (import lemma.docmd)
     (setv ~symbol (lemma.lang.LeConstant (lemma.core.latexstr ~latex) ~value))
     ;; Set name.
     (setv (. ~symbol name) (name '~symbol))
     ;; Set docstring.
     (if-not (none? ~doc)
             (setv (. ~symbol --doc--) ~doc))
     ;; Set _docmd.
     (setv (. ~symbol _docmd) (fn [] (lemma.docmd.constant-docmd ~symbol '~value)))))

(defmacro def-formula [symbol latex-name arglist &rest parts]
  "Assign a Lemma formula to the given symbol with the given latex-name
   representation. arglist should be a valid Hy function argument list (with
   support for optional arg-group keywords), followed by an optional docstring,
   and a body Lemma form representing the computation of the formula using the
   specified arguments."
  ;; Check symbol and latex-name.
  (symbol-arg-check symbol "def-formula")
  (if-not (isinstance latex-name str)
          (raise (LeSyntaxError "The name of an equation must be a LatexString or string.")))
  ;; Capture optional docstring.
  (setv [doc parts] (capture-docstring parts))
  ;; Ensure there is only one body form.
  (if-not (and (= (len parts) 1))
          (raise (LeSyntaxError "The body of a formula must be a single Lemma form.")))
  (let [args (parse-arglist arglist)
        body (first parts)]
    `(do
       (require hy.contrib.walk)
       (require lemma.core)
       (import lemma.lang)
       (setv ~symbol
             (hy.contrib.walk.let [body-expr (lemma.core.expr ~body)]
               (lemma.lang.LeFormula
                 :latex-fn
                 (fn ~(:arglist args)
                   (lemma.core.formula-call-latex
                     ~latex-name ~(:groups args) ~(:identifiers-or-vals-hy args)))
                 :expr-fn
                 (fn ~(:arglist args)
                   (.bind body-expr ~(:bindings args)))
                 :arg-identifiers ~(:identifiers-or-vals-hy args))))
       ;; Set name
       (setv (. ~symbol name) (name '~symbol))
       ;; Set docstring.
       (if-not (none? ~doc)
               (setv (. ~symbol --doc--) ~doc))
       ;; Set _docmd.
       (setv (. ~symbol _docmd) (fn [] (lemma.docmd.formula-docmd ~symbol '~arglist))))))

(defmacro/g! equation [arglist &rest parts]
  "Create a Lemma equation for the given arglist (in the format of a Hy function
   argument list), optional docstring, and a list of Lemma forms representing
   equivalent transformations/steps of an equation."
  ;; Capture optional docstring.
  (setv [doc parts] (capture-docstring parts))
  ;; Check there is a single list form representing equation steps.
  (if-not (and (= (len parts) 1)
               (isinstance (first parts) HyList))
          (raise (LeSyntaxError "The body of an equation must be a list of Lemma forms.")))
  (let [expr-forms (first parts)
        args (parse-arglist arglist)]
    `(do
       (require hy.contrib.walk)
       (require lemma.core)
       (import lemma.lang)
       (hy.contrib.walk.let
         [~g!expressions ~(->> expr-forms
                               (map (fn [body] `(lemma.core.expr ~body)))
                               (list))
          ~g!equation (lemma.lang.LeEquation
                        :expressions-fn
                        (fn ~(:arglist args)
                          (map (fn [expr]
                                 (.bind expr ~(:bindings args)))
                               ~g!expressions))
                        :arg-identifiers ~(:identifiers-or-vals-hy args))]
         ;; Set docstring.
         (if-not (none? ~doc)
                 (setv (. ~g!equation --doc--) ~doc))
         ;; Return equation.
         ~g!equation))))

(defmacro def-equation [symbol arglist &rest parts]
  "Assign a Lemma equation to the given symbol, see lemma.core.equation."
  (if (not (isinstance symbol HySymbol))
      (raise (LeSyntaxError "The first argument to def-equation must be a symbol.")))
  `(do
     (require lemma.core)
     (setv ~symbol (lemma.core.equation ~arglist ~@parts))
     ;; Set name.
     (setv (. ~symbol name) (name '~symbol))
     ;; Set _docmd.
     (setv (. ~symbol _docmd) (fn [] (lemma.docmd.equation-docmd ~symbol '~arglist)))))

;; Supported clause names for def-operator.
(setv OPERATOR-CLAUSES #{'expr 'latex 'latex-macro 'hy 'hy-macro
                         'precedence 'example-args})
;; Sets of operator clauses where only one of the clauses in each set
;; may be provided.
(setv EXCLUSIVE-OPERATOR-CLAUSE-SETS
      {:latex #{'expr 'latex 'latex-macro}
       :hy #{'expr 'hy 'hy-macro}})

(eval-and-compile

  (defn parse-precedence [clause-dict]
    "Given a dictionary of def-operator clauses, return the precedence value if
     one is specified, otherwise return None. Raise LeSyntaxError if precedence
     clause has incorrect syntax."
    (if (in 'precedence clause-dict)
        (let [precedence-clause (get clause-dict 'precedence)]
          ;; Check only a single precedence value is specified.
          (if (not (= (len precedence-clause) 1))
              (raise (LeSyntaxError "Precedence must be a single numeric value."))
              (first precedence-clause)))
        None))

  (defn resolve-hy-code [bindings form]
    "Return Hy form that will return the value of form evaluated within the
     scope of variables in the given bindings dictionary."
    `(do
       (require hy.contrib.walk)
       (hy.contrib.walk.let [~@(reduce + (zip (map HySymbol (.keys bindings))
                                              (.values bindings)))]
         ~form)))

  (defn apply-func-to-args [func-sym args]
    "Return a sequence of Hy variable assignments that will re-assign each
     arg named in the args specification to the value produced by applying
     the func named by func-sym to that argument."
    (->> (:syms args)
         ;; For each arg, produce a Hy form that applies func to it.
         (map
           (fn [sym]
             (if
               ;; Map &rest with func.
               (= sym (:rest-sym args))
               `(list (map ~func-sym ~sym))
               ;; Map &kwargs values with func.
               (= sym (:kwargs-sym args))
               `(->> (.values ~sym)
                     (map ~func-sym)
                     (zip (.keys ~sym))
                     (dict))
               ;; Else, simply apply func to the arg.
               `(~func-sym ~sym))))
         ;; Create arg/form pairs
         (zip (:syms args))
         ;; Return a sequence of arg/form variable assignments.
         (map (fn [pair] `(setv ~(first pair) ~(second pair))))))

  (defn funcs-operator-definition [args clause-dict]
    "Given args specification and a clause-dict containing
     (latex OR latex-macro) AND (hy OR hy-macro) clauses,
     return a Hy form the builds a Lemma operator."
    (setv precedence (parse-precedence clause-dict))
    (setv latex-fn
          (if
            ;; Handle latex clause (where clause body should generate
            ;; operation latex representation given argument latex
            ;; values).
            (in 'latex clause-dict)
            `(fn ~(:arglist args)
               (import lemma.lang)
               (require lemma.core)
               ;; Apply gen-latex to each argument.
               ~@(apply-func-to-args 'lemma.lang.gen-latex args)
               ;; Return a LatexString from the value generated by the
               ;; clause body.
               (lemma.core.latexstr (do ~@(get clause-dict 'latex)) ~precedence))
            ;; Handle hy-macro clause (where clause body should
            ;; generate operation latex representation given raw
            ;; argument forms).
            (in 'latex-macro clause-dict)
            `(fn ~(:arglist args)
               ;; Return a LatexString from the value generated by the
               ;; clause body.
               (lemma.core.latexstr (do ~@(get clause-dict 'latex-macro)) ~precedence))
            ;; Else raise exception for missing clause.
            (raise (LeSyntaxError f"Missing latex clause for operator definition - please provide one of: {(.join \", \" (map name (:latex EXCLUSIVE-OPERATOR-CLAUSE-SETS)))}"))))
    (setv hy-fn
          (if
            ;; Handle hy clause (where clause body should generate
            ;; operation Hy code given argument Hy-code values).
            (in 'hy clause-dict)
            `(fn ~(:arglist args)
               (import lemma.lang)
               (import lemma.core)
               ;; Apply gen-hy to each argument.
               ~@(apply-func-to-args 'lemma.lang.gen-hy args)
               (lemma.core.resolve-hy-code
                 ~(:bindings args)
                 (quote (do ~@(get clause-dict 'hy)))))
            ;; Handle hy-macro clause (where clause body should
            ;; generate operation Hy code given raw argument forms).
            (in 'hy-macro clause-dict)
            `(fn ~(:arglist args)
               ~@(get clause-dict 'hy-macro))
            ;; Else raise exception for missing clause.
            (raise (LeSyntaxError f"Missing clause for hy definition - please provide one of: {(.join \", \" (map name (:hy EXCLUSIVE-OPERATOR-CLAUSE-SETS)))}"))))
    ;; An operator is callable only if it doesn't rely on consuming
    ;; raw forms/syntax.
    (setv operator-type
          (if (or (in 'latex-macro clause-dict)
                  (in 'hy-macro clause-dict))
              'lemma.lang.LeOperator
              'lemma.lang.LeCallableOperator))
    ;; Return the operator.
    `(~operator-type
       :latex-fn ~latex-fn
       :hy-fn ~hy-fn
       :arg-identifiers ~(:identifiers-or-vals-hy args)))

  (defn expr-operator-definition [args clause-dict]
    "Given args specification and a clause-dict containing
     an expr clause, return a Hy form the builds a Lemma operator."
    (let [body (last (get clause-dict 'expr))]
      `(do
         (require hy.contrib.walk)
         (require lemma.core)
         (import lemma.lang)
         (hy.contrib.walk.let [body-expr (lemma.core.expr ~body)]
           ;; An expression-based operator is callable, as it doesn't
           ;; rely on consuming raw forms/syntax.
           (lemma.lang.LeCallableOperator
             :latex-fn
             (fn ~(:arglist args)
               ;; Generate latex from body-expr with bound args.
               (lemma.core.latexstr
                 (lemma.lang.gen-latex (.bind body-expr ~(:bindings args)))
                 ~(parse-precedence clause-dict)))
             :hy-fn
             (fn ~(:arglist args)
               ;; Generate Hy from body-expr with bound args.
               (lemma.lang.gen-hy (.bind body-expr ~(:bindings args))))
             :arg-identifiers ~(:identifiers-or-vals-hy args)))))))

(defmacro def-operator [symbol arglist &rest parts]
  "Assign a Lemma operator to symbol, given the arglist (in the format of
   a Hy function argument list), an optional docstring, and a series of
   (name body) clauses in any order:

  * EITHER:
    * expr: A Lemma expression that can be evaluated with the specified
      arguments to produce the output of the operator.
    * OR specify clauses with Hy code to directly generate latex and hy
      code for the operator:
      * latex OR latex-macro: A Hy form that will generate the output operation
        latex using the given arguments. latex-macro will receive the raw
        argument Lemma forms instead of their resulting latex.
      * hy OR hy-macro: A Hy form that will generate the output operation Hy
        code using the given arguments. hy-macro will receive the raw argument
        Lemma forms instead of their resulting Hy code forms.
  * (OPTIONAL) precedence: Set the precedence of LatexStrings generated by this
    operator. If not set, default will be that of the generated LatexString or
    BASE-PRECEDENCE.
  * (OPTIONAL) example-args: one or more lists of argument values that will be
    used to demonstrate usage of the operator in auto-generated documentation."
  ;; Check symbol and args.
  (symbol-arg-check symbol "def-operator")
  (setv args (parse-arglist arglist))
  ;; Capture docstring
  (setv [doc clauses] (capture-docstring parts))
  ;; Check for unrecognised clauses.
  (for [clause clauses]
    (if-not (and (isinstance clause HyExpression)
                 (in (first clause) OPERATOR-CLAUSES))
            (raise (LeSyntaxError f"Unrecognised operator clause: {(hy-repr clause)}"))))
  ;; Check for duplicate clauses.
  (setv duplicate-clauses (->> (.items (Counter (map first clauses)))
                               (filter (fn [pair] (> (second pair) 1)))
                               (map (comp name first))
                               (list)))
  (if-not (empty? duplicate-clauses)
          (raise (LeSyntaxError f"Duplicate operator clauses: {(.join \", \" duplicate-clauses)}")))
  (setv clause-dict (dict (map (juxt first (comp list rest)) clauses)))
  ;; Check for disallowed combinations of exclusive clauses.
  (for [exclusive-clauses (.values EXCLUSIVE-OPERATOR-CLAUSE-SETS)]
    (let [clause-count (->> (.keys clause-dict)
                            (filter (fn [clause-name] (in clause-name exclusive-clauses)))
                            (list)
                            (len))]
      (when (> clause-count 1)
        (raise (LeSyntaxError f"Only one clause allowed of: {(.join \", \" (map name exclusive-clauses))}")))))
  ;; Get operator definition from either expr or hy/latex clauses.
  (setv operator-definition
        (if (in 'expr clause-dict)
            (expr-operator-definition args clause-dict)
            (funcs-operator-definition args clause-dict)))
  ;; Convert example-args to a list of lemma-form/lemma-expression Hy
  ;; form pairs that represent the application of the operator to each
  ;; example-args list.
  (setv example-expressions
        (if (in 'example-args clause-dict)
            (->> (get clause-dict 'example-args)
                 ;; Function application lemma form.
                 (map (fn [args] `(~symbol ~@args)))
                 ;; Pair lemma form syntax with its expression.
                 (map (fn [form] `['~form (lemma.core.expr ~form)]))
                 (list))
            []))
  `(do
     (import lemma.docmd)
     (require lemma.core)
     (setv ~symbol ~operator-definition)
     ;; Set name.
     (setv (. ~symbol name) (name '~symbol))
     ;; Set docstring.
     (if-not (none? ~doc)
             (setv (. ~symbol --doc--) ~doc))
     ;; Set _docmd.
     (setv (. ~symbol _docmd) (fn [] (lemma.docmd.operator-docmd ~symbol '~arglist
                                                                 ~example-expressions)))))
