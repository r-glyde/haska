module Parser where

import Config
import Options.Applicative

supportedTypeReader :: ReadM SupportedType
supportedTypeReader = str >>= \s -> case s of
  "string" -> return STRING
  "long"   -> return LONG
  "avro"   -> return AVRO
  _ -> readerError "Must be one of: string|long|avro"

registryUrlNeeded :: String
registryUrlNeeded = "--registry-url (-r) must be supplied to use avro deserializers"

consumer :: Parser ConsumerConfig
consumer = ConsumerConfig
      <$> strOption
          ( long "brokers"
         <> short 'b'
         <> help "Kafka bootstrap servers"
         <> metavar "HOST:PORT" )
      <*> strOption
          ( long "topic"
         <> short 't'
         <> help "Topic to conumer from" 
         <> metavar "STRING")
      <*> option supportedTypeReader
          ( long "key-deserializer"
         <> short 'k'
         <> help "Deserializer for message keys"
         <> showDefault
         <> value STRING
         <> metavar "" )
      <*> option supportedTypeReader
          ( long "value-deserializer"
         <> short 'v'
         <> help "Deserializer for message values"
         <> showDefault
         <> value STRING
         <> metavar "" )
      <*> (optional $ strOption
          ( long "registry-url"
         <> short 'r'
         <> help "URL for schema-registry"
         <> metavar "" ))
