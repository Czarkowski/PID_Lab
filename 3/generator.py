from time import sleep
from json import dumps
from kafka import KafkaProducer
from kafka.errors import NoBrokersAvailable
from kafka.errors import KafkaTimeoutError
import os
import random
import time

while True:
    try:
        producer = KafkaProducer(
            bootstrap_servers=[os.environ.get("BROKER_BOOTSTRAP","127.0.0.1")],
            value_serializer=lambda x:
               dumps(x).encode('utf-8'))

        while True:
            moment=int(round(time.time()*1000))
            voltage=random.uniform(228,232)
            frequency=50.2-(voltage-228)/10
            meter=os.environ.get("METER_ID","METER")
            data = {'time' : moment,'V1':voltage,'F':frequency,'meter':meter}
            producer.send(os.environ.get("BROKER_TOPIC","topic"), value=data)
            sleep(int(os.environ.get("SLEEP_MS",1000))/1000)

    except NoBrokersAvailable:
        sleep(5)

    except KafkaTimeoutError:
        sleep(5)









