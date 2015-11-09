module Reactive.Commands.Selection where

import           Utils.PreludePlus
import           Control.Monad.State hiding (State)

import           Object.Object  (NodeId)
import           Object.Node    (Node)
import qualified Object.Widget.Node as NodeModel
import           Object.UITypes (WidgetId)
import           Object.Widget  (objectId, widget, WidgetFile(..))
import           Event.Keyboard (KeyMods(..))
import qualified JS.NodeGraph   as UI

import           Reactive.State.Global     (State)
import qualified Reactive.State.Global     as Global
import qualified Reactive.State.UIRegistry as UIRegistry
import qualified Reactive.State.Graph      as Graph

import           Reactive.Commands.Command          (Command, performIO)
import           Reactive.Commands.Graph            (allNodes)
import qualified Reactive.Commands.UIRegistry  as UICmd

unselectAll :: Command UIRegistry.State ()
unselectAll = do
    widgets <- allNodes
    let widgetIds = (^. objectId) <$> widgets
    forM_ widgetIds $ (flip UICmd.update) (NodeModel.isSelected .~ False)

selectAll :: Command UIRegistry.State ()
selectAll = do
    widgets <- allNodes
    let widgetIds = (^. objectId) <$> widgets
    forM_ widgetIds $ (flip UICmd.update) (NodeModel.isSelected .~ True)


selectedNodes :: Command UIRegistry.State [WidgetFile NodeModel.Node]
selectedNodes = do
    widgets <- allNodes
    return $ filter (^. widget . NodeModel.isSelected) widgets

focusSelectedNode :: Command UIRegistry.State ()
focusSelectedNode = do
    widgets <- selectedNodes
    UIRegistry.focusedWidget .= (view objectId <$> widgets ^? ix 0)
