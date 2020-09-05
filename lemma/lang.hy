"Internal implementation of Lemma language."

(require [hy.contrib.walk [let]])
(import [functools [partial]]
        [typing [Any Union Callable Sequence Mapping]]
        [hy.models [HyObject HySymbol HyExpression HyList]]
        [hy.contrib.walk [postwalk]]
        [hy.contrib.hy-repr [hy-repr]]
        ;; Explicitly load shadow operators, otherwise they will not
        ;; always be loaded into globals before (eval) is called.
        [hy.core.shadow [*]]
        [lemma.exceptions [*]]
        [lemma.precedence [*]])

;; Dereference `-` to trigger globals "magic" that allows - to be
;; looked up within calls to eval.
(setv minus -)

;; Types

(defclass LatexString [str]
  "Represents a string of LaTeX maths code, with a precedence that
   determines whether it should be wrapped with parentheses in
   certain operations."
  ;; See: https://stackoverflow.com/a/2673863
  (defn --new-- [cls ^str text ^(of Union int float) precedence]
    (let [str-obj (.--new-- str cls text)]
      (setv str-obj.precedence precedence)
      str-obj)))

(defclass LeSyntax []
  "Base class for all Lemma syntax objects."
  (defn --init-- [self]
    (setv self.name (str (hex (id self)))))
  (defn --repr-- [self]
    (+ self.--class--.--name-- "#" (str self.name))))

(defclass LeConstant [LeSyntax]
  "Lemma syntax object for a constant represented by a
   fixed `LatexString` and Hy value."
  (defn --init-- [self ^LatexString latex-val hy-val]
    (.--init-- (super))
    (setv self.latex-val latex-val)
    (setv self.hy-val hy-val))
  (defn latex [self] LatexString
    "Return a `LatexString` representing the constant."
    (gen-latex self))
  (defn hy [self]
    "Return Hy code representing the constant."
    (gen-hy self))
  (defn --call-- [self]
    "Evaluate and return the constant's Hy value."
    (eval (.hy self))))

(defclass LeIdentifier [LeConstant]
  "Lemma syntax object for a Hy symbol with
   associated LaTeX notation."
  (defn --init-- [self ^LatexString latex-val ^HySymbol hy-val]
    (.--init-- (super) latex-val hy-val)))

(defclass LeExpression [LeSyntax]
  "Lemma syntax object for a complete form of Lemma syntax."
  (defn --init-- [self ^HyObject body]
    (.--init-- (super))
    (setv self.body body))
  (defn bind [self ^(of Mapping str Any) bindings] LeExpression
    "Replace symbols and identifiers in the expression's
     body form with objects in bindings (a mapping of
     symbol/identifier names to replacement objects)."
    (LeExpression
      (postwalk
        (fn [subform]
          (if
            ;; Attempt to evaluate symbol's in the
            ;; context of the bindings.
            (isinstance subform HySymbol)
            (try
              (eval subform bindings)
              (except [NameError]
                subform))
            ;; Attempt to evaluate identifier's symbol
            ;; in the context of the bindings.
            (isinstance subform LeIdentifier)
            (try
              (eval (.hy subform) bindings)
              (except [NameError]
                subform))
            subform))
        self.body)))
  (defn latex [self] LatexString
    "Return a `LatexString` representing the expression."
    (gen-latex self))
  (defn hy [self]
    "Return a Hy form representing the expression."
    (gen-hy self))
  (defn --call-- [self]
    "Evaluate and return the expression's Hy value."
    (eval (.hy self)))
  (defn --repr-- [self]
    (+ "LeExpression#" (.lstrip (hy-repr self.body) "'"))))

(defclass LeOperator [LeSyntax]
  "Lemma syntax object for an operation that accepts arguments and can be
   formatted as a `LatexString` or Hy code."
  (defn --init-- [self
                  ^Callable latex-fn
                  ^Callable hy-fn
                  ^(of Sequence HySymbol) arg-identifiers]
    (.--init-- (super))
    (setv self.latex-fn latex-fn)
    (setv self.hy-fn hy-fn)
    (setv self.arg-identifiers arg-identifiers)))

(defclass LeCallableOperator [LeOperator]
  "A callable operator can be used directly (outside of a Lemma
   form/expression), because it's arguments can be passed by value (they don't
   have to be passed as raw forms/syntax)."
  (defn latex [self &rest args &kwargs kwargs] LatexString
    "Return a `LatexString` representing the operator applied to the given args."
    (.latex self #* args #** kwargs))
  (defn hy [self &rest args &kwargs kwargs]
    "Return a Hy form representing the operator applied to the given args."""
    (.hy-fn self #* args #** kwargs))
  (defn --call-- [self &rest args &kwargs kwargs]
    "Apply operator to given arguments and return the evaluated Hy value."
    (eval (.hy self #* args #** kwargs))))

(defclass LeFormula [LeCallableOperator]
  "Lemma syntax object that acts as an operator by evaluating a Lemma
   expression with provided arguments, but is formatted in LaTeX as a
   function-call/signature, instead of the full expression of its body
   expression."
  (defn --init-- [self
                  ^Callable latex-fn
                  ^Callable expr-fn
                  ^(of Sequence HySymbol) arg-identifiers]
    ;; Supply args for LeOperator constructor.
    (.--init-- (super)
               :latex-fn latex-fn
               :hy-fn
               (fn [&rest args &kwargs kwargs]
                 (gen-hy (expr-fn #* args #** kwargs)))
               :arg-identifiers arg-identifiers)
    (setv self.expr-fn expr-fn))
  (defn body-latex [self &rest args &kwargs kwargs] LatexString
    "Return a `LatexString` representing the body of this
     Formula using the given args.
     If no args are supplied, format with parameter names."
    (if (and (empty? args) (empty? kwargs))
        (gen-latex (.expr-fn self #* self.arg-identifiers))
        (gen-latex (.expr-fn self #* args #** kwargs))))
  (defn signature-latex [self &rest args &kwargs kwargs] LatexString
    "Return a `LatexString` representing the signature of this
     Formula using the given args.
     If no args are supplied, format with parameter names."
    (if (and (empty? args) (empty? kwargs))
        (.latex-fn self #* self.arg-identifiers)
        (.latex-fn self #* args #** kwargs)))
  (defn latex [self &rest args &kwargs kwargs] LatexString
    "Return a `LatexString` representing the equation of this Formula's
     signature to it's body using the given args.
     If no args are supplied, format with parameter names."
    (LatexString (+ (.signature-latex self #* args #** kwargs) " = "
                    (.body-latex self #* args #** kwargs))
                 EQUATION-PRECEDENCE))
  #@(property
      (defn op [self] LeCallableOperator
        "Return a simple operator represented by the body expression
         of this formula."
        (let [operator (LeCallableOperator self.body-latex self.hy-fn self.arg-identifiers)]
          (setv operator.name (+ self.name ".op"))
          operator))))

(defclass LeEquation [LeCallableOperator]
  "Lemma syntax object that acts as an operator representing a set of equivalent
   expressions that can be evaluated with the same arguments. Formatted in LaTeX
   expressions as the first expression, and can be formatted as a series of
   equation steps in LaTeX. Raises an exception when evaluated if any
   of the expressions produce different results."
  (defn --init-- [self ^Callable expressions-fn
                  ^(of Sequence HySymbol) arg-identifiers]
    ;; Supply latex-fn and hy-fn for LeOperator constructor.
    (.--init--
      (super)
      :latex-fn ;; Format equation as the first expression.
      (fn [&rest args &kwargs kwargs]
        (->> (expressions-fn #* args #** kwargs)
             (first)
             (gen-latex)))
      :hy-fn ;; Hy code that will raise an exception if any
             ;; expressions produce different results.
      (fn [&rest args &kwargs kwargs]
        (let [expressions (list (expressions-fn #* args #** kwargs))
              hy-expressions (list (map gen-hy expressions))
              argrepr (.join ", "
                             (+ (->> args
                                     (map str)
                                     list)
                                (->> (.items kwargs)
                                     (map (fn [pair] (.join "=" (map str pair))))
                                     list)))
              ;; Gensyms for hy-code.
              g/exp-reprs (gensym "exp-reprs")
              g/exp-repr (gensym "exp-repr")
              g/exp-results (gensym "exp-results")
              g/exp-result (gensym "exp-result")]
          `(do
             (import lemma.exceptions)
             (let [~g/exp-reprs ~(list (map repr expressions))
                   ~g/exp-results (list (map eval ~hy-expressions))]
               (for [[~g/exp-result ~g/exp-repr] (zip (rest ~g/exp-results) (rest ~g/exp-reprs))]
                 ;; Raise LeEquationError if any expressions produce
                 ;; different results.
                 (if-not (= ~g/exp-result (first ~g/exp-results))
                         (raise (lemma.exceptions.LeEquationError
                                  (+ "While evaluating " ~(repr self)
                                     " with arguments [" ~argrepr
                                     "]: result '" (str ~g/exp-result)
                                     "' of " ~g/exp-repr
                                     " did not equal result '" (str (first ~g/exp-results))
                                     "' of " ~g/exp-repr)))))
               ;; Return the first result.
               (first ~g/exp-results)))))
      :arg-identifiers arg-identifiers)
    (setv self.expressions-fn expressions-fn))
  (defn latex [self &rest args &kwargs kwargs] LatexString
    "Return a `LatexString` representing this equation evaluated with the given
     args. If no args are supplied, format with parameter names."
    (let [expressions (if (and (empty? args) (empty? kwargs))
                          (.expressions-fn self #* self.arg-identifiers)
                          (.expressions-fn self #* args #** kwargs))
          latexs (->> expressions
                      (map gen-latex)
                      (map (partial latex-enclose-arg EQUATION-PRECEDENCE))
                      (list))]
      (LatexString (+ r"\begin{aligned} "
                      (first latexs)
                      (if (> (len latexs) 1) " &= " "")
                      (.join r" \\&= " (rest latexs))
                      r"\end{aligned}")
                   EQUATION-PRECEDENCE))))

;; Helper functions

(defn make-latex-string [latex &optional [precedence None]]
  "Return a LatexString for the given latex (str or another
   LatexString), with an optionally set precedence."
  (if (and (isinstance latex LatexString)
           (none? precedence))
      latex
      (LatexString latex (if (none? precedence)
                             BASE-PRECEDENCE
                             precedence))))

(defn latex-enclose-arg [precedence-limit arg-latex-string]
  "If `LatexString` `arg-latex-string` has a precedence greater than or
  equal to `precedence-limit`, then returns `arg-latex-string` wrapped
  in parentheses, otherwise returns `arg-latex-string`."
  (if (>= arg-latex-string.precedence precedence-limit)
      (LatexString (+ r"\left(" arg-latex-string r"\right)") 0)
      arg-latex-string))

(defn make-identifier [symbol &optional latex]
  "Helper function to make a Lemma identifier that formats the given
   symbol with the given `LatexString` latex."
  (let [identifier (-> (if (none? latex) (name symbol) latex)
                       (LatexString BASE-PRECEDENCE)
                       (LeIdentifier symbol))]
    (setv identifier.name (name symbol))
    identifier))

(defn operator-application? [form]
  "Return true if the given form is the application of a `LeOperator`
   e.g. `(add 1 2)`."
  (if (isinstance form HyExpression)
      ;; If attempting to apply something that isn't an operator,
      ;; raise a LeSyntaxError.
      (if (isinstance (first form) LeOperator)
          True
          (raise (LeSyntaxError f"Unrecognised LeOperator: {(first form)}")))
      False))

(defn tag-application? [form]
  "Return true if the given form is the application of a tag macro."
  (and (isinstance form HyExpression)
       (= (first form) 'dispatch-tag-macro)))

(defn listy? [form]
  "Return true if the form is a list-like object."
  (or (list? form)
      (tuple? form)
      (isinstance form HyList)))

(defn latex-format-numeric [number]
  "Return a LatexString representing the given number."
  (LatexString (str number) NUMERIC-PRECEDENCE))

(defn split-args [op args]
  "Given the raw (i.e. syntax) of the arguments for a Lemma operator,
   divide them into args and kwargs."
  (setv args (list args))
  (setv argnames (->> op.arg-identifiers
                      (map gen-hy)
                      (map name)
                      (set)))
  (setv first-keyword-neg-index 0)
  ;; Search for the first keyword name in args, and return its
  ;; negative index (e.g. -1 is the negative index of the last item in
  ;; args).
  (while True
    ;; Search backwards in steps of 2, so that we don't check argument
    ;; values that happen to be keywords.
    (let [next-index (- first-keyword-neg-index 2)]
      (if (and
            ;; Not exceeded args length? ...
            (<= (abs next-index) (len args))
            ;; Is a keyword? ...
            (isinstance (get args next-index) HyKeyword)
            ;; Is an argument for the given op? ...
            (in (name (get args next-index)) argnames))
          ;; ...Then it's a keyword!
          (setv first-keyword-neg-index next-index)
          ;; Else there can't be any more keywords.
          (break))))
  (if (= first-keyword-neg-index 0)
      ;; If no keywords found, just return the list of args.
      {:args args
       :kwargs {}}
      {;; Format args as a list.
       :args (-> args
                 (cut 0 first-keyword-neg-index)
                 list)
       ;; Format kwargs as a dict.
       :kwargs (as-> args $
                   (cut $ first-keyword-neg-index)
                   (partition $ 2)
                   (map (fn [pair] [(name (first pair)) (second pair)]) $)
                   (dict $))}))

;; Tag Operators

;; Explicitly prevent parens around the body.
(setv bare
      (LeOperator
        (fn [body] (LatexString (gen-latex body) BASE-PRECEDENCE))
        (fn [body] (gen-hy body))
        ['body]))
(setv bare.name "bare")

;; Explicitly add parens around the body.
(setv parens
      (LeOperator
        (fn [body] (LatexString (+ r"\left(" (gen-latex body) r"\right)")
                                BASE-PRECEDENCE))
        (fn [body] (gen-hy body))
        ['body]))
(setv parens.name "parens")

(defn resolve-tag-operator [tagname]
  "Used to resolve built-in tag operators supported by the Lemma syntax."
  (if (= tagname "p") parens
      (= tagname "b") bare
      (raise (LeSyntaxError (+ "Unrecognised tag operator for Lemma: " (str tagname))))))

;; Evaluators

(defn gen-latex [form]
  "Takes a Lemma form of Hy data structures and Lemma objects and returns
  an executable Hy representation. Raises `LeSyntaxError` if the form
  cannot be interpreted as a Lemma form, and raises `LeRuntimeError` if
  an exception was raised while generating the Hy code."
  (try
    (cond
      [(isinstance form LeExpression) (gen-latex form.body)]
      [(tag-application? form)
       (gen-latex (LeExpression `(~(resolve-tag-operator (nth form 1)) ~(nth form 2))))]
      [(operator-application? form)
       (let [op (first form)
             args (split-args op (rest form))]
         (.latex-fn op #* (:args args) #** (:kwargs args)))]
      [(isinstance form LeConstant) form.latex-val]
      [(numeric? form) (latex-format-numeric form)]
      [(symbol? form) (LatexString (str form) BASE-PRECEDENCE)]
      [(listy? form) (LatexString (+ "\{" (.join ", " (map gen-latex form)) "\}")
                                  BASE-PRECEDENCE)]
      [True (raise (LeSyntaxError f"Cannot interpret lemma form {(hy-repr form)}"))])
    (except [ex Exception]
      (if-not (or (isinstance ex LeRuntimeError) (isinstance ex LeSyntaxError))
              (raise (LeRuntimeError f"Error generating latex for lemma form: {(hy-repr form)}") :from ex)
              (raise)))))

(defn gen-hy [form]
  "Takes a Lemma form of Hy data structures and Lemma objects and returns
  a `LatexString` representation. Raises `LeSyntaxError` if the form
  cannot be interpreted as a Lemma form, and raises `LeRuntimeError` if
  an exception was raised while generating the LaTeX."
  (try
    (cond
      [(isinstance form LeExpression) (gen-hy form.body)]
      [(tag-application? form)
       (gen-hy (LeExpression `(~(resolve-tag-operator (nth form 1)) ~(nth form 2))))]
      [(operator-application? form)
       (let [op (first form)
             args (split-args op (rest form))]
         (.hy-fn op #* (:args args) #** (:kwargs args)))]
      [(isinstance form LeConstant) form.hy-val]
      [(numeric? form) form]
      [(symbol? form) form]
      [(listy? form) (list (map gen-hy form))]
      [True (raise (LeSyntaxError f"Cannot interpret lemma form {(hy-repr form)}"))])
    (except [ex Exception]
      (if-not (or (isinstance ex LeRuntimeError) (isinstance ex LeSyntaxError))
              (raise (LeRuntimeError f"Error generating code for lemma form: {(hy-repr form)}") :from ex)
              (raise)))))
