{-# LANGUAGE FunctionalDependencies,
             FlexibleInstances #-}

module Common'.C'select5 where

class C'select5 a b | a->b where
    select5    :: a -> b
    select5''M :: a -> IO b
