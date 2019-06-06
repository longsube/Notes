#!/bin/bash -ex
#
source config.cfg
source functions.sh

echocolor "Backup Keystone config"
cp -rp /etc/keystone /root/backup_mitaka/
cp /etc/apache2/sites-available/wsgi-keystone.conf /root/backup_mitaka
cp /etc/apache2/sites-enabled/wsgi-keystone.conf /root/backup_mitaka