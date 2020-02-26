{-# LANGUAGE DeriveGeneric, DeriveAnyClass #-}
module KafkaTypes where

import Data.Aeson
import Data.Int
import Data.Map ( Map )
import qualified Data.ByteString            as B
import qualified Data.ByteString.Lazy.Char8 as LC
import qualified Data.Map                   as Map
import qualified Data.Text                  as T
import qualified Data.Text.Encoding         as TE
import GHC.Generics
import Kafka.Consumer
import Kafka.Metadata

type PartitionOffsets = Map Int TopicOffsets

data TopicOffsets = TopicOffsets { lowest :: Int64 , highest :: Int64 } deriving (Show)

data ConsumedRecord = ConsumedRecord
  { key       :: Value
  , value     :: Value
  , topic     :: T.Text
  , partition :: Int
  , offset    :: Int64 } deriving (Show, Generic, ToJSON)

-------------------------------------------------------------------

offsetsFromWatermarks :: [WatermarkOffsets] -> PartitionOffsets
offsetsFromWatermarks wos = Map.fromList $ toOffsets <$> wos
  where
    toOffsets :: WatermarkOffsets -> (Int, TopicOffsets)
    toOffsets (WatermarkOffsets _ (PartitionId p) (Offset l) (Offset h))= (p, TopicOffsets l h)

toRecord :: ConsumerRecord (Maybe B.ByteString) (Maybe B.ByteString) -> ConsumedRecord
toRecord (ConsumerRecord (TopicName t) (PartitionId p) (Offset o) _ k v) =
  ConsumedRecord (toStringJson k) (toStringJson v) t p o
    where
      toStringJson :: (Maybe B.ByteString) -> Value
      toStringJson Nothing   = Null
      toStringJson (Just bs) = case (decode $ LC.fromStrict bs :: Maybe Value) of
                          Just j  -> j
                          Nothing -> String $ TE.decodeUtf8 bs
