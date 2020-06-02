# lemma.core

`lemma.core` contains the fundamental building blocks for expressing
your computations with Lemma.

Each section below provides API documentation for each type of object
in the Lemma language, including the operations they support and how
to construct objects.

In the example code, we assume you have required `lemma.core` as `le`,
and we also use operators defined in `lemma.domain.algebra` for
examples:

``` scheme
(require [lemma.core :as le])
(import [lemma.domain.algebra [*])
```

**Note:** Many of the code examples in this document use the raw
string (`r"hello"`) format for strings containing LaTeX. Using the raw
string syntax is generally recommended for LaTeX strings, as it
prevents the backslashes in LaTeX syntax from being interpreted by
Hy/Python as escape sequences.

## Lemma Forms

Many of the descriptions of Lemma types in this document refer to
*Lemma forms*. A Lemma form is simply a piece of valid Lemma syntax. A
form can be any of the following:

| Form | Examples |
| - | - |
| A numeric value | `1`, `-100`, `3.14` |
| The application of a Lemma operator (including tag operators, formulas, and equations)\* | `(add 1 2)` |
| A Lemma expression | See documentation below |
| A Lemma constant or identifier | See documentation below |
| A list/sequence of forms | `[1 2 3]`, `{(add 1 2) (add 3 4)}` |
| A variable that will reference a form\*\* | `(setv x 1) x` |

\* Operator arguments may be forms or other values, depending on the
operator.
\
\*\* Resolution of constants, identifiers, variables, and operators
within Lemma forms will only look at definitions in the global
scope. Therefore, you should only define Lemma objects that you intend
to reference within Lemma forms at top-level of a file (i.e. not
nested inside functions or classes).


## Expressions

Expressions are the simplest means of expressing computations with
Lemma. You can define a computation with an expression, then format it
as LaTeX and evaluate it to find the resulting value. You can create
an expression by wrapping any Lemma form with the `expr` macro.

For example, you can assign an expression to a variable:

``` scheme
;; (le.expr FORM)
(setv myexpr (le.expr (add 1 2)))
```

You can generate a LaTeX representation for an expression using the
`.latex` method:

``` scheme
(.latex myexpr) ;; => "1 + 2"
;; Or in Python: myexpr.latex()
```

You can evaluate the expression and get the resulting value by calling
it as a function:

``` scheme
(myexpr) ;; => 3
;; Or in Python: myexpr()
```

You can even use the `.hy` method to get the raw Hy code that is
evaluated when evaluating the expression:

``` scheme
(.hy myexpr) ;; => '(+ 1 2)
;; Or in Python: myexpr.hy()
```

For advanced use cases, if your expression's form references variables
that will not be immediately resolved from the global scope, you can
explicitly bind values to them using the `.bind` method (which returns
a new expression object with variables resolved using the provided
mapping):

``` scheme
(setv unbound-expr (le.expr (add x y)))
(.latex unbound-expr) ;; => "x + y"
(unbound-expr) ;; => NameError: name 'x' is not defined
(setv bound-expr (.bind expr-with-unbound-x {"x" 5 "y" 3}))
(.latex bound-expr) ;; => "5 + 3"
(bound-expr) ;; => 8
```

You can also generate a list of expressions with the `exprs` macro:

``` scheme
(exprs
  (add 1 2)
  (add 3 4))
```


## Operators

Operators are essentially the "functions" of Lemma's syntax. Operators
are called with a series of arguments, and perform some operation to
those arguments. For example, the `add` operator from
`lemma.domain.algebra` performs the addition of any number of
arguments:

``` scheme
(setv addition-expr (le.expr (add 1 2 3 4)))
(.latex addition-expr) ;; => "1 + 2 + 3 + 4"
(addition-expr) ;; => 10
```

You may also find it more readable to identify operator arguments with
keywords in some cases:

``` scheme
(div :numerator 6 :denominator 2) ;; => 3
```

### Callable Operators

As well as being usable in Lemma forms, some operators are classified
as "callable", and can be called directly from Hy or Python code:

``` scheme
(add 1 2 3 4) ;; => 10
;; Or in Python: add(1 2 3 4)
(.latex add 1 2 3 4) ;; => "1 + 2 + 3 + 4"
;; Or in Python: add.latex(1 2 3 4)
(.hy add 1 2 3 4) ;; => '(+ 1 2 3 4)
;; Or in Python: add.hy(1 2 3 4)
```

While it is possible to define your own operators (see documentation
on formulas, equations, and custom operators later in this document)
Most operators you use will be imported from `lemma.domain` submodules
(like `lemma.domain.algebra`).

### Tag Operators

Lemma forms also support some special **tag operators**, which provide
an abbreviated syntax for commonly used operations that apply to a
single argument. All tag operators start with a `#`, and are used as a
prefix for their target argument. The following table lists the tag
operators supported in Lemma forms, and demonstrates their usage:

| Tag | Description | Usage in Forms |
| - | - | - |
| `#p` | Explicitly wraps the target's LaTeX representation in parentheses. | `#p(add 1 2)` → $(1 + 2)$<br>`(add #p 1 2)` → $(1) + 2$ |
| `#b` | Prevent the target's LaTeX representation from being automatically wrapped in parentheses by an operator.<br>**NOTE:** The order of operations expressed in the resulting LaTeX may no longer reflect the computation, so only use `#b` when you are sure the order of operations is not impacted. | `(add #b(mul/times 1 2) 3)` → $1 \times 2 + 3$ |


## Formulas

Formulas are a special type of callable operator, and are the primary
means of defining re-usable Lemma expressions that can accept
arguments.

You can define a new formula with the `def-formula` macro:

``` scheme
;; (le.def-formula NAME LATEX-NAME
;;   [PARAMETERS]
;;   OPTIONAL-DOCSTRING
;;   BODY-FORM)
(le.def-formula circumference "C_{radius}"
  [r]
  "Return the circumference of a circle with radius `r`."
  (mul/times 2 PI r))
```

Formulas can be applied like all other callable operators either
directly or in Lemma forms, which will result in the evaluation of the
`BODY-FORM` with the provided arguments. The supplied `LATEX-NAME`
will be used to format the formula as a function call:

``` scheme
(setv circ-expr (le.expr (circumference 42)))
(circ-expr) ;; => 263.89378290154264
(.latex circ-expr) ;; => r"C_{radius}\left(4\right)"
```

Formatted as: $C_{radius}\left(4\right)$

If you want your formula formatted as an expression built from the
`BODY-FORM`, you can use the simplified operator made available in the
`.op` attribute:

``` scheme
(setv circ-op-expr (le.expr (circumference.op 42)))
(.latex circ-op-expr) ;; => "2 \times \pi \times 42"
```

### Formula LaTeX

Formulas also provide some special LaTeX formatting capabilities. When
called without any arguments, the `.latex` method will provide the
notation for a full definition of the formula. The `.signature-latex`
and `.body-latex` methods also allow you retrieve the individual parts
of the definition:

<table>
    <tr>
        <td><code>(circumference.latex)</code></td>
        <td>$C_{radius}\left(r\right) = 2 \times \pi \times r$</td>
    </tr>
    <tr>
        <td><code>(circumference.signature-latex)</code></td>
        <td>$C_{radius}\left(r\right)$</td>
    </tr>
    <tr>
        <td><code>(circumference.body-latex)</code></td>
        <td>$2 \times \pi \times r$</td>
    </tr>
</table>

You can also provide arguments to these functions to replace the
placeholder variables in the formatted output:

<table>
    <tr>
        <td><code>(circumference.latex 42)</code></td>
        <td>$C_{radius}\left(42\right) = 2 \times \pi \times 42$</td>
    </tr>
    <tr>
        <td><code>(circumference.signature-latex 42)</code></td>
        <td>$C_{radius}\left(42\right)$</td>
    </tr>
    <tr>
        <td><code>(circumference.body-latex 42)</code></td>
        <td>$2 \times \pi \times 42$</td>
    </tr>
</table>

### Formula Parameters

Formula parameter lists support all the features of Hy/Python
functions, including variable argument lengths, optional arguments
with default values, keyword arguments, and type annotations. For
syntax and examples, see:
https://docs.hylang.org/en/stable/language/api.html#defn

Lemma also allows you to control whether formula arguments are
formatted as a list within parentheses (default), or as subscripts or
superscripts. By placing `:paren`, `:super`, or `:sub` in your
parameter list, all following arguments will be formatted
accordingly. You can even combine argument formats:

``` scheme
(le.def-formula magic r"\text{magic}"
  [:sub x y :super a b :paren i j]
  (add x y a b i j))
(.signature-latex magic)
```

Will be formatted as: $\text{magic}_{x, y}^{a, b}(i, j)$


## Equations

Equations are a special type of callable operator, and are useful for
testing the steps in the algebraic transformation of an expression.

An equation can be defined by a sequence of Lemma forms that should
all produce the same result when evaluated with the same arguments:

``` scheme
;; (le.def-equation NAME
;;   [PARAMETERS]
;;   OPTIONAL-DOCSTRING
;;   [STEP1
;;    STEP2
;;    ...])
(le.def-equation foil
  [x y]
  "Equation to test the steps of a FOIL expansion."
  [(mul (add x y) (sub x y))
   (add #b(sub (pow x 2) (mul x y))
        #b(sub (mul x y) (pow y 2)))
   (sub (pow x 2) (pow y 2))])
```

It is also possible to create an anonymous equation without assigning
it to a variable, which may be useful for writing unit tests of
formulas and operators:

``` scheme
(equation [PARAMETERS] [...STEPS...])
```

Equations can be applied like all other callable operators either
directly or in Lemma forms. If all steps evaluate to the same result
for the given arguments, then that result is returned, and the LaTeX
representation will be that of the first form:

``` scheme
(setv foil-expr (le.expr (foil 3 2)))
(foil-expr) ;; => 5
(.latex foil-expr) ;; => r"\left(x + y\right)\left(x - y\right)"
```

If all steps do not evaluate to the same result, then a
`lemma.exceptions.LeEquationError` will be raised:

``` scheme
(le.def-equation bad-equation
  [x]
  [(add x 1)
   (sub x 1)])
(bad-equation 2)
;; => LeEquationError: While evaluating LeEquation#bad-equation
;;    with arguments [2]: result '1' of
;;    LeExpression#(LeCallableOperator#sub 2 1) did not equal
;;    result '3' of LeExpression#(LeCallableOperator#sub 2 1)
```

### Equation LaTeX

Equations also provide some special LaTeX formatting
capabilities. When called without any arguments, the `.latex` method
will provide the notation for all steps in the equation. Providing
arguments will replace the placeholder variables in the formatted
output:

<table>
    <tr>
        <td><code>(foil.latex)</code></td>
        <td>$$\begin{aligned} \left(x + y\right)\left(x - y\right) &= x^{2} - xy + xy - y^{2} \\&= x^{2} - y^{2}\end{aligned}$$</td>
    </tr>
    <tr>
        <td><code>(foil.latex 3 2)</code></td>
        <td>$$\begin{aligned} \left(3 + 2\right)\left(3 - 2\right) &= 3^{2} - 3\left(2\right) + 3\left(2\right) - 2^{2} \\&= 3^{2} - 2^{2}\end{aligned}$$</td>
    </tr>
</table>

### Equation Parameters

Equation parameter lists support all the features of Hy/Python
functions, including variable argument lengths, optional arguments
with default values, keyword arguments, and type annotations. For
syntax and examples, see:
https://docs.hylang.org/en/stable/language/api.html#defn


## Constants

Defining a constant allows you to associate a fixed value with a LaTeX
representation:

``` scheme
;; (le.def-constant NAME LATEX VALUE OPTIONAL-DOCSTRING)
(le.def-constant APPROX-PI r"\sim\pi" (/ 22.0 7)
  "An approximation of Pi.")
```

As well as acting as Lemma forms, Constants also support many of the
same methods as expressions:

``` scheme
(.latex APPROX-PI) ;; => r"\sim\pi"
(.hy APPROX-PI) ;; => '(/ 22.0 7)
;; Call as a function to get the value.
(APPROX-PI) ;; => 3.142857142857143
```


## Identifiers

Identifiers are a special kind of constant that associate a LaTeX
representation with an unbound/free variable name.

Defining an identifier allows you to specify the LaTeX representations
for formatting the argument placeholders of formulas and
equations. This allows you to use readable argument names while still
using conventional mathematical representations in LaTeX:

``` scheme
;; (le.def-identifier NAME LATEX OPTIONAL-DOCSTRING)
(le.def-identifier velocity r"V")
(le.def-identifier delta r"\delta"
  "A small difference in velocity, represented as $\delta$.")
(le.def-formula accelerate r"\text{acc}" [velocity delta]
  "Increase velocity by delta."
  (add velocity delta))
(le.def-formula decelerate r"\text{dec}" [velocity delta]
  "Decrease velocity by delta."
  (sub velocity delta))
(.latex accelerate) ;; => r"\text{acc}\left(V, \delta\right) = V + \delta"
(.latex decelerate) ;; => r"\text{dec}\left(V, \delta\right) = V - \delta"
```

Which will be formatted as: "$\text{acc}\left(v, \delta\right) = v +
\delta$" and "$\text{dec}\left(v, \delta\right) = v - \delta$".


## Defining Custom Operators

Sometimes you need to perform an operation in Lemma for which an
operator does not exist. For these cases, you can use the
`def-operator` macro:

``` scheme
;; (le.def-operator NAME
;;   [PARAMETERS]
;;   OPTIONAL-DOCSTRING
;;   CLAUSES...)
(le.def-operator increment
  [v]
  "Increments the provided value."
  (expr (add v 1))
  (example-args [x]
                [4]))
```

Each of the `CLAUSES` in an operator definition begins with the
clause's type, followed by the clause body. The following clauses can
be used to define an operator:

| Clause | Description | Example |
| - | - | - |
| `expr` | The clause body is a Lemma form that can be evaluated with the provided arguments to produce the LaTeX and resulting value of the operation. | `(expr (add v 1))` |
| `latex` | The clause body is a Hy expression that will return a LaTeX representation of the operation (as a string or LatexString). The arguments will be provided as LatexStrings. | `(latex (+ v " + 1"))` |
| `latex-macro` | The clause body is a Hy expression that will return a LaTeX representation of the operation (as a string or LatexString). The arguments will be provided as their raw forms/syntax. This can be useful for more complex operators that do not use their arguments as values directly. | `(latex-macro (+ (gen-latex v) " + 1"))` |
| `precedence`&nbsp;(optional) | The provided numeric value will override the `precedence` of any string generated by the `latex` or `latex-macro` clause. You should typically use on of the values defined in `lemma.precedences`. | `(precedence BINARY-OP-PRECEDENCE)` |
| `hy` | The clause body is a Hy expression that will return the resulting value of the operation. The arguments will be provided as their evaluated values. | `(hy (+ v 1))` |
| `hy-macro` | The clause body is a Hy expression that will return the syntax for a Hy expression that will produce the operation's result (similar to a Hy macro). The arguments will be provided as their raw forms/syntax. This can be useful for more complex operators that do not use their arguments as values directly. | `(hy (+ v 1))` |
| `example-args`&nbsp;(optional) | The clause body is a list of argument sets that can be used to format examples of usage and output LaTeX in auto-generated documentation. | (example-args [x] [4]) |

An operator definition must include either an `expr` clause and a pair
of hy/latex clauses, but may not include both. Furthermore, only one
of `latex` or `latex-macro` and `hy` or `hy-macro` may specified. As
long as an operator does not make use of a `latex-macro` or `hy-macro`
clause, it will be a *callable* operator.

### Operator Parameters

Operator parameter lists support all the features of Hy/Python
functions, including variable argument lengths, optional arguments
with default values, keyword arguments, and type annotations. For
syntax and examples, see:
https://docs.hylang.org/en/stable/language/api.html#defn

### Tips for Defining Operators

* The `lemma.core.latexstr` macro is useful for creating a LatexString
  object with an optionally set precedence:
  ``` scheme
  (le.latexstr "1 + 1" BINARY-OP-PRECEDENCE)
  ```
* Some other helpful utility functions are provided in the
  [`lemma.utils` module](lemma.utils).
  * `gen-hy` and `gen-latex` are useful for applying to
    arguments in `*-macro` clauses.
  * `latex-enclose-arg` can be used to automatically wrap LatexStrings
    in parentheses if their precedence is greater than or equal to a
    specified maximum.
* If you are defining multiple operators with the same behaviour but
  different LaTeX representations, you may like to give them a common
  prefix, and distinguish them with different suffixes after a forward
  slash: e.g. `mul`, `mul/times`, `mul/dot`.
