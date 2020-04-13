(require [hy.contrib.walk [let]])
(import [typing [Any Union Callable Sequence Mapping]]
        [hy.models [HyObject HySymbol HyExpression HyList]]
        [hy.contrib.walk [postwalk]]
        [hy.contrib.hy-repr [hy-repr]]
        [lemma.exceptions [*]])

;; Types

(defclass LatexString [str]
  ;; See: https://stackoverflow.com/a/2673863
  (defn --new-- [cls ^str text ^(of Union int float) precedence]
    (let [str-obj (.--new-- str cls text)]
      (setv str-obj.precedence precedence)
      str-obj)))

(defclass HyCode []
  (defn --init-- [self form bindings]
    (setv self.form form)
    (setv self.bindings bindings))
  (defn run [self]
    (eval self.form self.bindings)))

(defclass LeSyntax []
  (defn --init-- [self]
    (setv self.name (str (hex (id self)))))
  (defn --repr-- [self]
    (+ self.--class--.--name-- "#" (str self.name))))

(defclass LeConstant [LeSyntax]
  (defn --init-- [self ^LatexString latex-val hy-val]
    (.--init-- (super))
    (setv self.latex-val latex-val)
    (setv self.hy-val hy-val))
  (defn latex [self]
    (gen-latex self))
  (defn hy [self]
    (gen-hy self))
  (defn --call-- [self]
    (eval (.hy self))))

(defclass LeIdentifier [LeConstant]
  (defn --init-- [self ^LatexString latex-val ^HySymbol hy-val]
    (.--init-- (super) latex-val hy-val)))

(defclass LeExpression [LeSyntax]
  (defn --init-- [self ^HyObject body]
    (.--init-- (super))
    (setv self.body body))
  (defn bind [self ^(of Mapping str Any) bindings]
    (LeExpression
      (postwalk
        (fn [form]
          (if
            (isinstance form HySymbol)
            (try
              (eval form bindings)
              (except [NameError]
                form))
            (isinstance form LeIdentifier)
            (try
              (eval form.hy-val bindings)
              (except [NameError]
                form))
            form))
        self.body)))
  (defn latex [self]
    (gen-latex self))
  (defn hy [self]
    (gen-hy self))
  (defn --call-- [self]
    (eval (.hy self)))
  (defn --repr-- [self]
    (+ "LeExpression#" (hy-repr self.body))))

(defclass LeOperator [LeSyntax]
  (defn --init-- [self ^Callable latex-fn ^Callable hy-fn]
    (.--init-- (super))
    (setv self.latex-fn latex-fn)
    (setv self.hy-fn hy-fn))
  (defn --call-- [self &rest args &kwargs kwargs]
    (eval (.hy-fn self #* args #** kwargs))))

(defclass LeFormula [LeOperator]
  (defn --init-- [self
                  ^Callable latex-fn
                  ^Callable expr-fn
                  ^str latex-name
                  ^(of Sequence HySymbol) arg-identifiers
                  ^(of Sequence keyword) arg-groups]
    (let [hy-fn (fn [&rest args &kwargs kwargs]
                  (gen-hy (expr-fn #* args #** kwargs)))]
      (.--init-- (super) latex-fn hy-fn))
    (setv self.body-latex
          (fn [&rest args &kwargs kwargs]
            (gen-latex (expr-fn #* args #** kwargs))))
    (setv self.expr-fn expr-fn)
    (setv self.latex-name latex-name)
    (setv self.arg-identifiers arg-identifiers)
    (setv self.arg-groups arg-groups))
  (defn signature-latex [self]
    (formula-signature-latex self.latex-name self.arg-groups self.arg-identifiers))
  (defn latex [self &rest args &kwargs kwargs]
    (let [body-latex (if (and (empty? args) (empty? kwargs))
                         (.body-latex self #* self.arg-identifiers)
                         (.body-latex self #* args #** kwargs))]
      (LatexString (+ (.signature-latex self) " = " body-latex) 0)))
  #@(property
      (defn op [self] LeOperator
        (let [operator (LeOperator self.body-latex self.hy-fn)]
          (setv operator.name (+ self.name ".op"))
          operator))))

(defclass LeEquation [LeSyntax]
  (defn --init-- [self ^Callable expressions-fn
                  ^(of Sequence HySymbol) arg-identifiers]
    (.--init-- (super))
    (setv self.expressions-fn expressions-fn)
    (setv self.arg-identifiers arg-identifiers))
  (defn latex [self &rest args &kwargs kwargs]
    (let [expressions (if (and (empty? args) (empty? kwargs))
                          (.expressions-fn self #* self.arg-identifiers)
                          (.expressions-fn self #* args #** kwargs))
          latexs (list (map gen-latex expressions))]
      (+ r"\begin{aligned} "
         (first latexs) " &= "
         (.join r" \\&= " (rest latexs))
         r"\end{aligned}")))
  (defn --call-- [self &rest args &kwargs kwargs]
    (let [expressions (list (.expressions-fn self #* args #** kwargs))
          results (list (map (comp eval gen-hy) expressions))
          first-result (first results)]
      (for [[result expression] (zip (rest results) (rest expressions))]
        (if-not (= result first-result)
                (raise (LeEquationError
                         (+ "While evaluating "
                            (repr self)
                            " with arguments ["
                            (.join ", "
                                   (+ (->> args
                                           (map str)
                                           list)
                                      (->> (.items kwargs)
                                           (map (fn [pair] (.join "=" (map str pair))))
                                           list)))
                            "]: result '"
                            (str result)
                            "' of "
                            (repr expression)
                            " did not equal result '"
                            (str first-result)
                            "' of "
                            (repr (first expressions)))))))
      first-result)))

(defn make-identifier [symbol &optional latex]
  (let [identifier (-> (if (none? latex) (name symbol) latex)
                       (LatexString 0)
                       (LeIdentifier symbol))]
    (setv identifier.name (name symbol))
    identifier))

(setv ARG-GROUP-KEYS #{:paren :super :sub})

(defn formula-signature-latex [latex-name arg-groups arg-identifiers]
  (setv arg-grouping-dict {:sub [] :super [] :paren []})
  (for [[arg group] (zip arg-identifiers arg-groups)]
    (.append (get arg-grouping-dict group)
             (gen-latex arg)))
  (let [sub-args (if (empty? (get arg-grouping-dict :sub))
                     ""
                     (+ "_{" (.join "," (get arg-grouping-dict :sub)) "}"))
        super-args (if (empty? (get arg-grouping-dict :super))
                       ""
                       (+ "^{" (.join "," (get arg-grouping-dict :super)) "}"))
        paren-args (if (empty? (get arg-grouping-dict :paren))
                       ""
                       (+ r"\left(" (.join "," (get arg-grouping-dict :paren)) r"\right)"))]
    (LatexString (+ latex-name sub-args super-args paren-args) 0)))

(defn validate-even-bindings! [caller bindings]
  (when (not (even? (len bindings)))
    (raise (LeSyntaxError f"An even number of bindings must be supplied to {caller}."))))

(defn operator-application? [form]
  (if (isinstance form HyExpression)
      (if (isinstance (first form) LeOperator)
          True
          (raise (LeSyntaxError f"Unrecognised LeOperator: {(first form)}")))
      False))

(defn tag-application? [form]
  (and (isinstance form HyExpression)
       (= (first form) 'dispatch-tag-macro)))

(defn listy? [form]
  (or (list? form) (isinstance form HyList)))

(defn latex-format-numeric [number]
  (str number))

(defn latex-enclose-arg
  [max-precedence arg-latex-string]
  (if (>= arg-latex-string.precedence max-precedence)
      (LatexString (+ r"\left(" arg-latex-string r"\right)") 0)
      arg-latex-string))

(defn split-args [args]
  (setv args (list args))
  (setv first-keyword-neg-index 0)
  (while True
    (let [next-index (- first-keyword-neg-index 2)]
      (if (and (<= (abs next-index) (len args))
            (isinstance (get args next-index) HyKeyword))
          (setv first-keyword-neg-index next-index)
          (break))))
  (if (= first-keyword-neg-index 0)
      {:args args
       :kwargs {}}
      {:args (-> args
                 (cut 0 first-keyword-neg-index)
                 list)
       :kwargs (as-> args $
                   (cut $ first-keyword-neg-index)
                   (partition $ 2)
                   (map (fn [pair] [(name (first pair)) (second pair)]) $)
                   (dict $))}))

(setv bare
      (LeOperator
        (fn [body] (LatexString (gen-latex body) 0))
        (fn [body] (gen-hy body))))
(setv bare.name "bare")

(setv parens
      (LeOperator
        (fn [body] (LatexString (+ r"\left(" (gen-latex body) r"\right)") 0))
        (fn [body] (gen-hy body))))
(setv parens.name "parens")

(defn resolve-tag-operator [tagname]
  (if (= tagname "p") parens
      (= tagname "b") bare
      (raise (LeSyntaxError (+ "Unrecognised tag operator for Lemma: " (str tagname))))))

;; Evaluators

(defn gen-latex [form]
  (try
    (cond
      [(isinstance form LeExpression) (gen-latex form.body)]
      [(tag-application? form)
       (gen-latex (LeExpression `(~(resolve-tag-operator (nth form 1)) ~(nth form 2))))]
      [(operator-application? form)
       (do
         (let [args (split-args (rest form))]
           (.latex-fn (first form) #* (:args args) #** (:kwargs args))))]
      [(isinstance form LeConstant) form.latex-val]
      [(numeric? form) (LatexString (latex-format-numeric form) 0)]
      [(symbol? form) (LatexString (str form) 0)]
      [(listy? form) (LatexString (+ "\{" (.join ", " (map gen-latex form)) "\}") 0 )]
      [True (raise (LeSyntaxError f"Cannot interpret lemma form {(hy-repr form)}"))])
    (except [ex Exception]
      (if-not (or (isinstance ex LeRuntimeError) (isinstance ex LeSyntaxError))
              (raise (LeRuntimeError f"Error generating latex for lemma form: {(hy-repr form)}") :from ex)
              (raise)))))

(defn gen-hy [form]
  (try
    (cond
      [(isinstance form LeExpression) (gen-hy form.body)]
      [(tag-application? form)
       (gen-hy (LeExpression `(~(resolve-tag-operator (nth form 1)) ~(nth form 2))))]
      [(operator-application? form)
       (let [args (split-args (rest form))]
         (.hy-fn (first form) #* (:args args) #** (:kwargs args)))]
      [(isinstance form LeConstant) form.hy-val]
      [(numeric? form) form]
      [(symbol? form) form]
      [(listy? form) (list (map gen-hy form))]
      [True (raise (LeSyntaxError f"Cannot interpret lemma form {(hy-repr form)}"))])
    (except [ex Exception]
      (if-not (or (isinstance ex LeRuntimeError) (isinstance ex LeSyntaxError))
              (raise (LeRuntimeError f"Error generating code for lemma form: {(hy-repr form)}") :from ex)
              (raise)))))
