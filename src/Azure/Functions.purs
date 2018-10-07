module Azure.Functions
  ( Context
  , AzureState, AzureM, AzureFunction
  , log, warn, error, logVerbose
  , mkAzureFunction
  ) where

import Prelude

import Control.Monad.Reader (ReaderT, asks, runReaderT)
import Control.Promise (Promise, fromAff)
import Data.Maybe (Maybe)
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
import Effect.Uncurried (EffectFn2, EffectFn3, mkEffectFn3, runEffectFn2)
import Node.Process as Process

foreign import data Context :: Type

foreign import _logInfo :: forall a. EffectFn2 Context a Unit
foreign import _logWarn :: forall a. EffectFn2 Context a Unit
foreign import _logError :: forall a. EffectFn2 Context a Unit
foreign import _logVerbose :: forall a. EffectFn2 Context a Unit
foreign import _setRes :: forall a. EffectFn2 Context a Unit

type AzureState t i = { context :: Context, trigger :: t, input :: i }

type AzureM t i a = ReaderT (AzureState t i) Aff a

newtype AzureFunction t i = AzureFunction (EffectFn3 Context t i (Promise Unit))

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

mkAzureFunction :: forall t i a. AzureM t i a -> AzureFunction t i
mkAzureFunction m = AzureFunction $ mkEffectFn3 \context trigger input ->
  fromAff $ liftEffect <<< runEffectFn2 _setRes context =<< runReaderT m { context, trigger, input }
