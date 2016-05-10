FROM ubuntu:14.04

# make sure the package repository is up to date
RUN apt-get update

# install python and pip for python
RUN apt-get install -y python-pip  

RUN pip install pyzmq-static

RUN apt-get install -y python-psycopg2

RUN mkdir -p /opt/app_router

ADD *.so app_router /opt/app_router
WORKDIR /opt/app_router

