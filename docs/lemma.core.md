# lemma.core

The core set of Lemma macros for defining Lemma expressions and
higher-level constructs (formulae, equations, etc.).

## def-constant

`(def-constant symbol latex value &optional doc)`

### LeConstant

## def-equation

`(def-equation symbol arglist &rest parts)`

### LeEquation

## def-formula

`(def-formula symbol latex-name arglist &rest parts)`

### LeFormula

## def-identifier

`(def-identifier symbol latex &optional doc)`

### LeIdentifier

## def-operator

`(def-operator symbol arglist &rest parts)`

### LeOperator

## equation

`(def-equation arglist &rest parts)`

## expr

`(expr form)`

### LeExpression

## latexstr

`(latexstr latex &optional [precedence None])`

### LatexString
