#!/usr/bin/env python
# coding=utf-8
import logging
import zmq
import time
from multiprocessing import Process

class RxProcess(Process):
    def __init__(self, servers, topic, msg_queue):
        super(RxProcess, self).__init__()
        self.msg_queue = msg_queue
        try:
            self.context = zmq.Context()
            self.socket = self.context.socket(zmq.SUB)
            for server in servers:
                self.socket.connect('tcp:://%s' % server)
            self.socket.setsockopt(zmq.SUBSCRIBE, topic)
        except Exception, e:
            logging.error(e)
            raise ValueError
        
    def run(self):
        while True:
            try:
                string = self.socket.recv()
                topic, message = string.split()  
                self.msg_queue.put(message)
            except Exception, e:
                logging.error(e)
                self.msg_queue.close()
                return
