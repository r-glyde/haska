module Main where

import Config
import qualified Consumer as C
import Parser
import Options.Applicative

main :: IO ()
main = run =<< execParser opts
  where
    opts = info (consumer <**> helper)
      ( fullDesc
      <> progDesc "Consume from a kafka topic"
      <> header "haska - kafka-cli written in haskell" )

run :: ConsumerConfig -> IO ()
run (ConsumerConfig _ _ AVRO _ Nothing) = putStrLn registryUrlNeeded
run (ConsumerConfig _ _ _ AVRO Nothing) = putStrLn registryUrlNeeded
run consumerConfig                      = C.run consumerConfig
