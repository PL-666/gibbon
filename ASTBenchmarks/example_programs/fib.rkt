;; This is in the simplified easy-to-map-onto-algebraic-datatype grammar.

(MKPROG
 (
 (DefineValues (fib)
   (Lambda (F1 (n))
           (If (App ((VARREF <=) (VARREF n) (Quote (INTLIT 2))))
               (Quote (INTLIT 1))
               (App ( (VARREF +)
                      (App ((VARREF fib)
                            (App ((VARREF -) (VARREF n) (Quote (INTLIT 1))))))
                      (App ((VARREF fib)
                            (App ((VARREF -) (VARREF n) (Quote (INTLIT 2)))))))))))
 ))

