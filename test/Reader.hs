{-# LANGUAGE RankNTypes #-}
module Reader
( genReader
, tests
) where

import qualified Control.Carrier.Reader.Function as ReaderC
import Control.Effect.Reader
import qualified Control.Monad.Trans.Reader as ReaderT
import Data.Function ((&))
import Pure
import Hedgehog
import Hedgehog.Function
import Hedgehog.Gen
import Test.Tasty
import Test.Tasty.Hedgehog

tests :: TestTree
tests = testGroup "Reader"
  [ testReader "ReaderC" ReaderC.runReader         genA
  , testReader "(->)"    (fmap PureC . (&))        genA
  , testReader "ReaderT" (flip ReaderT.runReaderT) genA
  ]


genReader :: (Has (Reader a) sig m, Arg a, Vary a) => Gen a -> Gen (m a) -> Gen (m a)
genReader a ma = choice
  [ pure ask
  , fn a >>= subterm ma . local . apply
  ]


testReader :: (Has (Reader r) sig m, Arg r, Eq r, Show r, Vary r) => String -> (forall a . r -> m a -> PureC a) -> Gen r -> TestTree
testReader name runReader genA = testGroup name
  [ testProperty "ask environment" . forall (genA :. fn (Blind <$> genM genReader genA) :. Nil) $
    \ a k -> ask_environment (~=) runReader a (getBlind . apply k)
  , testProperty "local modification" . forall (genA :. fn genA :. fmap Blind (genM genReader genA) :. Nil) $
    \ a f m -> local_modification (~=) runReader a (apply f) (getBlind m)
  ]
