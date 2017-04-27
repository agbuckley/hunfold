{-# LANGUAGE NoMonomorphismRestriction #-}
{-# LANGUAGE RankNTypes                #-}

module MarkovChain
  ( module X
  , markovChain, metropolis
  ) where

import           Control.Monad.Primitive       as X (PrimMonad (..))
import           Pipes
import           Pipes.Prelude                 as P
import           System.Random.MWC             as X (Gen, asGenIO,
                                                     withSystemRandom)
import           System.Random.MWC.Probability

markovChain :: Monad m => (t -> m t) -> t -> Producer t m r
markovChain f = P.unfoldr $ \x -> Right <$> (fmap dup . f) x
  where dup x = (x, x)


metropolis
  :: PrimMonad m
  => (t -> Prob m t)
  -> (t -> Double)
  -> (t, Double)
  -> Producer (t, Double) (Prob m) r
metropolis prop logLH = markovChain $ metropolisStep prop logLH


metropolisStep
  :: PrimMonad m
  => (t -> Prob m t)
  -> (t -> Double)
  -> (t, Double)
  -> Prob m (t, Double)
metropolisStep proposal logLH (currloc, currllh) = do
  nextloc <- proposal currloc
  let nextllh = logLH nextloc
  accept <- bernoulli . exp . min 0 $ nextllh - currllh
  if accept
    then return (nextloc, nextllh)
    else return (currloc, currllh)
