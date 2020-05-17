"Utilities that are helpful when extending the notation of Lemma."

(import [lemma.lang [LatexString gen-hy gen-latex]]
        [lemma.exceptions [LeSyntaxError]])

(defn latex-enclose-arg [precedence-limit arg-latex-string]
  "If `LatexString` `arg-latex-string` has a precedence greater than or
  equal to `precedence-limit`, then returns `arg-latex-string` wrapped
  in parentheses, otherwise returns `arg-latex-string`."
  (if (>= arg-latex-string.precedence precedence-limit)
      (LatexString (+ r"\left(" arg-latex-string r"\right)") 0)
      arg-latex-string))

(defn validate-even-bindings! [caller bindings]
  "Raises a `LeSyntaxError` if the given `bindings` sequence does not have
  an even length. Formats the exception with the given name of the `caller`."
  (when (not (even? (len bindings)))
    (raise (LeSyntaxError f"An even number of bindings must be supplied to {caller}."))))
