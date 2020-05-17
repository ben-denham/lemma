"Constants defining relative levels of precedence for LatexStrings."

;; Lowest level of precedence, never needs to be wrapped in
;; parentheses. Applies to e.g. paren-wrapped expressions,
;; identifiers, numbers.
(setv BASE-PRECEDENCE 0)

;; Unary operators (e.g. roots, floor, ceil).
(setv UNARY-OP-PRECEDENCE 100)

;; Expressions with an exponent.
(setv EXPONENT-PRECEDENCE 200)

;; Fractions, as formatted with `\frac`.
(setv FRACTION-PRECEDENCE 300)

;; Multiplication by juxtaposition (e.g. `xy`).
(setv JUXT-PRECEDENCE 400)

;; Function calls (e.g. `max(0, 1)`).
(setv FUNCTION-CALL-PRECEDENCE 500)

;; Binary operators. Distinction between the precedences of
;; addition+subtraction and multiplication+division is not made, as
;; dependence on precedences is considered to reduce readability.
(setv BINARY-OP-PRECEDENCE 600)

;; Summation/product precedences (e.g. Big sigma, Big Pi).
(setv SUMMATION-PRECEDENCE 700)

;; Equations/assignments formatted as an `=` binary operation.
(setv EQUATION-PRECEDENCE 1000)

;; Defines the maximum known precedence.
(setv MAX-PRECEDENCE EQUATION-PRECEDENCE)
