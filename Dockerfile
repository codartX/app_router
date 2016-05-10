FROM ubuntu:14.04

# make sure the package repository is up to date
RUN apt-get update

# install python and pip for python
RUN apt-get install -y python-pip  

RUN pip install kafka-python==1.0.2

RUN apt-get install -y python-psycopg2

RUN mkdir -p /opt/app_route

ADD . /opt/app_route
WORKDIR /opt/app_route

