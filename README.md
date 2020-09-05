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

**TL;DR:**

1. Write your mathematical formula with Lemma
2. Execute them from Python code
3. Output formula definitions in LaTeX maths notation
4. Ensures your implementation and documentation match
5. Great for reproducible research and teaching/learning

## Le Quick Start

Follow the tutorial on Binder:

[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/ben-denham/lemma/master?filepath=notebooks%2FTutorial.ipynb)

Then check out:

* [Le Docs](http://ben-denham.github.io/lemma)
* [Le Installation Guide](http://ben-denham.github.io/lemma/#/installation)
* [Le API reference](https://ben-denham.github.io/lemma/#/lemma.core)

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

* [handcalcs](https://github.com/connorferster/handcalcs)
  * handcalcs has a similar goal of producing LaTeX notation for your
    Python code, but it takes the approach of directly interpreting
    Python syntax. It supports some common mathematical notation, but
    does not appear to have the same focus on user extensibility (to
    new math domains) and customisability (for fine-grained control of
    generated notation) that Lemma does.
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
* [Penrose](http://penrose.ink/)
  * While Penrose is a math language for generating diagrams, while
    Lemma generates LaTeX notation and executable code.

## Le TODO

* Write tutorial
* Add more operators to `algebra.hy`
* Add unit tests
