#!/usr/bin/env python
# coding=utf-8

import logging
import getopt, sys
import Queue
import time
import requests
import socket
import json
import multiprocessing 
from forward import ForwardProcess
from rx import RxProcess

def main():
    #logging.basicConfig(
    #    format='%(asctime)s.%(msecs)s:%(name)s:%(thread)d:%(levelname)s:%(process)d:%(message)s',
    #    level=logging.DEBUG
    #    )

    try:
        opts, args = getopt.getopt(sys.argv[1:],'ht:',['topic='])
    except getopt.GetoptError:
        print 'main.py -t <topic>'

    for opt, arg in opts:
        if opt == '-h':
            print 'main.py -t <topic>'
            sys.exit()
        elif opt in ('-t', '--topic'):
            topic = arg

    try:
        f = open('config.json', 'r')
        raw_data = f.read()
        config_json = json.loads(raw_data)
        servers = config_json['network_servers']
        db_addr = config_json['database_cfg']['host']
        db_port = config_json['database_cfg']['port']
        db_name = config_json['database_cfg']['db_name']
        db_username = config_json['database_cfg']['username']
        db_pwd = config_json['database_cfg']['password']
        process_num = config_json['process_num']
    except Exception, e:
        print 'Wrong format config file:', str(e) 
        sys.exit()

    health_check_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    health_check_socket.setblocking(0)
    health_check_socket.bind(('', 5000))
    health_check_socket.listen(5)

    msg_queue = multiprocessing.Queue()
    worker_pool = []

    try:
        for i in range(int(process_num)):
            p = ForwardProcess(db_addr, db_port, db_name, db_username, db_pwd, msg_queue)
            p.daemon = True
            worker_pool.append(p)
            p.start()
        p = RxProcess(servers, topic, msg_queue)
        p.daemon = True
        p.start()
    except Exception, e:
        print 'Process create fail:', str(e)
        sys.exit()

    for worker in worker_pool:
        worker.join()

    p.join()
    msg_queue.close()

if __name__ == "__main__":
    main()

