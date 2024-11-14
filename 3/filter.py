from time import sleep
from json import dumps
from kafka import KafkaConsumer, KafkaProducer
from kafka.errors import NoBrokersAvailable
from kafka.errors import KafkaTimeoutError
from json import loads, dumps
import os

input_topic = os.environ.get("INPUT_TOPIC", "input-topic")
output_topic = os.environ.get("OUTPUT_TOPIC", "output-topic")
broker = os.environ.get("BROKER_BOOTSTRAP", "127.0.0.1:9092")
data_type = os.environ.get("DATA_TYPE", "V1")

while True:
    try:
        consumer = KafkaConsumer(
            input_topic,
            bootstrap_servers=[broker],
            group_id="filter-group",
            value_deserializer=lambda x: loads(x.decode('utf-8'))
        )

        producer = KafkaProducer(
            bootstrap_servers=[broker],
            value_serializer=lambda x: dumps(x).encode('utf-8')
        )

        for message in consumer:
            data = message.value
            
            if data_type in data:
                filtered_data = {data_type: data[data_type]}
                producer.send(output_topic, value=filtered_data)
                print(f"Przesyłanie: {filtered_data}")

    except NoBrokersAvailable:
        sleep(5)

    except KafkaTimeoutError:
        sleep(5)

