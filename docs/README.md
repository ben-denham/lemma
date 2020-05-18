```
     ##### /
  ######  /
 /#   /  /
/    /  /
    /  /
   ## ##              /##    ### /### /###    ### /### /###       /###
   ## ##             / ###    ##/ ###/ /##  /  ##/ ###/ /##  /   / ###  /
   ## ##            /   ###    ##  ###/ ###/    ##  ###/ ###/   /   ###/
   ## ##           ##    ###   ##   ##   ##     ##   ##   ##   ##    ##
   ## ##           ########    ##   ##   ##     ##   ##   ##   ##    ##
   #  ##           #######     ##   ##   ##     ##   ##   ##   ##    ##
      /            ##          ##   ##   ##     ##   ##   ##   ##    ##
  /##/           / ####    /   ##   ##   ##     ##   ##   ##   ##    /#
 /  ############/   ######/    ###  ###  ###    ###  ###  ###   ####/ ##
/     #########      #####      ###  ###  ###    ###  ###  ###   ###   ##
#
 ##
```

[![PyPI version](https://badge.fury.io/py/lemma.svg)](https://badge.fury.io/py/lemma)

An extensible mini-language to generate mathematical notation for
executable and testable Python.

## Le Quick Start

Follow the tutorial on Binder:

[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/ben-denham/lemma/master?filepath=notebooks%2FBasicTutorial.ipynb)

Then check out:

* [Le Docs](http://ben-denham.github.io/lemma)
* [Le API reference](https://ben-denham.github.io/lemma/#/lemma.core)
* [Tutorial on adding your own notation to Lemma](https://mybinder.org/v2/gh/ben-denham/lemma/master?filepath=notebooks%2BExtendingTutorial.ipynb)

## Le Features

* Define mathematical formulae that can be formatted as LaTeX and
  executed as functions.
* Check all of the steps in your equation transformations produce the
  same results in software.
* Runs on Python - you can use defined formulae in your existing
  Python projects, and use Python libraries from your formulae.
* Fully extensible - built with Hy (a Lisp running on Python) to
  provide powerful tools for defining your own mathematical
  operations.

## Le Use Cases

* Supports reproducible research by ensuring the notation in your
  paper matches the behaviour of your (testable) code.
* Enables developers to work through math in a more exploratory
  way. Use an equation to record the steps in your step-by-step
  algebraic transformations, and write test-cases to check your
  working. Then, get the LaTeX to document your work.
* Bridges the gap between mathematical notation and code to simplify
  teaching in domains that depend on both.

## Le Similar Projects

* [Mathematica/Wolfram Language](https://www.wolfram.com/language/)
  * The Wolfram Language has similar motivations to Lemma around
    bridging the gap between mathematical notation and executable
    code. You can generate LaTeX from your code, but it's a
    proprietary language. Also, because Lemma is built on top of
    Python, it can work with your existing Python code and libraries.
* [SymPy](https://docs.sympy.org/latest/index.html)
  * Like the Wolfram Language, SymPy is designed for symbolic
    computation. You can generate LaTeX from your expressions, but it
    seems that control over the notation is limited (expressions are
    automatically simplified, and LaTeX formatting options are
    controlled by keyword arguments that apply to the entire
    expression). Lemma is designed to be extensible so that you can
    define exactly how you want the LaTeX to be generated for your use
    case, and so that you can provide notation for any Python code you
    like (not just symbolic computation). A library for using SymPy's
    symbolic computation powers from Lemma would be a good extension
    though...
* [pytexit](https://pytexit.readthedocs.io/en/latest/)
  * Translates a string of Python code to LaTeX. Limited features
    supported, and requires managing Python code in strings.
* [LaTeXCalc](http://latexcalc.sourceforge.net/doc.php)
  * Interprets and executes LaTeX math notation. Limited library of
    math functions available.

## Le TODO

* Generate `algebra.hy` API doc from docstrings
  * Add support for defining example arguments for an operator.
* Commenting and some refactoring
  * lang.hy
  * core.hy
* Documentation
  * API reference: lemma.core
  * Installation & Usage
  * BasicTutorial
  * ExtendingTutorial
* Complete `algebra.hy`
* Unit tests