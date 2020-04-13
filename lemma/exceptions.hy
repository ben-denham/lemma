(defclass LeError [Exception])

(defclass LeRuntimeError [LeError])

(defclass LeSyntaxError [LeError])

(defclass LeEquationError [LeError])
