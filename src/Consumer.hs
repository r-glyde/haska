module Consumer ( run ) where

import Config
import KafkaTypes

import Control.Exception ( bracket )
import Control.Monad ( unless )
import Data.Aeson
import Data.Either
import qualified Data.Map                   as Map
import qualified Data.ByteString.Lazy.Char8 as LC
import qualified Data.Text                  as T
import qualified Kafka.Consumer             as KC
import qualified Kafka.Metadata             as KM

run :: ConsumerConfig -> IO ()
run (ConsumerConfig b t _ _ _) =
    bracket mkConsumer clConsumer runHandler >> return ()
    where
      mkConsumer = KC.newConsumer (settings b) (subscription t)
      clConsumer (Left err) = return (Left err)
      clConsumer (Right kc) = (maybe (Right ()) Left) <$> KC.closeConsumer kc
      runHandler (Left err) = return (Left err)
      runHandler (Right kc) = consume kc t

settings :: T.Text -> KC.ConsumerProperties
settings b = KC.brokersList [KC.BrokerAddress b]
  <> KC.groupId (KC.ConsumerGroupId $ T.pack "random-group")
  <> KC.noAutoCommit
  <> KC.logLevel KC.KafkaLogCrit
  <> KC.extraProp (T.pack "enable.partition.eof") (T.pack "true")

subscription :: T.Text -> KC.Subscription
subscription t = KC.topics [KC.TopicName t]
  <> KC.offsetReset KC.Earliest

consume :: KC.KafkaConsumer -> T.Text -> IO ((Either KC.KafkaError ()))
consume kafka t = do
  meta <- KM.watermarkOffsets kafka (KC.Timeout 500) (KC.TopicName t)
  _    <- consumeToCompletion kafka (offsetsFromWatermarks $ rights meta) 0
  return $ Right ()
  where
    consumeToCompletion :: KC.KafkaConsumer -> PartitionOffsets -> Int -> IO ()
    consumeToCompletion kc partitions completed = do
      (errors, msgs) <- partitionEithers <$> KC.pollMessageBatch kc (KC.Timeout 500) 250
      records        <- return $ toRecord <$> msgs
      putStr $ unlines $ (LC.unpack . encode) <$> records
      unless (Map.size partitions == completed) $ do
        consumeToCompletion kc partitions (countPartitionEnds errors completed)
    countPartitionEnds :: [KC.KafkaError] -> Int -> Int
    countPartitionEnds [] c                                                       = c
    countPartitionEnds (KC.KafkaResponseError KC.RdKafkaRespErrPartitionEof:es) c = countPartitionEnds es (c + 1)
    countPartitionEnds (_:es) c                                                   = countPartitionEnds es c
