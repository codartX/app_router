#!/usr/bin/env python
import threading, logging, time

from kafka import KafkaConsumer, KafkaProducer


class Producer(threading.Thread):
    daemon = True

    def run(self):
        producer = KafkaProducer(bootstrap_servers='10.75.163.104:31000')

        while True:
            producer.send('cisco', b"test")
            producer.send('cisco', b"\xc2Hola, mundo!")
            time.sleep(1)


class Consumer(threading.Thread):
    daemon = True

    def run(self):
        consumer = KafkaConsumer(bootstrap_servers='10.75.163.104:31000',
                                 auto_offset_reset='earliest')
        consumer.subscribe(['cisco'])

        for message in consumer:
            print (message)


def main():
    threads = [
        Producer(),
        Consumer()
    ]

    for t in threads:
        t.start()

    time.sleep(10)

if __name__ == "__main__":
    logging.basicConfig(
        format='%(asctime)s.%(msecs)s:%(name)s:%(thread)d:%(levelname)s:%(process)d:%(message)s',
        level=logging.INFO
        )
    main()
