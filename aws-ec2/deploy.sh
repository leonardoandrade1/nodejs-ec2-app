#!/bin/bash

APP_PATH="/var/www/app"
export PM2_HOME="/opt/.pm2"

echo "Starting deployment as $(whoami)... Date: $(date)" >> /var/log/deploy.log

sudo -u deploy-user git -C $APP_PATH pull origin main

sudo -u deploy-user npm --prefix $APP_PATH install --production

sudo -u deploy-user "PM2_HOME=/opt/.pm2 pm2 reload nodejs-ec2-app"

sudo systemctl restart nginx

echo "Deploy success with PM2! Date: $(date)"

## to check logs:
## cat /var/log/deploy.log

## To check nginx error after deploy, use:
## journalctl -u nginx -n 50

## To monitor PM2, use:
## sudo su
## pm2 monit
## pm2 list to see status in real time