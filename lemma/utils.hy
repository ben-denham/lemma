"Utility functions that are helpful when constructing your own Lemma
operators with `lemma.core.def-operator`."

(import [lemma.lang [gen-hy gen-latex latex-enclose-arg]]
        [lemma.exceptions [LeSyntaxError]])

(defn validate-even-bindings! [caller bindings]
  "Raises a `LeSyntaxError` if the given `bindings` sequence does not have
  an even length. Formats the exception with the given name of the `caller`."
  (when (not (even? (len bindings)))
    (raise (LeSyntaxError f"An even number of bindings must be supplied to {caller}."))))
