{-# LANGUAGE DataKinds #-}

module Matrix
  ( module X
  , Vec, Mat
  , transpose, inner, dot, outer, (><)
  , multMM, multMV, multVM, tailV
  ) where

import           Data.Foldable
import           Data.Monoid
import           Data.Vector.Fixed.Cont as X (Arity (..), ContVec (..), S,
                                              ToPeano, Z)
import qualified Data.Vector.Fixed.Cont as V

type Vec = ContVec

instance (Show a, Arity n) => Show (ContVec n a) where
  show = show . toList

-- rows are innermost
type Mat n m a = Vec m (Vec n a)

transpose :: (Arity n, Arity m) => Mat n m a -> Mat m n a
transpose = sequenceA

inner :: (Monoid c, Foldable t, Applicative t)
      => (a -> b -> c) -> t a -> t b -> c
inner f v v' = fold $ f <$> v <*> v'

dot :: (Num a, Foldable t, Applicative t)
    => t a -> t a -> a
dot v v' = getSum $ inner (\x y -> Sum $ x * y) v v'

-- TODO
-- write these more generally
-- eg. I'm pretty sure these are special cases of tensor products (or something)

multMM :: (Traversable t1, Traversable t, Applicative t1, Applicative f, Num b)
       => t (t1 b) -> t1 (f b) -> f (t b)
multMM m m' = outer dot m $ sequenceA m'

multMV :: (Traversable t, Foldable f, Applicative f, Num b)
       => t (f b) -> f b -> t b
multMV = traverse dot

multVM :: (Traversable t1, Traversable t, Applicative t1, Applicative t, Num b)
       => t1 b -> t1 (t b) -> t b
multVM v m = traverse dot (sequenceA m) v

tailV :: ContVec (S n) a -> ContVec n a
tailV = V.tail

-- arbitrary cartesian product
infix 5 ><
(><) :: (Traversable t, Functor f) => t a -> f b -> f (t (a, b))
(><) = outer (,)

outer :: (Traversable t, Functor f)
      => (a1 -> a -> b) -> t a1 -> f a -> f (t b)
outer f v v' = traverse f v <$> v'