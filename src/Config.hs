module Config where

import qualified Data.Text as T

data ConsumerConfig = ConsumerConfig
  { brokers           :: T.Text
  , topic             :: T.Text
  , keyDeserializer   :: SupportedType
  , valueDeserializer :: SupportedType
  , schemaRegistryUrl :: Maybe String } deriving (Show)

data SupportedType = STRING | LONG | AVRO deriving (Show)
