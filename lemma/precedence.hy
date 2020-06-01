"This module defines the relative levels of precedence for LaTeX
strings that may be generated by Lemma forms."

;; Lowest level of precedence, never needs to be wrapped in
;; parentheses. Applies to e.g. paren-wrapped expressions,
;; identifiers.
(setv BASE-PRECEDENCE 0)

;; Applies to numeric values (e.g. 1, 1.4, -5).
(setv NUMERIC-PRECEDENCE 100)

;; Unary operators (e.g. roots, floor, ceil).
(setv UNARY-OP-PRECEDENCE 200)

;; Expressions with an exponent.
(setv EXPONENT-PRECEDENCE 300)

;; Fractions, as formatted with `\frac`.
(setv FRACTION-PRECEDENCE 400)

;; Multiplication by juxtaposition (e.g. `xy`).
(setv JUXT-PRECEDENCE 500)

;; Function calls (e.g. `max(0, 1)`).
(setv FUNCTION-CALL-PRECEDENCE 600)

;; Binary operators. Distinction between the precedences of
;; addition+subtraction and multiplication+division is not made, as
;; dependence on precedences is considered to reduce readability.
(setv BINARY-OP-PRECEDENCE 700)

;; Summation/product precedences (e.g. Big sigma, Big Pi).
(setv SUMMATION-PRECEDENCE 800)

;; Equations/assignments formatted as an `=` binary operation.
(setv EQUATION-PRECEDENCE 1000)

;; Defines the maximum known precedence.
(setv MAX-PRECEDENCE 10_000)
