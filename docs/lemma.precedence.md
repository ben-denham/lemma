# lemma.precedence

<style>
table {
}
</style>

Constants defining relative levels of precedence for Lemma operators.

| Precedence level | Purpose |
| - | - |
| <nobr>BASE-PRECEDENCE</nobr> | Lowest level of precedence, never needs to be wrapped in parentheses. Applies to e.g. paren-wrapped expressions, identifiers, numbers. |
| <nobr>UNARY-OP-PRECEDENCE</nobr> | Unary operators (e.g. powers, roots). |
| <nobr>FRACTION-PRECEDENCE</nobr> | Fractions, as formatted with `\frac`. |
| <nobr>FUNCTION-CALL-PRECEDENCE</nobr> | Function calls (e.g. `max(0, 1)`). |
| <nobr>JUXT-PRECEDENCE</nobr> | Multiplication by juxtaposition (e.g. `xy`). |
| <nobr>BINARY-OP-PRECEDENCE</nobr> | Binary operators. Distinction between the precedences of addition+subtraction and multiplication+division is not made, as dependence on precedences is considered to reduce readability. |
| <nobr>SUMMATION-PRECEDENCE</nobr> | Summation/product precedences (e.g. Big sigma, Big Pi). |
| <nobr>EQUATION-PRECEDENCE</nobr> | Equations/assignments formatted as an `=` binary operation. |
| <nobr>MAX-PRECEDENCE</nobr> | Defines the maximum known precedence. |
