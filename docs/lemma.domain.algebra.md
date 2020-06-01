# lemma.domain.algebra

This module provides constants and operators for expressing basic
algebra in Lemma.


## Constant: `E`

Mathematical constant $e$.<table>
  <tr>
    <td>`math.e` (`2.718281828459045`)</td>
    <td>$e$</td>
  </tr>
</table>


## Constant: `PI`

Mathematical constant $\pi$.<table>
  <tr>
    <td>`math.pi` (`3.141592653589793`)</td>
    <td>$\pi$</td>
  </tr>
</table>


## Constant: `TAU`

Mathematical constant $\tau = 2\pi$.<table>
  <tr>
    <td>`math.tau` (`6.283185307179586`)</td>
    <td>$\tau$</td>
  </tr>
</table>


## Operator: `add`

```scheme
(add &rest args)
```

Add the given arguments.

*Callable: Supports direct usage from Hy/Python code.*

<table>
  <tr>
    <td><code class="language-scheme">(add x 1 2)</code></td>
    <td>$x + 1 + 2$</td>
  </tr>
</table>


## Operator: `sub`

```scheme
(sub &rest args)
```

Subtract, from the first argument, all remaining arguments. If only one
argument is provided, return its negation.

*Callable: Supports direct usage from Hy/Python code.*

<table>
  <tr>
    <td><code class="language-scheme">(sub x)</code></td>
    <td>$-x$</td>
  </tr>
  <tr>
    <td><code class="language-scheme">(sub x 1 2)</code></td>
    <td>$x - 1 - 2$</td>
  </tr>
</table>


## Operator: `mul`

```scheme
(mul &rest args)
```

Multiply the given arguments (formatted as a juxt-position).

*Callable: Supports direct usage from Hy/Python code.*

<table>
  <tr>
    <td><code class="language-scheme">(mul x 2 3)</code></td>
    <td>$x\left(2\right)\left(3\right)$</td>
  </tr>
  <tr>
    <td><code class="language-scheme">(mul 2 x)</code></td>
    <td>$2x$</td>
  </tr>
</table>


## Operator: `mul/times`

```scheme
(mul/times &rest args)
```

Multiply the given arguments (formatted with times sign).

*Callable: Supports direct usage from Hy/Python code.*

<table>
  <tr>
    <td><code class="language-scheme">(mul/times x 2 3)</code></td>
    <td>$x \times 2 \times 3$</td>
  </tr>
</table>


## Operator: `mul/dot`

```scheme
(mul/dot &rest args)
```

Multiply the given arguments (formatted with dot).

*Callable: Supports direct usage from Hy/Python code.*

<table>
  <tr>
    <td><code class="language-scheme">(mul/dot x 2 3)</code></td>
    <td>$x \cdot 2 \cdot 3$</td>
  </tr>
</table>


## Operator: `div`

```scheme
(div numerator denominator)
```

Divide the numerator by the denominator (formatted with division sign).

*Callable: Supports direct usage from Hy/Python code.*

<table>
  <tr>
    <td><code class="language-scheme">(div x 2)</code></td>
    <td>$x \div 2$</td>
  </tr>
</table>


## Operator: `div/frac`

```scheme
(div/frac numerator denominator)
```

Divide the numerator by the denominator (formatted with division sign).

*Callable: Supports direct usage from Hy/Python code.*

<table>
  <tr>
    <td><code class="language-scheme">(div/frac x 2)</code></td>
    <td>$\frac{x}{2}$</td>
  </tr>
</table>


## Operator: `pow`

```scheme
(pow value exponent)
```

Raise value to the given exponent.

*Callable: Supports direct usage from Hy/Python code.*

<table>
  <tr>
    <td><code class="language-scheme">(pow x 2)</code></td>
    <td>$x^{2}$</td>
  </tr>
</table>


## Operator: `length`

```scheme
(length sequence)
```

Returns the length of the given sequence.

*Callable: Supports direct usage from Hy/Python code.*

<table>
  <tr>
    <td><code class="language-scheme">(length [1 2 3])</code></td>
    <td>$|\{1, 2, 3\}|$</td>
  </tr>
</table>


## Operator: `seq-sum`

```scheme
(seq-sum bindings body)
```

Returns the summation of the body form evaluated for each permutation of
arguments specified by bindings.

<table>
  <tr>
    <td><code class="language-scheme">(seq-sum [x [1 2 3] y [4 5 6]] (add x y))</code></td>
    <td>$\sum_{x \in \{1, 2, 3\}, y \in \{4, 5, 6\}} x + y$</td>
  </tr>
</table>


## Operator: `seq-prod`

```scheme
(seq-prod bindings body)
```

Returns the product of the body form evaluated for each permutation of
arguments specified by bindings.

<table>
  <tr>
    <td><code class="language-scheme">(seq-prod [x [1 2 3] y [4 5 6]] (add x y))</code></td>
    <td>$\prod_{x \in \{1, 2, 3\}, y \in \{4, 5, 6\}} x + y$</td>
  </tr>
</table>
