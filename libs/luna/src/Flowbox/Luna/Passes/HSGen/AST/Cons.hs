---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2013
---------------------------------------------------------------------------

module Flowbox.Luna.Passes.HSGen.AST.Cons (
	module Flowbox.Luna.Passes.HSGen.AST.Cons,
	module Flowbox.Luna.Passes.HSGen.AST.Expr
)where

import           Flowbox.Prelude                      
import           Flowbox.Luna.Passes.HSGen.AST.Expr   

empty :: Expr
empty = Cons "" []
