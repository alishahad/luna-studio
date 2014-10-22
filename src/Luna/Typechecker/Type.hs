module Luna.Typechecker.Type (
    Scheme(..), Type(..), Tyvar(..), Tycon(..),
    tChar, tDouble, tInt, tString,
    mkTyList, mkTyFun,
    instantiate
  ) where

import Luna.Typechecker.IDs         (TyID(..))
import Luna.Typechecker.Type.Type   (Type(..),Tyvar(..),Tycon(..))
import Luna.Typechecker.Type.Scheme (Scheme(..),instantiate)



tChar, tDouble, tInt, tString :: Type
tChar   = TConst (Tycon (TyID "Char"))
tDouble = TConst (Tycon (TyID "Double"))
tInt    = TConst (Tycon (TyID "Int"))
tString = mkTyList tChar


tList, tFun :: Type
tList = TConst (Tycon (TyID "[]"))
tFun  = TConst (Tycon (TyID "(->)"))

mkTyList :: Type -> Type
mkTyList = TAp tList

mkTyFun :: Type -> Type -> Type
mkTyFun = TAp . TAp tFun