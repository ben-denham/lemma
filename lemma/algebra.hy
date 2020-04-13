(require [hy.contrib.walk [let]])
(require [lemma.core :as le])
(import [functools [partial]]
        math
        [lemma.lang [gen-latex gen-hy
                     latex-enclose-arg
                     validate-even-bindings!]])

;; PRECEDENCES

#_(

    summations
    add/subtract
    multiply/divide
    fractions
    unary (minus,root,power)
    functions/identifiers/constants

    set operations?
    comparators?
    logical/bitwise operators
   )

;; CONSTANTS

(le.def-constant PI r"\pi" math.pi)

;; OPERATORS

(le.def-operator frac
  [numerator denominator]
  (precedence 10)
  (latex (+ r"\frac{" numerator "}{" denominator "}"))
  (hy (/ numerator denominator)))

(le.def-operator exp
  [value exponent]
  (precedence 5)
  (latex f"{(latex-enclose-arg 10 value)}^{exponent}")
  (hy (** value exponent)))

(le.def-operator length
  [value]
  (precedence 10)
  (latex f"|{value}|")
  (hy (len value)))

(le.def-operator add
  [&rest args]
  (precedence 100)
  (latex (->> args
              (map (partial latex-enclose-arg 100))
              (.join " + ")))
  (hy (+ #* args)))

(le.def-operator subtract
  [&rest args]
  (precedence 100)
  (latex
    (if (> (len args) 1)
        (->> args
             (map (partial latex-enclose-arg 100))
             (.join " - "))
        f"-{(first args)}"))
  (hy
    (hy.core.shadow.- #* args)))

(le.def-operator multiply
  [&rest args]
  (precedence 50)
  (latex (->> args
              (map (partial latex-enclose-arg 50))
              (.join r" \times ")))
  (hy
    (* #* args)))

(le.def-operator set-sum
  [bindings body]
  (precedence 500)
  (latex-macro
    (validate-even-bindings! "set-sum" bindings)
    (let [identifiers (->> bindings
                           (take-nth 2)
                           (map gen-latex))
          values (->> (rest bindings)
                      (take-nth 2)
                      (map gen-latex))
          latex-bindings (->> (map (fn [ident val] f"{ident} \in {val}")
                                   identifiers values)
                              (.join ", "))]
      (+ r"\sum_{" latex-bindings "} " (gen-latex body))))
  (hy-macro
    (validate-even-bindings! "set-sum" bindings)
    `(sum (lfor ~@(map gen-hy bindings) ~(gen-hy body)))))
