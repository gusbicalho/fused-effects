{-# LANGUAGE DeriveFunctor, FlexibleContexts, FlexibleInstances, MultiParamTypeClasses, PolyKinds, TypeOperators, UndecidableInstances #-}
module Control.Effect.Trace
( Trace(..)
, trace
, runPrintingTrace
) where

import Control.Effect.Handler
import Control.Effect.Internal
import Control.Effect.Sum
import Control.Monad.IO.Class
import System.IO

data Trace m k = Trace String k
  deriving (Functor)

instance HFunctor Trace where
  hfmap _ (Trace s k) = Trace s k

instance Effect Trace where
  handle state handler (Trace s k) = Trace s (handler (k <$ state))

trace :: (Subset Trace sig, Effectful sig m) => String -> m ()
trace message = send (Trace message (pure ()))


runPrintingTrace :: (MonadIO m, Effectful sig m) => Eff (PrintingH m) a -> m a
runPrintingTrace = runPrintingH . interpret

newtype PrintingH m a = PrintingH { runPrintingH :: m a }

instance (MonadIO m, Carrier sig m) => Carrier (Trace :+: sig) (PrintingH m) where
  gen = PrintingH . gen
  alg = algT \/ (PrintingH . alg . handlePure runPrintingH)
    where algT (Trace s k) = PrintingH (liftIO (hPutStrLn stderr s) *> runPrintingH k)
