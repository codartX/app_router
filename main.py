#!/usr/bin/env python
# coding=utf-8

import logging
import getopt, sys
import Queue
import time
import requests
import socket
import json
from kafka import KafkaConsumer
import multiprocessing 
from forward import ForwardProcess

def main():
    #logging.basicConfig(
    #    format='%(asctime)s.%(msecs)s:%(name)s:%(thread)d:%(levelname)s:%(process)d:%(message)s',
    #    level=logging.DEBUG
    #    )

    try:
        opts, args = getopt.getopt(sys.argv[1:],'ht:',['topics='])
    except getopt.GetoptError:
        print 'main.py -t <topics>'

    for opt, arg in opts:
        if opt == '-h':
            print 'main.py -t <topics>'
            sys.exit()
        elif opt in ('-t', '--topics'):
            topics = arg

    try:
        f = open('config.json', 'r')
        raw_data = f.read()
        config_json = json.loads(raw_data)
        kfk_addrs = config_json['kafka_cfg']['hosts']
        db_addr = config_json['database_cfg']['host']
        db_port = config_json['database_cfg']['port']
        db_name = config_json['database_cfg']['db_name']
        db_username = config_json['database_cfg']['username']
        db_pwd = config_json['database_cfg']['password']
        process_num = config_json['process_num']
    except Exception, e:
        print 'Wrong format config file:', str(e) 
        sys.exit()

    try:
        consumer = KafkaConsumer(topics, 
                                 bootstrap_servers = kfk_addrs,
                                 auto_offset_reset = 'earliest',
                                 enable_auto_commit = False)
    except Exception as e:
        print 'Consumer create fail:', str(e) 
        sys.exit()

    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server_socket.setblocking(0)
    server_socket.bind(('', 5000))
    server_socket.listen(5)

    msg_queue = multiprocessing.Queue()
    worker_pool = []

    try:
        for i in range(int(process_num)):
            p = ForwardProcess(db_addr, db_port, db_name, db_username, db_pwd, msg_queue, server_socket)
            p.daemon = True
            worker_pool.append(p)
            p.start()
    except Exception, e:
        print 'Process create fail:', str(e)
        sys.exit()

    while True:
        try:
            for message in consumer:
                try:
                    print 'consume msg:', message
                    msg_queue.put(message.value)
                    consumer.commit()
                except Exception, e:
                    print 'Enqueue fail,error:', str(e)
                    msg_queue.close()
                    break
        except Exception as e:
            #TODO:check consumer if OK or restart consumer?
            print 'Consume  message error:', str(e)
            break

    for worker in worker_pool:
        worker.join()

if __name__ == "__main__":
    main()

