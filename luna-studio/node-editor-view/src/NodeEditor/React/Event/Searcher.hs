{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE StrictData     #-}
{-# LANGUAGE TypeFamilies   #-}

module NodeEditor.React.Event.Searcher where

import           Common.Data.Event (EventName)
import           Common.Prelude
import           Data.Aeson        (FromJSON)


data Event = InputChanged Text Int Int
           | Accept
           | AcceptInput
           | HintShortcut   Int
           | AcceptWithHint Int
           | Continue
           | ScrollPrev
           | ScrollNext
           | MoveLeft
            deriving (FromJSON, Generic, NFData, Show, Typeable)

instance EventName Event
