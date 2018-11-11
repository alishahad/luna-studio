module LunaStudio.Data.Visualizer where

import Prologue hiding (Text, TypeRep)

import qualified Data.Aeson                 as Aeson
import qualified Data.ByteString.Lazy.Char8 as BS
import qualified Data.Map                   as Map
import qualified Data.Text                  as Text

import Control.Lens            (Getter, makePrisms, to)
import Control.Lens.Aeson      (parseDropUnary, toEncodingDropUnary)
import Data.Aeson.Types        (FromJSON, ToJSON)
import Data.Binary             (Binary)
import Data.Map                (Map)
import Data.Maybe              (maybeToList)
import Data.Text               (Text)
import LunaStudio.Data.TypeRep (TypeRep (TCons), toConstructorRep)


type VisualizerName = Text
type VisualizerPath = Text
type LibraryName    = Text


data RawVisualizer = RawVisualizer
    { name :: Maybe VisualizerName
    , path :: VisualizerPath
    } deriving (Eq, Generic, Show)

instance ToJSON   RawVisualizer
instance NFData   RawVisualizer
instance FromJSON RawVisualizer

type VisualizerMatcher = TypeRep -> IO [RawVisualizer]

data VisualizerType
    = InternalVisualizer
    | LunaVisualizer
    | ProjectVisualizer
    | ImportedVisualizer LibraryName
    deriving (Eq, Generic, Ord, Read, Show)

makePrisms ''VisualizerType
instance NFData   VisualizerType
instance Binary   VisualizerType
instance FromJSON VisualizerType where parseJSON  = parseDropUnary
instance ToJSON   VisualizerType where toEncoding = toEncodingDropUnary

data VisualizerId = VisualizerId
    { _visualizerType :: VisualizerType
    , _visualizerName :: VisualizerName
    } deriving (Eq, Generic, Ord, Read, Show)

makeLenses ''VisualizerId
instance Binary   VisualizerId
instance NFData   VisualizerId
instance FromJSON VisualizerId where parseJSON  = parseDropUnary
instance ToJSON   VisualizerId where toEncoding = toEncodingDropUnary

data Visualizer = Visualizer
    { _visualizerId      :: VisualizerId
    , _visualizerRelPath :: VisualizerPath
    } deriving (Eq, Generic, Ord, Show)

makeLenses ''Visualizer

instance NFData   Visualizer
instance Binary   Visualizer
instance FromJSON Visualizer
instance ToJSON   Visualizer

data ExternalVisualizers a = ExternalVisualizers
    { _projectVisualizers   :: Maybe a
    , _librariesVisualizers :: Map LibraryName a
    } deriving (Eq, Foldable, Functor, Generic, Show, Traversable)

makeLenses ''ExternalVisualizers

instance Binary   a => Binary   (ExternalVisualizers a)
instance NFData   a => NFData   (ExternalVisualizers a)
instance FromJSON a => FromJSON (ExternalVisualizers a)
instance ToJSON   a => ToJSON   (ExternalVisualizers a)
instance Default  a => Default  (ExternalVisualizers a) where
    def = ExternalVisualizers mempty mempty



mapExternalVisualizers :: (a -> b) -> (a -> b) -> ExternalVisualizers a
    -> ExternalVisualizers b
mapExternalVisualizers projectF libsF vis = ExternalVisualizers
    (projectF <$> vis ^. projectVisualizers)
    (libsF    <$> vis ^. librariesVisualizers)

mapExternalVisualizersM :: Monad m
    => (a -> m b) -> (a -> m b) -> ExternalVisualizers a
    -> m (ExternalVisualizers b)
mapExternalVisualizersM = sequence .:. mapExternalVisualizers

mapExternalVisualizersWithKey
    :: (a -> b) -> (LibraryName -> a -> b) -> ExternalVisualizers a
    -> ExternalVisualizers b
mapExternalVisualizersWithKey projectF libsF vis = ExternalVisualizers
    (projectF            <$> vis ^. projectVisualizers)
    (Map.mapWithKey libsF $  vis ^. librariesVisualizers)

mapExternalVisualizersWithKeyM :: Monad m
    => (a -> m b) -> (LibraryName -> a -> m b) -> ExternalVisualizers a
    -> m (ExternalVisualizers b)
mapExternalVisualizersWithKeyM = sequence .:. mapExternalVisualizersWithKey


data Visualizers a = Visualizers
    { _internalVisualizers :: a
    , _lunaVisualizers     :: a
    , _externalVisualizers :: ExternalVisualizers a
    } deriving (Eq, Foldable, Functor, Generic, Show, Traversable)

makeLenses ''Visualizers
instance Binary   a => Binary   (Visualizers a)
instance NFData   a => NFData   (Visualizers a)
instance FromJSON a => FromJSON (Visualizers a)
instance ToJSON   a => ToJSON   (Visualizers a)
instance Default  a => Default  (Visualizers a) where
    def = Visualizers def def def


mapVisualizers :: (a -> b) -> (a -> b) -> (a -> b) -> (a -> b) -> Visualizers a
    -> Visualizers b
mapVisualizers internalF lunaF projectF libsF vis = Visualizers
    (internalF                             $ vis ^. internalVisualizers)
    (lunaF                                 $ vis ^. lunaVisualizers)
    (mapExternalVisualizers projectF libsF $ vis ^. externalVisualizers)

mapVisualizersM :: Monad m
    => (a -> m b) -> (a -> m b) -> (a -> m b) -> (a -> m b) -> Visualizers a
    -> m (Visualizers b)
mapVisualizersM = sequence .::. mapVisualizers

mapVisualizersWithKey
    :: (a -> b) -> (a -> b) -> (a -> b) -> (LibraryName -> a -> b)
    -> Visualizers a
    -> Visualizers b
mapVisualizersWithKey internalF lunaF projectF libsF vis = Visualizers
    (internalF                                    $ vis ^. internalVisualizers)
    (lunaF                                        $ vis ^. lunaVisualizers)
    (mapExternalVisualizersWithKey projectF libsF $ vis ^. externalVisualizers)

mapVisualizersWithKeyM :: Monad m
    => (a -> m b) -> (a -> m b) -> (a -> m b) -> (LibraryName -> a -> m b)
    -> Visualizers a
    -> m (Visualizers b)
mapVisualizersWithKeyM = sequence .::. mapVisualizersWithKey


errorVisId, mdVisId, placeholderVisId :: VisualizerId
errorVisId       = VisualizerId InternalVisualizer "internal: error"
mdVisId          = VisualizerId LunaVisualizer     "base: markdown"
placeholderVisId = VisualizerId InternalVisualizer "internal: placeholder"

transformJSVisualizerMatcher :: MonadIO m
    => (String -> m String) -> TypeRep -> m [RawVisualizer]
transformJSVisualizerMatcher f r = case toConstructorRep r of
    Nothing -> pure def
    Just r' -> fromJust def . Aeson.decode . BS.pack
        <$> f (BS.unpack $ Aeson.encode r')

convertRawVisualizer
    :: VisualizerId -> RawVisualizer -> (VisualizerId, VisualizerPath)
convertRawVisualizer k (RawVisualizer Nothing  p) = (k, p)
convertRawVisualizer k (RawVisualizer (Just n) p)
    = (k & visualizerName %~ Text.concat . (:[": ", n]), p)

fromJSVisualizersMap :: Map String (String -> IO String)
    -> Map VisualizerName VisualizerMatcher
fromJSVisualizersMap = fromList . fmap convertToEntry . toList where
    convertToEntry (k, v) = (convert k, transformJSVisualizerMatcher v)

applyType :: MonadIO m => TypeRep -> Map VisualizerId VisualizerMatcher
    -> m (Map VisualizerId VisualizerPath)
applyType tpe = fmap toMap . liftIO . mapM applyToEntry . toList where
    toMap = fromList . concat
    applyToEntry (k, f) = fmap2 (convertRawVisualizer k) $ f tpe

fromJSInternalVisualizersMap :: Map String String -> Map VisualizerId VisualizerPath
fromJSInternalVisualizersMap = fromList . concatMap convertJSON . toList where
    convertJSON (k, v)
        =   convertRawVisualizer (VisualizerId InternalVisualizer (convert k))
        <$> (fromJust [] . Aeson.decode $ BS.pack v)

getMdVisualizer :: MonadIO m
    => Map VisualizerId VisualizerMatcher -> m (Maybe Visualizer)
getMdVisualizer visMap = fmap (Visualizer mdVisId) . Map.lookup mdVisId
    <$> applyType (TCons "Text" def) visMap
