{-# LANGUAGE PolyKinds #-} -- Needed by Proxy P!
-- there is a bug, when reifying functions if PolyKind was enabled in some type classes module.

module Luna.Target.HS.Proxy where

data P a = P