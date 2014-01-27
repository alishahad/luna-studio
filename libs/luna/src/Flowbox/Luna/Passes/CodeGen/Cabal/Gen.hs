---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2014
---------------------------------------------------------------------------

module Flowbox.Luna.Passes.CodeGen.Cabal.Gen where

import qualified Data.List    as List
import           Data.Version (Version)

import           Flowbox.Luna.Data.Cabal.Config  (Config)
import qualified Flowbox.Luna.Data.Cabal.Config  as Config
import           Flowbox.Luna.Data.Cabal.Section (Section)
import qualified Flowbox.Luna.Data.Cabal.Section as Section
import           Flowbox.Luna.Data.Source        (Source)
import qualified Flowbox.Luna.Data.Source        as Source
import           Flowbox.Prelude



getModuleName :: Source -> String
getModuleName source = List.intercalate "." $ Source.path source


genLibrary :: String -> Version -> [String] -> [String] -> [String] -> [Source] -> Config
genLibrary name version ghcOptions cppOptions libs sources = genCommon sectionBase name version ghcOptions cppOptions libs where
    sectionBase = Section.mkLibrary { Section.exposedModules = map getModuleName sources }


genExecutable :: String -> Version -> [String] -> [String] -> [String] -> Config
genExecutable name version ghcOptions cppOptions libs = genCommon sectionBase name version ghcOptions cppOptions libs where
    sectionBase = Section.mkExecutable name


genCommon :: Section -> String -> Version -> [String] -> [String] -> [String] -> Config
genCommon sectionBase name version ghcOptions cppOptions libs = conf where
    section = sectionBase { Section.buildDepends = libs
                          , Section.ghcOptions   = ghcOptions
                          , Section.cppOptions   = cppOptions
                          }
    conf = Config.addSection section
         $ Config.make name version
