#!/bin/sh
#
# log.sh

DATE=$(date +"%m-%d-%y")
HOUR=$(date +"%r")

echo $DATE $HOUR '\n' >> /var/log/update_script.log
sudo apt-get update -y >> /var/log/update_script.log
sudo apt-get upgrade -y >> /var/log/update_script.log
echo '\n' >> /var/log/update_script.log
