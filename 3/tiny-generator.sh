#! /bin/bash
# build tiny configuration with one-nodes Kafka with KRaft, and a generator,
# both at the same network
# version 2024.03

# set all parameters as variables
LIBDIR="/srv/lib"
DNAME="/srv/kafka/data"
NNAME="pid-net"
KNAME="kafka"
GNAME="generator"
GNAME_2="generator_2"
FNAME="filter"

# make sure all required software is present
sudo apt-get install -y ntp docker.io  >/dev/null 2>/dev/null

# stop and remove the old version of both containers
docker stop "$KNAME" 2>/dev/null
docker rm "$KNAME" 2>/dev/null
docker stop "$GNAME" 2>/dev/null
docker rm "$GNAME" 2>/dev/null
docker stop "$GNAME_2" 2>/dev/null
docker rm "$GNAME_2" 2>/dev/null
docker container prune -f 2>/dev/null

# make sure kafka data directory exists and is empty
sudo rm -r -f  "$DNAME"
sudo mkdir -p "$DNAME"
sudo chmod 777 "$DNAME"

# build the network, make sure it is from scratch
docker network rm "$NNAME" 2>/dev/null
docker network prune -f 2>/dev/null
docker network create "$NNAME"

# run the kafka broker
docker run \
  --hostname "$KNAME" \
  --network "$NNAME" \
  --publish "29092:29092" \
  --publish "9093:9093" \
  --publish "9092:9092" \
  --volume "$DNAME:/var/lib/kafka/data" \
  --name "$KNAME" \
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

cd "$LIBDIR" || exit

# build the generator image
cat >Dockerfile <<EOF
FROM python:3.8
COPY generator.py /srv/bin/generator.py
RUN pip install kafka-python==1.4.7 six
ENV PYTHONUNBUFFERED=1
CMD [ "python", "-u", "/srv/bin/generator.py" ]
EOF

# build the image
docker build -t "$GNAME:latest" .

# clean up
rm Dockerfile

# run the generator
docker run \
  --hostname "$GNAME_2" \
  --name "$GNAME_2" \
  --network "$NNAME" \
  --env  BROKER_BOOTSTRAP="$KNAME:9092" \
  --env  BROKER_TOPIC='measurement' \
  --env  SLEEP_MS='2137' \
  --env  METER_ID='TWO' \
  --detach \
  "$GNAME:latest"

docker run \
  --hostname "$GNAME" \
  --name "$GNAME" \
  --network "$NNAME" \
  --env  BROKER_BOOTSTRAP="$KNAME:9092" \
  --env  BROKER_TOPIC='measurement' \
  --env  SLEEP_MS='1000' \
  --env  METER_ID='ONE' \
  --detach \
  "$GNAME:latest"


cat >Dockerfile <<EOF
FROM python:3.8
COPY filter.py /srv/bin/filter.py
RUN pip install kafka-python==1.4.7 six
ENV PYTHONUNBUFFERED=1
CMD [ "python", "-u", "/srv/bin/filter.py" ]
EOF

docker build -t "$FNAME:latest" .

docker run \
  --hostname "$FNAME" \
  --name "$FNAME" \
  --network "$NNAME" \
  --env  BROKER_BOOTSTRAP="$KNAME:9092" \
  --env  INPUT_TOPIC='measurement' \
  --env  OUTPUT_TOPIC='filtered_measurement' \
  --env  DATA_TYPE='V1' \
  --detach \
  "$FNAME:latest"














