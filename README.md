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

An extensible mini-language to generate mathematical notation for
executable and testable Python.

## Le Quick Start

Try the Demo on Binder:

[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/ben-denham/lemma/master?filepath=notebooks%2FLemmaDemo.ipynb)

Or get it from PyPi [![PyPI version](https://badge.fury.io/py/lemma.svg)](https://badge.fury.io/py/lemma)

```
pip install lemma
```

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

* Complete `algebra.hy`
* Improve precedence numbering.
* Commenting and some refactoring
* Generate docstrings
* Examples with pdoc3 and pytest
* Documentation (tutorial, API reference)

## Le Dev Environment

### Dependencies

In order to run this project, you must have the following dependencies
installed on your host:

* [Docker Community Edition](https://docs.docker.com/get-docker/) (>= 17.09)
* [Docker Compose](https://docs.docker.com/compose/install/) (>= 1.17)
  (Included with Docker Desktop on Mac/Windows)
* [Make](https://www.gnu.org/software/make/) (technically optional if
  you don't mind running the commands in the Makefile directly)

**Note:** If you use [Git bash](https://git-scm.com/downloads) on
Windows and also
[install `make`](https://gist.github.com/evanwill/0207876c3243bbb6863e65ec5dc3f058)
into Git bash, then you should be able to run this project on Windows.

## Basic Usage

1. Run `make run` in this directory.
   * This will perform all Docker image build steps and dependency
     installations every time you run it, so that you can never forget
     to rebuild. The first time you run this, it make take some time
     for the base Docker image and other dependencies to be
     downloaded.
2. Browse to http://localhost:7777 and enter the token displayed in
   the terminal (or just follow the link in the terminal).
3. Work in Python notebooks, with the ability to import code from your
   the lemma module.

### Linting

You can run [flake8](http://flake8.pycqa.org/en/latest/) linting on
your modules with: `make lint`.

### Testing

You can run [pytest](https://docs.pytest.org/en/latest/) unit tests
linting contained in your modules with: `make test`.

An HTML code-coverage reported will be generated for each module at:
`<module-dir>/test/coverage/index.html`.
