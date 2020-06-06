"""
IPython extension that provides %%hy and %%lemma magics, as well
as HTML representations for Lemma objects.
"""

import sys
import hy

from lemma.lang import LatexString, LeExpression
from lemma.exceptions import LeError

try:
    from IPython.display import HTML
    from IPython.core.magic import needs_local_scope
except ImportError as ex:
    raise LeError('You can only load lemma.ipython from an IPython/Jupyter notebook.') from ex


def hy_eval_in_ns(code, ns):
    """Return the result of evaluating the given Hy code in the given
    namespace."""
    return hy.eval(hy.read_str("(do\n" + code + "\n)\n"),
                   locals=ns, module=sys.modules[ns['__name__']])


def table_formatter(rows):
    """Format the rows (a list of col/cell lists) as an HTML table string."""
    row_cells = [''.join([f'<td style="font-size: 14px; padding: 20px;">{cell}</td>'for cell in row]) for row in rows]
    trs = [f'<tr>{cells}</tr>' for cells in row_cells]
    return f'<table class="lemma-table">{"".join(trs)}</table>'


@needs_local_scope
def hy_magic(line, cell=None, local_ns=None):
    """Magic to execute Hy code within a Python kernel."""
    code = (line or "") + (cell or "")
    return hy_eval_in_ns(code, local_ns)


@needs_local_scope
def lemma_magic(line, cell=None, local_ns=None):
    """Magic to print the LaTeX and result for a Lemma expression
    made from the given form."""
    if line:
        expr = hy_eval_in_ns(f'(require [lemma.core [expr]])\n(expr {line})', local_ns)
        return expr
    elif cell:
        exprs = hy_eval_in_ns(f'(require [lemma.core [exprs]])\n(exprs {cell})', local_ns)
        return HTML(table_formatter([[f'$${expr.latex()}$$', expr()] for expr in exprs]))


def latexstring_formatter(latexstring):
    "Format LatexString as math in notebooks."
    return f'$${latexstring}$$'


def expression_formatter(expr):
    "Format LeExpression as math + value in notebooks."
    return table_formatter([[f'$${expr.latex()}$$', expr()]])


def load_ipython_extension(ipython):
    ipython.register_magic_function(hy_magic, magic_kind='line_cell', magic_name='hy')
    ipython.register_magic_function(lemma_magic, magic_kind='line_cell', magic_name='lemma')
    html_formatter = ipython.display_formatter.formatters['text/html']
    html_formatter.for_type(LatexString, latexstring_formatter)
    html_formatter.for_type(LeExpression, expression_formatter)
