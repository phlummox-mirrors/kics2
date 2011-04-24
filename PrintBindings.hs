--- This module contains the auxiliary operations to print
--- the main expression with the bindings of free variables.
--- The REPL translates an expression "exp where x1,...,xn free"
--- into the main expression (exp,["x1",...,"xn"],x1,...,xn).
--- The normal form of this expression is printed in a nicely
--- readable way by the operation "printWithBindings<n>".

module PrintBindings where

import Curry_Prelude
import Basics(fromCurry)

printWithBindings1 :: (Show a, Show b) =>
  (OP_Tuple3 a (OP_List C_String) b) -> IO ()
printWithBindings1 (OP_Tuple3 result names v1) =
  let [n1] = fromCurry names in
  putStrLn (concat ["{",
                    n1," = ",show v1,
                    "} ",show result])

printWithBindings2 :: (Show a, Show b, Show c) =>
  (OP_Tuple4 a (OP_List C_String) b c) -> IO ()
printWithBindings2 (OP_Tuple4 result names v1 v2) =
  let [n1,n2] = fromCurry names in
  putStrLn (concat ["{",
                    n1," = ",show v1,
                    ", ",
                    n2," = ",show v2,
                    "} ",show result])

printWithBindings3 :: (Show a, Show b, Show c, Show d) =>
  (OP_Tuple5 a (OP_List C_String) b c d) -> IO ()
printWithBindings3 (OP_Tuple5 result names v1 v2 v3) =
  let [n1,n2,n3] = fromCurry names in
  putStrLn (concat ["{",
                    n1," = ",show v1,
                    ", ",
                    n2," = ",show v2,
                    ", ",
                    n3," = ",show v3,
                    "} ",show result])

printWithBindings4 :: (Show a, Show b, Show c, Show d, Show e) =>
  (OP_Tuple6 a (OP_List C_String) b c d e) -> IO ()
printWithBindings4 (OP_Tuple6 result names v1 v2 v3 v4) =
  let [n1,n2,n3,n4] = fromCurry names in
  putStrLn (concat ["{",
                    n1," = ",show v1,
                    ", ",
                    n2," = ",show v2,
                    ", ",
                    n3," = ",show v3,
                    ", ",
                    n4," = ",show v4,
                    "} ",show result])

printWithBindings5 :: (Show a, Show b, Show c, Show d, Show e, Show f) =>
  (OP_Tuple7 a (OP_List C_String) b c d e f) -> IO ()
printWithBindings5 (OP_Tuple7 result names v1 v2 v3 v4 v5) =
  let [n1,n2,n3,n4,n5] = fromCurry names in
  putStrLn (concat ["{",
                    n1," = ",show v1,
                    ", ",
                    n2," = ",show v2,
                    ", ",
                    n3," = ",show v3,
                    ", ",
                    n4," = ",show v4,
                    ", ",
                    n5," = ",show v5,
                    "} ",show result])
