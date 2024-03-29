------------------------------------------------------------------------------
--- Library to support meta-programming in Curry.
---
--- This library contains a definition for representing Haskell or Curry
--- programs in Curry (type "Prog").
---
--- Note: this definition contains support for type classes which
--- are currently not part of Curry but can be used to generate also
--- Haskell programs. It also contains representation of logic variables
--- which are not part of Haskell.
---
--- @author Michael Hanus, Björn Peemöller
--- @version May 2015
------------------------------------------------------------------------------

module AbstractHaskell where

------------------------------------------------------------------------------
-- Definition of data types for representing abstract Curry programs:
-- ==================================================================

--- Data type for representing a Curry module in the intermediate form.
--- A value of this data type has the form
--- <CODE>
---  (CProg modname imports typedecls functions opdecls)
--- </CODE>
--- where modname: name of this module,
---       imports: list of modules names that are imported,
---       typedecls, opdecls, functions: see below
data Prog = Prog String [String] [TypeDecl] [FuncDecl] [OpDecl]

--- The data type for representing qualified names.
--- In AbstractHaskell all names are qualified to avoid name clashes.
--- The first component is the module name and the second component the
--- unqualified name as it occurs in the source program.
type QName = (String, String)

--- Data type to specify the visibility of various entities.
data Visibility = Public    -- exported entity
                | Private   -- private entity

--- The data type for representing type variables.
--- They are represented by (i,n) where i is a type variable index
--- which is unique inside a function and n is a name (if possible,
--- the name written in the source program).
type TVarIName = (Int, String)

--- Data type for representing definitions of algebraic data types
--- and type synonyms.
---
--- A data type definition of the form
---
--- <code>data t x1...xn = ...| c t1....tkc |...</code>
---
--- is represented by the Curry term
---
--- <code>(Type t v [i1,...,in] [...(ons c kc v [t1,...,tkc])...])</code>
---
--- where each <code>ij</code> is the index of the type variable
--- <code> xj</code>.
---
--- Note: the type variable indices are unique inside each type declaration
---       and are usually numbered from 0
---
--- Thus, a data type declaration consists of the name of the data type,
--- a list of type parameters and a list of constructor declarations.
data TypeDecl
  = Type     QName Visibility [TVarIName] [ConsDecl]
  | TypeSyn  QName Visibility [TVarIName] TypeExpr
  | Instance QName TypeExpr [Context] [(QName, Rule)]

--- A single type context is class name applied to type variables.
data Context = Context QName [TVarIName]

--- A constructor declaration consists of the name and arity of the
--- constructor and a list of the argument types of the constructor.
data ConsDecl = Cons QName Int Visibility [TypeExpr]


--- Data type for type expressions.
--- A type expression is either a type variable, a function type,
--- or a type constructor application.
---
--- Note: the names of the predefined type constructors are
---       "Int", "Float", "Bool", "Char", "IO", "Success",
---       "()" (unit type), "(,...,)" (tuple types), "[]" (list type)
data TypeExpr
  = TVar TVarIName              -- type variable
  | FuncType TypeExpr TypeExpr  -- function type t1->t2
  | TCons QName [TypeExpr]      -- type constructor application
                                -- (TCons (module,name) arguments)

--- Data type to represent the type signature of a defined function.
--- The type can be missing or a type with an optional context.
data TypeSig
  = Untyped
  | CType [Context] TypeExpr

--- Data type for operator declarations.
--- An operator declaration "fix p n" in Curry corresponds to the
--- AbstractHaskell term (Op n fix p).
data OpDecl = Op QName Fixity Int

data Fixity
  = InfixOp   -- non-associative infix operator
  | InfixlOp  -- left-associative infix operator
  | InfixrOp  -- right-associative infix operator

--- Data types for representing object variables.
--- Object variables occurring in expressions are represented by (Var i)
--- where i is a variable index.
type VarIName = (Int, String)

--- Data type for representing function declarations.
---
--- A function declaration in AbstractHaskell is a term of the form
---
--- <code>
--- (Func cmt name arity visibility type (Rules eval [Rule rule1,...,rulek]))
--- </code>
---
--- and represents the function <code>name</code> defined by the rules
--- <code>rule1,...,rulek</code>.
---
--- Note: the variable indices are unique inside each rule
---
--- External functions are represented as
--- <code>(Func cmt name arity type External)</code>.
---
--- Thus, a function declaration consists of the comment, name, arity, type,
--- and a list of rules. The type is optional according to its occurrence in
--- the source text. The comment could be used
--- by pretty printers that generate a readable Curry program
--- containing documentation comments.
data FuncDecl = Func String QName Int Visibility TypeSig Rules

--- Rules are either a list of single rules or no rule at all
--- if then function is defined externally.
data Rules
  = Rules [Rule]
  | External

--- The most general form of a rule. It consists of a list of patterns
--- (left-hand side), a list of guards ("success" if not present in the
--- source text) with their corresponding right-hand sides, and
--- a list of local declarations.
data Rule = Rule [Pattern] Rhs [LocalDecl]

data Rhs
  = SimpleRhs  Expr
  | GuardedRhs [(Expr, Expr)]

--- Data type for representing local (let/where) declarations
data LocalDecl
  = LocalFunc FuncDecl                 -- local function declaration
  | LocalPat  Pattern Expr [LocalDecl] -- local pattern declaration

--- Data type for representing Haskell expressions.
data Expr
  = Var        VarIName          -- variable (unique index / name)
  | Lit        Literal           -- literal (Integer/Float/Char constant)
  | Symbol     QName             -- a defined symbol with module and name
  | Apply      Expr Expr         -- application (e1 e2)
  | InfixApply Expr QName Expr   -- infix application
  | Lambda     [Pattern] Expr    -- lambda abstraction
  | Let        [LocalDecl] Expr  -- local let declarations
  | DoExpr     [Statement]       -- do expression
  | ListComp   Expr [Statement]  -- list comprehension
  | Case       Expr [BranchExpr] -- case expression
  | Typed      Expr TypeExpr     -- typed expression
  | IfThenElse Expr Expr Expr    -- if-then-else expression
  | Tuple      [Expr]
  | List       [Expr]

--- Data type for representing statements in do expressions and
--- list comprehensions.
data Statement
  = SExpr Expr        -- an expression (I/O action or boolean)
  | SPat Pattern Expr -- a pattern definition
  | SLet [LocalDecl]  -- a local let declaration

--- Data type for representing pattern expressions.
data Pattern
  = PVar VarIName              -- pattern variable (unique index / name)
  | PLit Literal               -- literal (Integer/Float/Char constant)
  | PComb QName [Pattern]      -- application (m.c e1 ... en) of n-ary
                               -- constructor m.c (PComb (m,c) [e1,...,en])
  | PAs VarIName Pattern       -- as-pattern (extended Curry)
  | PTuple [Pattern]
  | PList [Pattern]

--- Data type for representing branches in case expressions.
data BranchExpr = Branch Pattern Expr

--- Data type for representing literals occurring in an expression.
--- It is either an integer, a float, a character, or a string constant.
data Literal
  = Intc    Int
  | Floatc  Float
  | Charc   Char
  | Stringc String
