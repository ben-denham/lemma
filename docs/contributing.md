# Contributing

If you like Lemma, there are lots of ways you can contribute:

* Star Lemma on [GitHub](https://github.com/ben-denham/lemma).
* Tell your friends/colleagues/students about Lemma.
* If you've used Lemma in a project, please [write an
  issue](https://github.com/ben-denham/lemma/issues/new) sharing what
  you used it for, and what you liked or didn't like about using
  it. If your project is open-source, post the link and we'll add it
  to a list of projects using Lemma in the README.
* [Write an issue](https://github.com/ben-denham/lemma/issues/new) (or
  even better a [pull
  request](https://github.com/ben-denham/lemma/pulls)) for a feature
  you'd like to see added.
* Add a new domain to Lemma, with operators, constants, and formulas
  covering some field of mathematics. Some ideas:
  * Set theory with Python sets.
  * Linear algebra with numpy.
  * Calculus, perhaps using the
    [SymPy](https://docs.sympy.org/latest/index.html) symbolic
    computation library as a foundation.

## Development Environmnt

A Docker-based development environment is provided in the [Lemma
repository](https://github.com/ben-denham/lemma).

To use it, you must have the following dependencies installed on your
host:

* [Docker Community Edition](https://docs.docker.com/get-docker/) (>= 17.09)
* [Docker Compose](https://docs.docker.com/compose/install/) (>= 1.17)
  (Included with Docker Desktop on Mac/Windows)
* [Make](https://www.gnu.org/software/make/) (technically optional if
  you don't mind running the commands in the Makefile directly)

**Note:** If you use [Git bash](https://git-scm.com/downloads) on
Windows and also
[install `make`](https://gist.github.com/evanwill/0207876c3243bbb6863e65ec5dc3f058)
into Git bash, then you should be able to run this project on Windows.

Once you have installed the above tools, you can:

1. Run `make run` in the project root directory.
   * This will perform all Docker image build steps and dependency
     installations every time you run it, so that you can never forget
     to rebuild. The first time you run this, it make take some time
     for the base Docker image and other dependencies to be
     downloaded.
2. Browse to http://localhost:7777 and enter the token displayed in
   the terminal (or just follow the link in the terminal).
3. Work in Python notebooks, with the ability to import code from your
   the `lemma` package.
4. Run linting with `make lint`.
5. Run tests with `make test`.
