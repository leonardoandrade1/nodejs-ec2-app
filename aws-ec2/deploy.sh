#!/bin/bash

cd /var/www/app

git pull origin main

npm install --production

sudo su -c "PM2_HOME=/opt/.pm2 pm2 reload nodejs-ec2-app"

systemctl restart nginx

echo "Deploy success with PM2! Date: $(date)"

## to check logs:
## cat /var/log/deploy.log

## To check nginx error after deploy, use:
## journalctl -u nginx -n 50

## To monitor PM2, use:
## sudo su
## pm2 monit
## pm2 list to see status in real time