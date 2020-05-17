"Constants and operators for basic algebra in Lemma."

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
  "Mathematical constant $\pi$.")
(le.def-constant TAU r"\tau" math.tau
  "Mathematical constant $\tau = 2\pi$.")

;; ARITHMETIC

(le.def-operator add
  [&rest args]
  "Add the given arguments."
  (precedence BINARY-OP-PRECEDENCE)
  (latex
    (->> args
         (map (partial latex-enclose-arg BINARY-OP-PRECEDENCE))
         (.join " + ")))
  (hy (+ #* args)))

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
  (hy (hy.core.shadow.- #* args)))

(le.def-operator mul
  [&rest args]
  "Multiply the given arguments (formatted as a juxt-position)."
  (precedence JUXT-PRECEDENCE)
  (latex (->> args
              (map (partial latex-enclose-arg FUNCTION-CALL-PRECEDENCE))
              (.join)))
  (hy (* #* args)))

(le.def-operator mul/times
  [&rest args]
  "Multiply the given arguments (formatted with times sign)."
  (precedence BINARY-OP-PRECEDENCE)
  (latex (->> args
              (map (partial latex-enclose-arg BINARY-OP-PRECEDENCE))
              (.join r" \times ")))
  (hy (* #* args)))

(le.def-operator mul/dot
  [&rest args]
  "Multiply the given arguments (formatted with dot)."
  (precedence BINARY-OP-PRECEDENCE)
  (latex (->> args
              (map (partial latex-enclose-arg BINARY-OP-PRECEDENCE))
              (.join r" \dot ")))
  (hy (* #* args)))

(le.def-operator div
  [numerator denominator]
  "Divide the numerator by the denominator (formatted with division sign)."
  (precedence BINARY-OP-PRECEDENCE)
  (latex (+ (latex-enclose-arg numerator BINARY-OP-PRECEDENCE)
            " \div "
            (latex-enclose-arg denominator BINARY-OP-PRECEDENCE)))
  (hy (/ numerator denominator)))

(le.def-operator div/frac
  [numerator denominator]
  "Divide the numerator by the denominator (formatted with division sign)."
  (precedence FRACTION-PRECEDENCE)
  (latex (+ r"\frac{" numerator "}{" denominator "}"))
  (hy (/ numerator denominator)))

(le.def-operator pow
  [value exponent]
  "Raise value to the given exponent."
  (precedence EXPONENT-PRECEDENCE)
  (latex (+ (latex-enclose-arg EXPONENT-PRECEDENCE value)
            "^{" exponent "}"))
  (hy (** value exponent)))

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
  (hy (len sequence)))

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
    `(sum (lfor ~@(map gen-hy bindings) ~(gen-hy body)))))

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
    `(reduce * (lfor ~@(map gen-hy bindings) ~(gen-hy body)))))

;; get/sup, get/sub
;; map
;; filter
;; range (set notation)

;; Conditional logic

;; lt/le/gt/ge/eq/neq
;; and/or/not
;; if-else
;; cond
