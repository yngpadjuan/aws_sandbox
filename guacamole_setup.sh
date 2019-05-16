#!/bin/bash

#Ubuntu 18 Apache Guacamole 1.0.0
#Docker Guac server Ubuntu 18

#install docker
sudo apt install docker.io

#start/enable docker/mysql daemon
sudo systemctl start docker
^start^enable

#guacd container
sudo docker run --name some-guacd -d guacamole/guacd

#guacamole container and create customer guacamole_db script
sudo docker run --rm guacamole/guacamole /opt/guacamole/bin/initdb.sh --mysql > initdb.sql

#get mysql container
sudo docker pull mysql:8

#start mysql container
sudo docker run --name mysql -e MYSQL_DATABASE=guacamole -e MYSQL_USER=guacamole -e MYSQL_PASSWORD=guacamole -e MYSQL_ROOT_PASSWORD=guacamole -d -p 3306:3306 mysql

#copy db .sql script to container
sudo docker cp initdb.sql mysql:/

#build guacamole db
sudo docker exec mysql /bin/sh -c 'mysql -u guacamole -pguacamole < /initdb.sql'

#start guacamole containter
sudo docker run --name guacamole --link some-guacd:guacd --link mysql:mysql -e MYSQL_DATABASE=guacamole -e MYSQL_USER=guacamole -e MYSQL_PASSWORD=guacamole -e MYSQL_ROOT_PASSWORD=guacamole -d -p 8080:8080 guacamole/guacamole 

#start containters on system boot
sudo docker update --restart=always $(docker ps -aq)
