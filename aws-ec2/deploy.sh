#!/bin/bash

cd /var/www/app

git pull origin main

npm install --production

pm2 reload node-app

systemctl restart nginx

echo "Deploy success with PM2! Date: $(date)"

## to check logs:
## cat /var/log/deploy.log

## To check nginx error after deploy, use:
## journalctl -u nginx -n 50

## To monitor PM2, use:
## pm2 monit
## pm2 list to see status in real time