---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2013
---------------------------------------------------------------------------

module Flowbox.Batch.Batch (
    Batch(..),
    empty,

    projects,
    createProject,
    openProject,
    closeProject,
    storeProject,
    setActiveProject,

    libraries,
    loadLibrary,
    unloadLibrary,
    storeLibrary,
    libraryRootDef

) where


import qualified Flowbox.Batch.Project.Project            as Project
import           Flowbox.Batch.Project.Project              (Project(..))
import qualified Flowbox.Batch.Project.ProjectManager     as ProjectManager
import           Flowbox.Batch.Project.ProjectManager       (ProjectManager)
import qualified Flowbox.Luna.Core                        as Core
import           Flowbox.Luna.Core                          (Core(..))
import qualified Flowbox.Luna.Lib.LibManager              as LibManager
import           Flowbox.Luna.Lib.LibManager                (LibManager)
import qualified Flowbox.Luna.Lib.Library                 as Library
import           Flowbox.Luna.Lib.Library                   (Library(..))
import qualified Flowbox.Luna.Network.Attributes          as Attributes
import           Flowbox.Luna.Network.Attributes            (Attributes)
import qualified Flowbox.Luna.Network.Def.DefManager      as DefManager
import           Flowbox.Luna.Network.Def.DefManager        (DefManager)
import qualified Flowbox.Luna.Network.Def.Definition      as Definition
import           Flowbox.Luna.Network.Def.Definition        (Definition(..))
import qualified Flowbox.Luna.Network.Flags               as Flags
import qualified Flowbox.Luna.Network.Graph.Graph         as Graph
import           Flowbox.Luna.Network.Graph.Graph           (Graph)
import qualified Flowbox.Luna.Network.Graph.Node          as Node
import           Flowbox.Luna.Network.Graph.Node            (Node(..))
import qualified Flowbox.Luna.System.UniPath              as UniPath
import           Flowbox.Luna.System.UniPath                (UniPath)
import qualified Flowbox.Luna.Type.Type                   as Type



data Batch = Batch { projectManager  :: ProjectManager
                   , activeProjectID :: Project.ID
                   }


empty :: Batch
empty = Batch ProjectManager.empty (-1)


activeProject :: Batch -> Maybe Project
activeProject (Batch pm apID) = do
    project <- ProjectManager.lab pm apID
    return project


activeProjectOp :: (Batch -> (Project.ID, Project) -> Either String (Project, r)) 
                         -> Batch
                         -> Either String (Batch, r)
activeProjectOp operation batch = 
    case activeProject batch of 
        Nothing                   -> Left "No active project set."
        Just project              -> let projectID = activeProjectID batch
                                     in case operation batch (projectID, project) of
            Left message          -> Left message
            Right (newProject, r) -> Right (newBatch, r) where
                                         aprojectManager   = projectManager batch
                                         newProjectManager = ProjectManager.updateNode (projectID, newProject) aprojectManager
                                         newBatch          = batch { projectManager = newProjectManager }

activeProjectOp' :: (Batch -> (Project.ID, Project) -> IO (Either String (Project, r)))
                 -> Batch
                 -> IO (Either String (Batch, r))
activeProjectOp' operation batch = 
    case activeProject batch of 
        Nothing                   -> return $ Left "No active project set."
        Just project              -> do 
            let projectID = activeProjectID batch
            opr <- operation batch (projectID, project)
            case opr of
                Left message          -> return $ Left message
                Right (newProject, r) -> do let aprojectManager   = projectManager batch
                                                newProjectManager = ProjectManager.updateNode (projectID, newProject) aprojectManager
                                                newBatch          = batch { projectManager = newProjectManager }
                                            return $ Right (newBatch, r)



activeCoreOp :: (Batch -> Core -> Either String (Core, r))
             -> Batch
             -> Either String (Batch, r)
activeCoreOp operation = 
    activeProjectOp (\batch (_, project) -> let
        core = Project.core project
        in case operation batch core of 
            Left message       -> Left message
            Right (newCore, r) -> Right (newProject, r) where
                                        newProject = project {Project.core = newCore})


activeCoreOp' :: (Batch -> Core -> IO (Either String (Core, r)))
              -> Batch
              -> IO (Either String (Batch, r))
activeCoreOp' operation = 
    activeProjectOp' (\batch (_, project) -> do
        let core = Project.core project
        opr <- operation batch core
        case opr of 
            Left message       -> return $ Left message
            Right (newCore, r) -> do let newProject = project {Project.core = newCore}
                                     return $ Right (newProject, r))


activeLibManagerOp :: (Batch -> LibManager -> Either String (LibManager, r))
                   -> Batch 
                   -> Either String (Batch, r)
activeLibManagerOp operation = 
    activeCoreOp (\batch core -> let
        libManager = Core.libManager core
        in case operation batch libManager of 
            Left message             -> Left message
            Right (newLibManager, r) -> Right (newCore, r) where
                                            newCore = core { Core.libManager = newLibManager })

activeDefManagerOp :: (Batch -> DefManager -> Either String (DefManager, r))
                   -> Batch 
                   -> Either String (Batch, r)
activeDefManagerOp operation = 
    activeCoreOp (\batch core -> let
        defManager = Core.defManager core
        in case operation batch defManager of 
            Left message             -> Left message
            Right (newDefManager, r) -> Right (newCore, r) where
                                            newCore = core { Core.defManager = newDefManager })



readonly :: Either String (a, r) -> Either String r
readonly op = case op of 
    Left message -> Left message
    Right (_, r) -> Right r


readonly' :: IO (Either String (a, r)) -> IO (Either String r)
readonly' op = do
    o <- op
    case o of 
        Left message -> return $ Left message
        Right (_, r) -> return $ Right r


noresult :: Either String (a, r) -> Either String a
noresult op = case op of 
    Left message -> Left message
    Right (a, _) -> Right a


-------- Projects -------------------------------------------------------------

projects :: Batch -> [(Project.ID, Project)]
projects batch = projectList where
    aprojectManager = projectManager batch
    projectList     = ProjectManager.projects aprojectManager


createProject :: Batch -> Project -> IO ()
createProject _ = ProjectManager.createProject


openProject :: Batch -> Project -> IO (Batch, (Project.ID, Project))
openProject batch project = do
    let aprojectManager = projectManager batch
    (newProjectManager, newP) <- ProjectManager.openProject aprojectManager project
    let newBatch = batch {projectManager = newProjectManager}
    return (newBatch, newP)



closeProject :: Batch -> Project.ID -> IO Batch
closeProject batch projectID = do
    let aprojectManager = projectManager batch
    newProjectManager <- ProjectManager.closeProject aprojectManager projectID
    let newBatch = batch {projectManager = newProjectManager}
    return newBatch



storeProject :: Batch -> Project.ID -> IO ()
storeProject batch projectID = do
    let aprojectManager = projectManager batch
    _ <- ProjectManager.storeProject aprojectManager projectID
    return ()


setActiveProject :: Batch -> Project.ID -> Batch
setActiveProject batch projectID = newBatch where
    newBatch = batch { activeProjectID = projectID }


-------- Libraries ------------------------------------------------------------

libraries :: Batch -> Either String [(Library.ID, Library)]
libraries = readonly . activeLibManagerOp (\batch libManager -> let 
    r = LibManager.labNodes libManager 
    in Right (libManager, r))

--createLibrary :: Batch -> Library -> Library ???
--createLibrary _ library = library


loadLibrary :: Library -> Batch -> IO (Either String (Batch, (Library.ID, Library)))
loadLibrary library = activeCoreOp' (\batch core -> do
    let (newCore, newLibrary, newLibID) = Core.loadLibrary core library
    return $ Right (newCore, (newLibID, newLibrary)))


unloadLibrary :: Library.ID -> Batch -> Either String Batch
unloadLibrary libraryID = noresult . activeCoreOp (\batch core ->let 
    newCore = Core.unloadLibrary core libraryID
    in Right (newCore, ()))


storeLibrary :: Library.ID -> Batch -> IO (Either String ())
storeLibrary libraryID = readonly' . activeCoreOp' (\batch core -> do
    putStrLn "call storeLibrary - NOT YET IMPLEMENTED"
    return $ Right (core, ()))


libraryRootDef :: Library.ID -> Batch -> Either String (Definition.ID, Definition)
libraryRootDef libraryID = readonly . activeCoreOp (\batch core -> let 
    libManager = Core.libManager core
    in case LibManager.lab libManager libraryID of 
        Nothing      -> Left "Wrong `libraryID"
        Just library -> let 
            rootDefID' = Library.rootDefID library 
            in case Core.nodeDefByID core rootDefID' of
                Nothing      -> Left "Wrong `rootDefID`"
                Just rootDef -> Right (core, (rootDefID', rootDef)))


-------- Definitions ----------------------------------------------------------

defsGraph :: Batch -> Either String DefManager
defsGraph = readonly . activeDefManagerOp (\_ defManager -> Right (defManager, defManager) )


--newDefinition :: IORef Project -> Maybe TTypes.Type -> Maybe (Vector Import)
--                            -> Maybe Attrs_Types.Flags -> Maybe Attrs_Types.Attributes
--                            -> IO Definition
--newDefinition _ ttype timports tflags tattrs = do 
--    putStrLn "Creating new definition...\t\tsuccess!"
--    return $ Definition ttype timports tflags tattrs (Just 0) (Just 0)


addDefinition :: Definition -> Definition.ID -> Batch -> Either String (Batch, Definition.ID)
addDefinition definition parentID = activeDefManagerOp (\batch defManager ->
    case DefManager.gelem parentID defManager of 
        False -> Left "Wrong `defID`"
        True  -> Right (newDefManager, defID) where
                        [defID]       = DefManager.newNodes 1 defManager
                        newDefManager = DefManager.addToParent (parentID, defID, definition) defManager)


updateDefinition :: (Definition.ID, Definition) -> Batch -> Either String Batch
updateDefinition (defID, def) = noresult .activeDefManagerOp (\batch defManager ->
    -- putStrLn "call updateDefinition - NOT IMPLEMENTED, sorry."
    Right (defManager, ()))


removeDefinition :: Definition.ID -> Batch -> Either String Batch 
removeDefinition defID = noresult . activeDefManagerOp (\batch defManager -> 
    case DefManager.gelem defID defManager of 
        False -> Left "Wrong `defID`"
        True  -> Right (newDefManager, ()) where 
                        newDefManager = DefManager.delNode defID defManager)


definitionChildren :: Definition.ID -> Batch -> Either String [(Definition.ID, Definition)]
definitionChildren defID = readonly . activeDefManagerOp (\batch defManager -> 
    case DefManager.gelem defID defManager of 
        False -> Left "Wrong `defID`"
        True  -> Right (defManager, children) where
                       children = DefManager.children defManager defID)


definitionParent :: Definition.ID -> Batch -> Either String (Definition.ID, Definition)
definitionParent defID = readonly . activeDefManagerOp (\batch defManager -> 
    case DefManager.gelem defID defManager of 
        False           -> Left "Wrong `defID`"
        True            -> case DefManager.parent defManager defID of
            Nothing     -> Left "Definition has no parent"
            Just parent -> Right (defManager, parent))


-------- Graphs ---------------------------------------------------------------

graph :: Definition.ID -> Batch -> Either String Graph
graph defID = readonly . activeDefManagerOp (\batch defManager -> 
    case DefManager.lab defManager defID of 
        Nothing  -> Left "Wrong `defID`"
        Just def -> Right (defManager, Definition.graph def))


addNode :: Node -> Definition.ID -> Batch -> Either String (Batch, (Node.ID, Node))
addNode node defID = activeDefManagerOp (\batch defManager -> 
    case DefManager.lab defManager defID of 
        Nothing         -> Left "Wrong `defID`"
        Just definition -> Right (newDefManager, (nodeID, node)) where
            agraph        = Definition.graph definition
            [nodeID]      = Graph.newNodes 1 agraph
            newGraph      = Graph.insNode (nodeID, node) agraph
            newDefinition = definition {Definition.graph =  newGraph}
            newDefManager = DefManager.updateNode (defID, newDefinition) defManager)


updateNode :: (Node.ID, Node) -> Definition.ID -> Batch -> Either String Batch
updateNode (nodeID, node) defID = noresult . activeDefManagerOp (\batch defManager -> 
    case DefManager.lab defManager defID of 
        Nothing         -> Left "Wrong `defID`"
        Just definition -> let agraph = Definition.graph definition
            in case Graph.gelem nodeID agraph of 
                False -> Left "Wrong `nodeID`"
                True  -> Right (newDefManager, ()) where
                     newGraph      = Graph.updateNode (nodeID, node) agraph
                     newDefinition = definition {Definition.graph =  newGraph}
                     newDefManager = DefManager.updateNode (defID, newDefinition) defManager)


removeNode :: Node.ID -> Definition.ID -> Batch -> Either String Batch
removeNode nodeID defID = noresult . activeDefManagerOp (\batch defManager -> 
    case DefManager.lab defManager defID of 
        Nothing         -> Left "Wrong `defID`"
        Just definition -> let agraph = Definition.graph definition
            in case Graph.gelem nodeID agraph of 
                False -> Left "Wrong `nodeID`"
                True  -> Right (newDefManager, ()) where
                    newGraph      = Graph.delNode nodeID agraph
                    newDefinition = definition {Definition.graph =  newGraph}
                    newDefManager = DefManager.updateNode (defID, newDefinition) defManager)


--connect :: IORef Project -> Maybe TGraph.Node -> Maybe TGraph.PortDescriptor
--                      -> Maybe TGraph.Node -> Maybe TGraph.PortDescriptor
--        -> Maybe TDefs.Definition -> IO ()
--connect = nodesConnectOperation (\batchHandler (srcNodeID, srcNode) srcPort 
--                                               (dstNodeID, dstNode) dstPort definition -> do 
--    putStrLn "call connect - NOT IMPLEMENTED")


--disconnect :: IORef Project -> Maybe TGraph.Node -> Maybe TGraph.PortDescriptor
--                         -> Maybe TGraph.Node -> Maybe TGraph.PortDescriptor
--           -> Maybe TDefs.Definition -> IO ()
--disconnect = nodesConnectOperation (\batchHandler (srcNodeID, srcNode) srcPort
--                                                  (dstNodeID, dstNode) dstPort definition -> do 
--    putStrLn "call disconnect - NOT IMPLEMENTED")
