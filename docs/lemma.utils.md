# lemma.utils

Utilities that are helpful when extending the notation of Lemma.

## gen-hy

``` scheme
(gen-hy form)
```

Takes a Lemma form of Hy data structures and Lemma objects and returns
an executable Hy representation. Raises `LeSyntaxError` if the form
cannot be interpreted as a Lemma form, and raises `LeRuntimeError` if
an exception was raised while generating the Hy code.

```scheme
(require [lemma.core :as le])
(import [lemma.algebra [add]])

(gen-hy (le.expr (add 1 2))) ;; => '(+ 1 2)
```

## gen-latex

```scheme
(gen-latex form)
```

Takes a Lemma form of Hy data structures and Lemma objects and returns
a `LatexString` representation. Raises `LeSyntaxError` if the form
cannot be interpreted as a Lemma form, and raises `LeRuntimeError` if
an exception was raised while generating the LaTeX.

```scheme
(gen-latex (le.expr (add 1 2))) ;; => "1 + 2"
```

## latex-enclose-arg

```scheme
(latex-enclose-arg precedence-limit arg-latex-string)
```

If `LatexString` `arg-latex-string` has a precedence greater than or
equal to `precedence-limit`, then returns `arg-latex-string` wrapped
in parentheses, otherwise returns `arg-latex-string`.

```scheme
(latex-enclose-arg 20 (le.latexstr "spam" 10)) ;; => (LatexString "spam" 10)
(latex-enclose-arg 10 (le.latexstr "spam" 10)) ;; => (LatexString r"\left(spam\right)" BASE-PRECEDENCE)
```

## validate-even-bindings!

```scheme
(validate-even-bindings! caller bindings)
```

Raises `LeSyntaxError` if the given `bindings` sequence does not have
an even length. Formats the exception with the given name of the
`caller`.

```scheme
(validate-even-bindings! "calling-func" ['a 1 'b 2]) ;; => None
(validate-even-bindings! "calling-func" ['a 1 'b]) ;; => raises `LeSyntaxError`
```
