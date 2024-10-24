#! /bin/bash
# build tiny configuration with Kafka (one broker) for KRaft version
# version 2024.03

# set all parameters as variables
LIBDIR="/srv/lib"
CNAME="kafka"
DNAME="/srv/kafka/data"

# make sure all required software is present
sudo apt-get install -y ntp docker.io >/dev/null 2>/dev/null

# stop and remove the old version of this container as well as unused ones
docker stop "$CNAME" 2>/dev/null
docker rm "$CNAME" 2>/dev/null
docker container prune -f 2>/dev/null

# make sure kafka data directory exists and is empty
sudo rm -r -f  "$DNAME"
sudo mkdir -p "$DNAME"
sudo chmod 777 "$DNAME"

# move to the work directory
cd "$LIBDIR" || exit

# start the container
docker run \
  --hostname "$CNAME" \
  --publish "29092:29092" \
  --publish "9093:9093" \
  --publish "9092:9092" \
  --volume ""$DNAME":/var/lib/kafka/data" \
  --name "$CNAME" \
  --env  CLUSTER_ID="PBS-PID-kafka-lab-0001" \
  --env  KAFKA_NODE_ID=1 \
  --env  KAFKA_PROCESS_ROLES="broker,controller" \
  --env  KAFKA_LISTENERS="INNER://kafka:9092,OUTER://kafka:29092,CONTROLLER://kafka:9093" \
  --env  KAFKA_LISTENER_SECURITY_PROTOCOL_MAP="INNER:PLAINTEXT,OUTER:PLAINTEXT,CONTROLLER:PLAINTEXT" \
  --env  KAFKA_CONTROLLER_QUORUM_VOTERS="1@kafka:9093" \
  --env  KAFKA_CONTROLLER_LISTENER_NAMES="CONTROLLER" \
  --env  KAFKA_ADVERTISED_LISTENERS="INNER://kafka:9092,OUTER://localhost:29092" \
  --env  KAFKA_INTER_BROKER_LISTENER_NAME="INNER" \
  --env  KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=1 \
  --env  KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS=0 \
  --env  KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR=1 \
  --env  KAFKA_TRANSACTION_STATE_LOG_MIN_ISR=1 \
  --detach \
  confluentinc/cp-kafka:7.4.0













