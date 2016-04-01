#!/bin/bash
sudo yum install -y git python-devel gcc
git clone https://github.com/a-h/service-example
cd service-example/python/establishment_service
sudo yum install -y python34-virtualenv
sudo alternatives --set python /usr/bin/python3.4
virtualenv-3.4 .
sudo pip install pymongo flask psutil jsonpickle pytest coverage tornado motor pytest-cov
sudo pip install pymongo==2.8
#TODO: Get the username setup properly, so we don't use the root mongodb user.
nohup python3 app.py mongodb://admin:123456@10.0.1.250:27017 &
