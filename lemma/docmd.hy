"Utilities for generating markdown documentation for Lemma objects."

(require [hy.contrib.walk [let]])
(import [hy.contrib.hy-repr [hy-repr]]
        [hy.lex [hy-parse]]
        [importlib [import-module]]
        [inspect [cleandoc getsource]]
        [lemma.lang [LeCallableOperator]])

(setv DOCUMENTABLE-DEFS #{"def-identifier" "def-constant"
                          "def-equation" "def-formula"
                          "def-operator"})

(defn module-docmd [module-name]
  (let [module (import-module module-name)]
    (+ f"# {module-name}"
       (if (and (hasattr module "__doc__")
                (not (none? (. module --doc--))))
           (+ "\n\n" (. module --doc--))
           "")
       "\n\n\n"
       (.join "\n\n\n"
              (->> (getsource module)
                   (hy-parse)
                   ;; Filter to to documentable defs.
                   (filter (fn [form]
                             (-> (first form)
                                 (str)
                                 (.split ".")
                                 (last)
                                 (in DOCUMENTABLE-DEFS))))
                   ;; Get defined name.
                   (map (fn [form] (mangle (str (second form)))))
                   ;; Lookup name in module
                   (filter (fn [obj-name] (in obj-name (. module --dict--))))
                   (map (fn [obj-name] (get (. module --dict--) obj-name)))
                   ;; Get docmd
                   (filter (fn [obj] (hasattr obj "_docmd")))
                   (map (fn [obj] (._docmd obj))))))))

(defn html-codeblock [code &optional [lang "scheme"]]
  f"<code class=\"language-{lang}\">{code}</code>")

(defn html-table [rows]
  (+ "<table>\n"
     (->> rows
          (map
            (fn [row]
              (+ "  <tr>\n"
                 (->> row
                      (map
                        (fn [cell]
                          (+ "    <td>" (str cell) "</td>\n")))
                      (.join ""))
                 "  </tr>\n")))
          (.join ""))
     "</table>"))

(defn base-docmd [type-name obj &optional [arglist None]]
  (let [obj-name (. obj name)
        title (+ "## " type-name ": `" obj-name "`")
        signature (if (none? arglist)
                      ""
                      (+ "\n\n```scheme\n(" obj-name " "
                         (.join " " (map
                                      (fn [item] (.lstrip (hy-repr item) "'"))
                                      arglist))
                         ")\n```"))
        docstring (if (hasattr obj "__doc__")
                      f"\n\n{(cleandoc (. obj --doc--))}"
                      "")]
    (+ title signature docstring)))

(defn identifier-docmd [identifier]
  (base-docmd "Identifier" identifier))

(defn constant-docmd [constant value-hy]
  (+ (base-docmd "Constant" constant)
     (html-table [[(+ "`" (.lstrip (hy-repr value-hy) "'") "` (`" (str (constant)) "`)")
                   (+ "$" (.latex constant) "$")]])))

(defn formula-docmd [formula arglist]
  (+ (base-docmd "Formula" formula arglist)
     "\n\n$" (.latex formula) "$"))

(defn equation-docmd [equation arglist]
  (+ (base-docmd "Equation" equation arglist)
     "\n\n$" (.latex equation) "$"))

(defn operator-docmd [operator arglist example-expressions]
  (+ (base-docmd "Operator" operator arglist)
     ;; Callable?
     (if (isinstance operator LeCallableOperator)
         "\n\n*Callable: Supports direct usage from Hy/Python code.*"
         "")
     ;; Table of example expressions.
     (if (empty? example-expressions)
         ""
         (+ "\n\n"
            (html-table
              (->> example-expressions
                   (map (fn [pair]
                          (let [form (first pair)
                                expr (second pair)
                                ;; Strip the quote off the form string.
                                form-str (.lstrip (hy-repr form) "'")]
                            [(html-codeblock form-str)
                             (+ "$" (.latex expr) "$")])))
                   (list)))))))
