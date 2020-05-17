"Exception types that can be raised by Lemma."

(defclass LeError [Exception]
  "Base exception type for all errors raised by Lemma.")

(defclass LeRuntimeError [LeError]
  "Raised when an exception was raised while generating LaTeX or Hy for a
   Lemma expression. Wraps the original exception.")

(defclass LeSyntaxError [LeError]
  "Raised when a form cannot be interpreted as a Lemma expression.")

(defclass LeEquationError [LeError]
  "Raised when two steps in an equation return different results")
