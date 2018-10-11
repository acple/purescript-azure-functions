module Azure.Functions
  ( Context
  , AzureState, AzureM, AzureFunction
  , log, warn, error, logVerbose
  , getSetting
  , mkAzureFunction
  ) where

import Prelude

import Control.Monad.Reader (ReaderT, asks, runReaderT)
import Control.Promise (Promise, fromAff)
import Data.Maybe (Maybe)
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
import Effect.Uncurried (EffectFn1, EffectFn2, mkEffectFn2, runEffectFn1, runEffectFn2)
import Node.Process as Process

foreign import data Context :: Type

foreign import _logInfo :: forall a. EffectFn2 Context a Unit
foreign import _logWarn :: forall a. EffectFn2 Context a Unit
foreign import _logError :: forall a. EffectFn2 Context a Unit
foreign import _logVerbose :: forall a. EffectFn2 Context a Unit
foreign import _getBindings :: forall a. EffectFn1 Context a

type AzureState t i = { context :: Context, trigger :: t, input :: Record i }

type AzureM t i a = ReaderT (AzureState t i) Aff a

newtype AzureFunction t (i :: # Type) a = AzureFunction (EffectFn2 Context t (Promise a))

_log :: forall t i a. EffectFn2 Context a Unit -> a -> AzureM t i Unit
_log f a = do
  context <- asks _.context
  liftEffect $ runEffectFn2 f context a

log :: forall t i a. a -> AzureM t i Unit
log = _log _logInfo

warn :: forall t i a. a -> AzureM t i Unit
warn = _log _logWarn

error :: forall t i a. a -> AzureM t i Unit
error = _log _logError

logVerbose :: forall t i a. a -> AzureM t i Unit
logVerbose = _log _logVerbose

getSetting :: forall t i. String -> AzureM t i (Maybe String)
getSetting = liftEffect <<< Process.lookupEnv

mkAzureFunction :: forall t i. AzureM t i ~> AzureFunction t i
mkAzureFunction m = AzureFunction $ mkEffectFn2 \context trigger -> do
  input <- runEffectFn1 _getBindings context
  fromAff $ runReaderT m { context, trigger, input }
