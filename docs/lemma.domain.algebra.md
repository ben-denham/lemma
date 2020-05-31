# lemma.domain.algebra

Constants and operators for basic algebra in Lemma.


## Constant: `E`

Mathematical constant $e$.<table>
  <tr>
    <td>E</td>
    <td>$e$</td>
    <td>`math.e` (`2.718281828459045`)</td>
  </tr>
</table>


## Constant: `PI`

Mathematical constant $\pi$.<table>
  <tr>
    <td>PI</td>
    <td>$\pi$</td>
    <td>`math.pi` (`3.141592653589793`)</td>
  </tr>
</table>


## Constant: `TAU`

Mathematical constant $\tau = 2\pi$.<table>
  <tr>
    <td>TAU</td>
    <td>$\tau$</td>
    <td>`math.tau` (`6.283185307179586`)</td>
  </tr>
</table>


## Operator: `add`

```scheme
(add &rest args)
```

Add the given arguments.

<table>
  <tr>
    <td><pre><code class="language-scheme">(add x 1 2)</code></pre></td>
    <td>$x + 1 + 2$</td>
  </tr>
</table>


## Operator: `sub`

```scheme
(sub &rest args)
```

Subtract, from the first argument, all remaining arguments. If only one
argument is provided, return its negation.

<table>
  <tr>
    <td><pre><code class="language-scheme">(sub x)</code></pre></td>
    <td>$-x$</td>
  </tr>
  <tr>
    <td><pre><code class="language-scheme">(sub x 1 2)</code></pre></td>
    <td>$x - 1 - 2$</td>
  </tr>
</table>


## Operator: `mul`

```scheme
(mul &rest args)
```

Multiply the given arguments (formatted as a juxt-position).

<table>
  <tr>
    <td><pre><code class="language-scheme">(mul x 2 3)</code></pre></td>
    <td>$x23$</td>
  </tr>
</table>


## Operator: `mul/times`

```scheme
(mul/times &rest args)
```

Multiply the given arguments (formatted with times sign).

<table>
  <tr>
    <td><pre><code class="language-scheme">(mul/times x 2 3)</code></pre></td>
    <td>$x \times 2 \times 3$</td>
  </tr>
</table>


## Operator: `mul/dot`

```scheme
(mul/dot &rest args)
```

Multiply the given arguments (formatted with dot).

<table>
  <tr>
    <td><pre><code class="language-scheme">(mul/dot x 2 3)</code></pre></td>
    <td>$x \cdot 2 \cdot 3$</td>
  </tr>
</table>


## Operator: `div`

```scheme
(div numerator denominator)
```

Divide the numerator by the denominator (formatted with division sign).

<table>
  <tr>
    <td><pre><code class="language-scheme">(div x 2)</code></pre></td>
    <td>$x \div 2$</td>
  </tr>
</table>


## Operator: `div/frac`

```scheme
(div/frac numerator denominator)
```

Divide the numerator by the denominator (formatted with division sign).

<table>
  <tr>
    <td><pre><code class="language-scheme">(div/frac x 2)</code></pre></td>
    <td>$\frac{x}{2}$</td>
  </tr>
</table>


## Operator: `pow`

```scheme
(pow value exponent)
```

Raise value to the given exponent.

<table>
  <tr>
    <td><pre><code class="language-scheme">(pow x 2)</code></pre></td>
    <td>$x^{2}$</td>
  </tr>
</table>


## Operator: `length`

```scheme
(length sequence)
```

Returns the length of the given sequence.

<table>
  <tr>
    <td><pre><code class="language-scheme">(length [1 2 3])</code></pre></td>
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
    <td><pre><code class="language-scheme">(seq-sum [x [1 2 3] y [4 5 6]] (add x y))</code></pre></td>
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
    <td><pre><code class="language-scheme">(seq-prod [x [1 2 3] y [4 5 6]] (add x y))</code></pre></td>
    <td>$\prod_{x \in \{1, 2, 3\}, y \in \{4, 5, 6\}} x + y$</td>
  </tr>
</table>
