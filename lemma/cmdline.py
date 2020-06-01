import argparse
import hy  # noqa: F401

from lemma.docmd import module_docmd


def lemmadoc_main():
    parser = argparse.ArgumentParser(prog="lemmadoc")
    parser.add_argument("module", metavar="MODULE",
                        help=('Module to generate Markdown documentation from'))
    options = parser.parse_args()
    print(module_docmd(options.module))
