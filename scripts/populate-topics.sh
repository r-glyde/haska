#!/usr/bin/env bash
kafka-topics.sh --zookeeper localhost:2181 --create --topic topic-1 --partitions 5 --replication-factor 1
kafka-topics.sh --zookeeper localhost:2181 --create --topic topic-2 --partitions 5 --replication-factor 1
kafka-topics.sh --zookeeper localhost:2181 --create --topic topic-3 --partitions 5 --replication-factor 1

for i in {1..100}; do
    echo "$i:{\"message\":\"$i\"}" | kafkacat -P -b localhost:9092 -t topic-1 -K:
done