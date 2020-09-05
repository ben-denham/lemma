"This module provides constants and operators for expressing basic
algebra in Lemma."

(require [hy.contrib.walk [let]])
(require [lemma.core :as le])
(import [functools [partial]]
        math
        [lemma.utils [gen-latex gen-hy
                      latex-enclose-arg
                      validate-even-bindings!]]
        [lemma.precedence [*]])

;; CONSTANTS

(le.def-constant E r"e" math.e
  "Mathematical constant $e$.")
(le.def-constant PI r"\pi" math.pi
  r"Mathematical constant $\pi$.")
(le.def-constant TAU r"\tau" math.tau
  r"Mathematical constant $\tau = 2\pi$.")

;; ARITHMETIC

(le.def-operator add
  [&rest args]
  "Add the given arguments."
  (precedence BINARY-OP-PRECEDENCE)
  (latex
    (->> args
         (map (partial latex-enclose-arg BINARY-OP-PRECEDENCE))
         (.join " + ")))
  (hy (+ #* args))
  (example-args [x 1 2]))

(le.def-operator sub
  [&rest args]
  "Subtract, from the first argument, all remaining arguments. If only one
  argument is provided, return its negation."
  (precedence BINARY-OP-PRECEDENCE)
  (latex
    (if (> (len args) 1)
        (->> args
             (map (partial latex-enclose-arg BINARY-OP-PRECEDENCE))
             (.join " - "))
        f"-{(first args)}"))
  (hy (- #* args))
  (example-args [x]
                [x 1 2]))

(le.def-operator mul
  [&rest args]
  "Multiply the given arguments (formatted as a juxt-position)."
  (precedence JUXT-PRECEDENCE)
  (latex
    (let [;; The precedence of each arg must be lower than the
          ;; previous arg (e.g. to prevent 2 numerics in a row), and
          ;; all must be below UNARY-OP-PRECEDENCE. Don't set a max
          ;; precedence below numeric though (parens should be placed
          ;; side-by-side).
          max-precedences (+ [UNARY-OP-PRECEDENCE]
                             (->> args
                                  (drop-last 1)
                                  (map (fn [arg]
                                         (max (min UNARY-OP-PRECEDENCE arg.precedence)
                                              NUMERIC-PRECEDENCE)))
                                  (list)))]
      (.join "" (map latex-enclose-arg max-precedences args))))
  (hy (* #* args))
  (example-args [x 2 3]
                [2 x]))

(le.def-operator mul/times
  [&rest args]
  "Multiply the given arguments (formatted with times sign)."
  (precedence BINARY-OP-PRECEDENCE)
  (latex (->> args
              (map (partial latex-enclose-arg BINARY-OP-PRECEDENCE))
              (.join r" \times ")))
  (hy (* #* args))
  (example-args [x 2 3]))

(le.def-operator mul/dot
  [&rest args]
  "Multiply the given arguments (formatted with dot)."
  (precedence BINARY-OP-PRECEDENCE)
  (latex (->> args
              (map (partial latex-enclose-arg BINARY-OP-PRECEDENCE))
              (.join r" \cdot ")))
  (hy (* #* args))
  (example-args [x 2 3]))

(le.def-operator div
  [numerator denominator]
  "Divide the numerator by the denominator (formatted with division sign)."
  (precedence BINARY-OP-PRECEDENCE)
  (latex (+ (latex-enclose-arg BINARY-OP-PRECEDENCE numerator)
            " \div "
            (latex-enclose-arg BINARY-OP-PRECEDENCE denominator)))
  (hy (/ numerator denominator))
  (example-args [x 2]))

(le.def-operator div/frac
  [numerator denominator]
  "Divide the numerator by the denominator (formatted with division sign)."
  (precedence FRACTION-PRECEDENCE)
  (latex (+ r"\frac{" numerator "}{" denominator "}"))
  (hy (/ numerator denominator))
  (example-args [x 2]))

(le.def-operator pow
  [value exponent]
  "Raise value to the given exponent."
  (precedence EXPONENT-PRECEDENCE)
  (latex (+ (latex-enclose-arg EXPONENT-PRECEDENCE value)
            "^{" exponent "}"))
  (hy (** value exponent))
  (example-args [x 2]))

;; ceil
;; floor
;; mod
;; abs
;; log
;; root
;; max
;; min

;; Sequence Operations

(le.def-operator length
  [sequence]
  "Returns the length of the given sequence."
  (precedence UNARY-OP-PRECEDENCE)
  (latex f"|{sequence}|")
  (hy (len sequence))
  (example-args [[1 2 3]]))

(le.def-operator seq-sum
  [bindings body]
  "Returns the summation of the body form evaluated for each permutation of
  arguments specified by bindings."
  (precedence SUMMATION-PRECEDENCE)
  (latex-macro
    (validate-even-bindings! "seq-sum" bindings)
    (let [identifiers (->> bindings
                           (take-nth 2)
                           (map gen-latex))
          values (->> (rest bindings)
                      (take-nth 2)
                      (map gen-latex)
                      (map (fn [latex] (latex-enclose-arg BINARY-OP-PRECEDENCE latex))))
          latex-bindings (->> (map (fn [ident val] f"{ident} \in {val}")
                                   identifiers values)
                              (.join ", "))
          latex-body (->> (gen-latex body)
                          (latex-enclose-arg EQUATION-PRECEDENCE))]
      (+ r"\sum_{" latex-bindings "} " latex-body)))
  (hy-macro
    (validate-even-bindings! "seq-sum" bindings)
    `(sum (lfor ~@(map gen-hy bindings) ~(gen-hy body))))
  (example-args [[x [1 2 3] y [4 5 6]] (add x y)]))

(le.def-operator seq-prod
  [bindings body]
  "Returns the product of the body form evaluated for each permutation of
  arguments specified by bindings."
  (precedence SUMMATION-PRECEDENCE)
  (latex-macro
    (validate-even-bindings! "seq-prod" bindings)
    (let [identifiers (->> bindings
                           (take-nth 2)
                           (map gen-latex))
          values (->> (rest bindings)
                      (take-nth 2)
                      (map gen-latex)
                      (map (fn [latex] (latex-enclose-arg BINARY-OP-PRECEDENCE latex))))
          latex-bindings (->> (map (fn [ident val] f"{ident} \in {val}")
                                   identifiers values)
                              (.join ", "))
          latex-body (->> (gen-latex body)
                          (latex-enclose-arg EQUATION-PRECEDENCE))]
      (+ r"\prod_{" latex-bindings "} " latex-body)))
  (hy-macro
    (validate-even-bindings! "seq-prod" bindings)
    `(reduce * (lfor ~@(map gen-hy bindings) ~(gen-hy body))))
  (example-args [[x [1 2 3] y [4 5 6]] (add x y)]))

;; get/sup, get/sub
;; map
;; filter
;; range (set notation)

;; Conditional logic

;; lt/le/gt/ge/eq/neq
;; and/or/not
;; if-else
;; cond
