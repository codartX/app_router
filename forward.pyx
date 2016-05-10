#!/usr/bin/env python
# coding=utf-8
import logging
import psycopg2
import os, sys
import json
import time
import socket
import requests
from multiprocessing import Process, Queue
import Queue
from database import RouteProfileModel, NodeModel

MSG_RETRANSMIT_COUNT    = 3
MSG_RETRANSMIT_INTERVAL = 3

class ForwardProcess(Process):
    def __init__(self, db_host, db_port, db_name, db_user, db_pwd, msg_queue):
        super(ForwardProcess, self).__init__()
        self.queue = msg_queue
        try:
            self.conn = psycopg2.connect(database=db_name, user=db_user, password=db_pwd, host=db_host, port=db_port)   
            self.db = self.conn.cursor(cursor_factory = psycopg2.extras.RealDictCursor)
            self.route_profile_model = RouteProfileModel(self.db) 
            self.node_model = NodeModel(self.db) 
        except Exception, e:
            print str(e)
            raise ValueError

    def run(self):
        while True:
            try:
                msg = self.queue.get(False)
                print 'get queue msg:', msg
                try:
                    msg_json = json.loads(msg)
                    dev_addr = str(msg_json['rxpk']['dev_addr'])
                    fport = int(msg_json['rxpk']['fport'])
                except Exception, e:
                    print 'Invalid format msg:', str(e)
                    continue

                try:
                    destinations = []
                    node = self.node_model.get_node(dev_addr)
                    if node:
                        route_policy = self.route_profile_model.get_route_policy(node['route_profile_name'], fport)
                        if route_policy:
                            route_destinations = self.route_profile_model.get_route_destinations(route_policy['id'])
                            if route_destinations:
                                if route_policy['strategy'] == 'broadcast':
                                    destinations.extend(route_destinations)                    
                                elif route_policy['strategy'] == 'unicast':
                                    destinations.append(route_destinations[0])
                            else:
                                print 'Route destinations not found'
                                continue
                        else:
                            print 'Route policy not found'
                            continue
                    else:
                        print 'Node not found'
                        continue
                except Exception, e:
                    print 'Find route profile fail:', str(e)
                    continue

                for dest in route_destinations:
                    count = 1
                    while count <= MSG_RETRANSMIT_COUNT:
                        try:
                            print 'Try send msg %d time' % count
                            if dest['proto_type'] == 'http':
                                r = requests.post('http://' + dest['host'] + ':' + str(dest['port']) + str(dest['path']), 
                                                  data = msg,
                                                  headers = {'Content-type': 'application/json', 'Accept': '*/*'},
                                                  timeout = 1.0)
                                if r.status_code == 200 and r.reason == 'OK':
                                    break
                                else:
                                    print 'Send msg error %d time, code:%d, reason:%s, data:%s' % (count, 
                                                  r.status_code, r.reason, msg_json)
                            elif dest['proto_type'] == 'https':
                                r = requests.post('https://' + dest['host'] + ':' + str(dest['port']) + str(dest['path']), 
                                                  data = msg,
                                                  headers = {'Content-type': 'application/json', 'Accept': '*/*'},
                                                  timeout = 1.0, verify = False)
                                if r.status_code == 200 and r.reason == 'OK':
                                    break
                                else:
                                    print 'Send msg error %d time, code:%d, reason:%s, data:%s' % (count, 
                                                  r.status_code, r.reason, msg_json)
                            else:
                                print 'Send msg error, unsupport protocol type, data:%s' % msg_json
     
                        except Exception as e:
                            print 'Send msg error:%s' % str(e)
                            pass

                        time.sleep(MSG_RETRANSMIT_INTERVAL)
                        count = count + 1
            except Queue.Empty:
                pass
            except:
                print 'process exit'
                return

