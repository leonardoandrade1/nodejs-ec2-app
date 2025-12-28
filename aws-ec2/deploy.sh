#!/bin/bash

# cd /var/www/app

git pull origin main

npm install --production

# restart systemd service for NodeJS application
systemctl restart node-app

systemctl restart nginx

echo "Deploy success! Date: $(date)"

## to check logs:
## cat /var/log/deploy.log

## To check nginx or node-app error after deploy, use:
## journalctl -u node-app -n 50
## journalctl -u nginx -n 50