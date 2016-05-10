#!/usr/bin/env python
# coding=utf-8
import psycopg2.extras
import json

class RouteProfileModel():
    def __init__(self, db):
        self.db = db

    def get_route_policy(self, profile_name, fport):
        sql = """SELECT * FROM "route_policies" WHERE route_profile_name = '{0}' and fport = {1};""".format(profile_name, fport) 
        self.db.execute(sql)
        route_policy = self.db.fetchone()
        return route_policy

    def get_route_destinations(self, route_policy_id):
        sql = """SELECT * FROM "route_destinations" WHERE route_policy_id = {0} ORDER BY priority DESC;""".format(route_policy_id) 
        self.db.execute(sql)
        route_destinations = self.db.fetchall()
        return route_destinations

class NodeModel():
    def __init__(self, db):
        self.db = db 
    
    def get_node(self, dev_addr):
        sql = """SELECT * FROM "nodes" WHERE dev_addr = '{0}';""".format(dev_addr) 
        self.db.execute(sql)
        node = self.db.fetchone()
        return node
