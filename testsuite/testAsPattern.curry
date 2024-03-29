--------------------------------------------------------------------------------
-- Some tests for "as" patterns.
--- 
--- @author Michael Hanus
--- @version February 2013
--------------------------------------------------------------------------------

import Assertion

--------------------------------------------------------------------------------
-- Simple as pattern:
f1 v@(x:_) = x : v

test1 = assertEqual  "Simple" (f1 [1,2]) [1,1,2]

--------------------------------------------------------------------------------
-- Non-linear as pattern:
g1 v@(x:_) v@(y:_) = x : y : v

test3 = assertEqual "Non-linear as (1)" (g1 [1,2] [1,2]) [1,1,1,2]

test4 = assertValues "Non-linear as (2)" (g1 [1,2] [3,4]) []

--------------------------------------------------------------------------------
-- As patterns in functional patterns:

h1 (_ ++ x@[(3,_)] ++ _) = x

test5 = assertEqual "FuncPat As (1)" (h1 (zip [1..9] [11..19])) [(3,13)]

h2 (_ ++ x@[_ ++ y@[(42,99)] ++ _] ++ _) = (x,y)

test6 = assertEqual "FuncPat As (2)"
          (h2 [[(1,2)],[(2,3),(42,99)],[]]) ([[(2,3),(42,99)]],[(42,99)])

h3 (v@[] ++ v@(_:_)) = 0

test7 = assertValues "FuncPat As (3)" (h3 [1,2,3,4]) []

--------------------------------------------------------------------------------
