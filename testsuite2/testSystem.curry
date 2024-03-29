------------------------------------------------------------------------------
--- Some tests for library System
---
--- To run all tests automatically by the currycheck tool, use the command:
--- "currycheck testSystem"
------------------------------------------------------------------------------

import System
import Test.EasyCheck

-- Testing environment variable handling:

evar = "asd123"

testGetUndefinedEnviron = (getEnviron evar) `returns` ""

testSetEnviron = (setEnviron evar "SET" >> getEnviron evar) `returns` "SET"

testUnsetEnviron = (unsetEnviron evar >> getEnviron evar) `returns` ""

testSetShellEnviron =
  (setEnviron evar "SET" >> system ("test \"$"++evar++"\" = SET")) `returns` 0
