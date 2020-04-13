(require [hy.contrib.walk [let]])
(import [hy.models [HyExpression HySymbol HyString HyInteger HyFloat]]
        [hy.contrib.walk [postwalk macroexpand-all]]
        [hy.contrib.hy-repr [hy-repr]]
        [lemma.exceptions [*]]
        [lemma.lang [ARG-GROUP-KEYS listy?]]
        [collections [Counter]])

(eval-and-compile

  (defn pair? [arg]
    (and (listy? arg) (= (len arg) 2)))

  (defn parse-arglist [arglist]
    (for [arg arglist]
      (if-not (or (isinstance arg HySymbol)
                  (and (pair? arg)
                       (isinstance (first arg) HySymbol))
                  (in arg ARG-GROUP-KEYS)
                  (and (isinstance arg HyExpression)
                       (= (first (arg)) (HySymbol "annotate*"))))
              (raise (LeSyntaxError f"Cannot parse argument: {arg}"))))
    (setv next-is-rest False)
    (setv next-is-kwargs False)
    (setv rest-sym None)
    (setv kwargs-sym None)
    (setv current-arg-group :paren)
    (setv sym-group-pairs [])
    (for [arg arglist]
      (if (in arg ARG-GROUP-KEYS)
        (setv current-arg-group arg)
        (let [single-arg (if (pair? arg) (first arg) arg)]
          (if (isinstance single-arg HySymbol)
              (if
                (= single-arg '&rest)
                (setv next-is-rest True)
                (= single-arg '&kwargs)
                (setv next-is-kwargs True)
                (not (.startswith (name single-arg) "&"))
                (do
                  (when next-is-rest
                    (setv rest-sym single-arg)
                    (setv next-is-rest False))
                  (when next-is-kwargs
                    (setv kwargs-sym single-arg)
                    (setv next-is-kwargs False))
                  (.append sym-group-pairs [single-arg current-arg-group])))))))
    (setv argsyms (list (map first sym-group-pairs)))
    {:syms argsyms
     :rest-sym rest-sym
     :kwargs-sym kwargs-sym
     :arglist (->> arglist
                   (remove (fn [arg] (in arg ARG-GROUP-KEYS)))
                   (map (fn [arg]
                          (if (pair? arg)
                              [(first arg) `(lemma.core.expr ~(second arg))]
                              arg)))
                   (list))
     :groups (->> sym-group-pairs
                  (map second)
                  (list))
     :identifiers (->> argsyms
                       (map (fn [sym]
                              `(try
                                 (eval '~sym)
                                 (except [NameError]
                                   (lemma.lang.make-identifier '~sym)))))
                       (list))
     :bindings (->> argsyms
                    (map (juxt name identity))
                    dict)})

  (defn symbol-arg-check [symbol calling-macro-name]
    (if-not (isinstance symbol str)
            (raise (LeSyntaxError f"The first argument to {calling-macro-name} must be a symbol."))))

  (defn capture-docstring [parts]
    (if (isinstance (first parts) HyString)
        (, (first parts) (list (rest parts)))
        (, None parts))))

(defmacro/g! latexstr [latex &optional [precedence None]]
  `(do
     (require hy.contrib.walk)
     (import lemma.lang)
     (hy.contrib.walk.let [~g!latex-val ~latex]
       (if (and (isinstance ~g!latex-val lemma.lang.LatexString)
                (none? ~precedence))
           ~g!latex-val
           (lemma.lang.LatexString ~g!latex-val
                                   (if (none? ~precedence)
                                       0
                                       ~precedence))))))

(defmacro expr [form]
  `(do
     (import lemma.lang)
     (.bind (lemma.lang.LeExpression '~form) (globals))))

(defmacro def-identifier [symbol latex &optional doc]
  (symbol-arg-check symbol "def-identifier")
  `(do
     (import lemma.lang)
     (setv ~symbol (lemma.lang.make-identifier '~symbol ~latex))
     (if-not (none? ~doc)
             (setv (. ~symbol --doc--) ~doc))))

(defmacro def-constant [symbol latex value &optional doc]
  (symbol-arg-check symbol "def-constant")
  `(do
     (require lemma.core)
     (import lemma.lang)
     (setv ~symbol (lemma.lang.LeConstant (lemma.core.latexstr ~latex) ~value))
     (setv (. ~symbol name) (name '~symbol))
     (if-not (none? ~doc)
             (setv (. ~symbol --doc--) ~doc))))

(defmacro def-formula [symbol latex-name arglist &rest parts]
  (symbol-arg-check symbol "def-formula")
  (if-not (isinstance latex-name str)
          (raise (LeSyntaxError "The name of an equation must be a LatexString or string.")))
  (setv [doc parts] (capture-docstring parts))
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
                 (fn ~(:arglist args)
                   (lemma.lang.formula-signature-latex
                     ~latex-name ~(:groups args) ~(:identifiers args)))
                 (fn ~(:arglist args)
                   (.bind body-expr ~(:bindings args)))
                 ~latex-name ~(:identifiers args) ~(:groups args))))
       (if-not (none? ~doc)
               (setv (. ~symbol --doc--) ~doc))
       (setv (. ~symbol name) (name '~symbol)))))

(defmacro/g! equation [arglist &rest parts]
  (setv [doc parts] (capture-docstring parts))
  (if-not (and (= (len parts) 1)
               (isinstance (first parts) HyList))
          (raise (LeSyntaxError "The body of an equation must be a list of Lemma forms.")))
  (let [expr-bodies (first parts)
        args (parse-arglist arglist)
        expressions (->> expr-bodies
                         (map (fn [body] `(lemma.core.expr ~body)))
                         (list))]
    `(do
       (require hy.contrib.walk)
       (require lemma.core)
       (import lemma.lang)
       (hy.contrib.walk.let
         [~g!expressions ~expressions
          ~g!equation (lemma.lang.LeEquation
                        (fn ~(:arglist args)
                          (map (fn [expr] (.bind expr ~(:bindings args))) ~g!expressions))
                        ~(:identifiers args))]
         (if-not (none? ~doc)
                 (setv (. ~g!equation --doc--) ~doc))
         ~g!equation))))

(defmacro def-equation [symbol &rest args]
  (if (not (isinstance symbol HySymbol))
      (raise (LeSyntaxError "The first argument to def-equation must be a symbol.")))
  `(do
     (require lemma.core)
     (setv ~symbol (lemma.core.equation ~@args))
     (setv (. ~symbol name) (name '~symbol))))

(setv OPERATOR-CLAUSES #{'expr 'latex 'latex-macro 'hy 'hy-macro 'precedence})
(setv EXCLUSIVE-OPERATOR-CLAUSE-SETS
      {:latex #{'expr 'latex 'latex-macro}
       :hy #{'expr 'hy 'hy-macro}})

(eval-and-compile

  (defn parse-precedence [clause-dict]
    (if (in 'precedence clause-dict)
        (let [precedence-clause (get clause-dict 'precedence)]
          (if (and (= (len precedence-clause) 1)
                   (or (isinstance (first precedence-clause) HyFloat)
                       (isinstance (first precedence-clause) HyInteger)))
              (eval (first precedence-clause))
              (raise (LeSyntaxError "Precedence must be a single numeric value."))))
        None))

  (defn resolve-hy-code [bindings form]
    `(do
       (require hy.contrib.walk)
       (hy.contrib.walk.let [~@(reduce + (zip (map HySymbol (.keys bindings))
                                              (.values bindings)))]
         ~form)))

  (defn apply-func-to-args [func-sym args]
    (->> (:syms args)
         (map
           (fn [sym]
             (if
               (= sym (:rest-sym args))
               `(list (map ~func-sym ~sym))
               (= sym (:kwargs-sym args))
               `(->> (.values ~sym)
                     (map ~func-sym)
                     (zip (.keys ~sym))
                     (dict))
               ;; else
               `(~func-sym ~sym))))
         (zip (:syms args))
         (map (fn [pair] `(setv ~(first pair) ~(second pair))))))

  (defn funcs-operator-definition [args clause-dict]
    (setv precedence (parse-precedence clause-dict))
    (setv latex-fn
          (if (in 'latex clause-dict)
              `(fn ~(:arglist args)
                 (import lemma.lang)
                 (require lemma.core)
                 ~@(apply-func-to-args 'lemma.lang.gen-latex args)
                 (lemma.core.latexstr (do ~@(get clause-dict 'latex)) ~precedence))
              (in 'latex-macro clause-dict)
              `(fn ~(:arglist args)
                 (lemma.core.latexstr (do ~@(get clause-dict 'latex-macro)) ~precedence))
              (raise (LeSyntaxError f"Missing latex clause for operator definition - please provide one of: {(.join \", \" (map name (:latex EXCLUSIVE-OPERATOR-CLAUSE-SETS)))}"))))
    (setv hy-fn
          (if (in 'hy clause-dict)
              `(fn ~(:arglist args)
                 (import lemma.lang)
                 (import lemma.core)
                 ~@(apply-func-to-args 'lemma.lang.gen-hy args)
                 (lemma.core.resolve-hy-code
                   ~(:bindings args)
                   (quote (do ~@(get clause-dict 'hy)))))
              (in 'hy-macro clause-dict)
              `(fn ~(:arglist args)
                 ~@(get clause-dict 'hy-macro))
              (raise (LeSyntaxError f"Missing clause for hy definition - please provide one of: {(.join \", \" (map name (:hy EXCLUSIVE-OPERATOR-CLAUSE-SETS)))}"))))
    `(lemma.lang.LeOperator ~latex-fn ~hy-fn))

  (defn expr-operator-definition [args clause-dict]
    (let [body (last (get clause-dict 'expr))
          precedence (parse-precedence clause-dict)]
      `(do
         (require hy.contrib.walk)
         (require lemma.core)
         (import lemma.lang)
         (hy.contrib.walk.let [body-expr (lemma.core.expr ~body)]
           (lemma.lang.LeOperator
             (fn ~(:arglist args)
               (lemma.core.latexstr
                 (lemma.lang.gen-latex (.bind body-expr ~(:bindings args)))
                 ~precedence))
             (fn ~(:arglist args)
               (lemma.lang.gen-hy (.bind body-expr ~(:bindings args))))))))))

(defmacro def-operator [symbol arglist &rest parts]
  (symbol-arg-check symbol "def-operator")
  (setv [doc clauses] (capture-docstring parts))
  (setv args (parse-arglist arglist))
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
  ;; Check for disallowed combinations of clauses.
  (for [exclusive-clauses (.values EXCLUSIVE-OPERATOR-CLAUSE-SETS)]
    (let [clause-count (->> (.keys clause-dict)
                            (filter (fn [clause-name] (in clause-name exclusive-clauses)))
                            (list)
                            (len))]
      (when (> clause-count 1)
        (raise (LeSyntaxError f"Only one clause allowed of: {(.join \", \" (map name exclusive-clauses))}")))))
  (setv operator-definition
        (if (in 'expr clause-dict)
            (expr-operator-definition args clause-dict)
            (funcs-operator-definition args clause-dict)))
  `(do
     (setv ~symbol ~operator-definition)
     (if-not (none? ~doc)
             (setv (. ~symbol --doc--) ~doc))
     (setv (. ~symbol name) (name '~symbol))))
