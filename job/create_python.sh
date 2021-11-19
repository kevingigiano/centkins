#!/bin/bash
# This is just an test script that I used for figuring out how to build python from source

WORKDIR=$(pwd)
cd /tmp/
wget https://www.python.org/ftp/python/3.8.8/Python-3.8.8.tgz
tar xzf Python-3.8.8.tgz

cd Python-3.8.8
./configure --prefix=/opt/python38
make -j 8
make altinstall

tar cvf python38.tar.gz -C /opt python38
cp python38.tar.gz $WORKDIR
