#!/bin/bash

## Upgrade packages and install NGINX
sudo dnf update -y
sudo dnf install git nginx -y

## System user for deployment
useradd -m -s /bin/bash deploy-user

## Install NodeJS LTS Version
export NVM_DIR="/usr/local/nvm"
mkdir -p $NVM_DIR
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source /root/.bashrc
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

nvm install --lts
npm install pm2 -g

## Sharing NodeJS and PM2 with another shell sessions
NODE_PATH=$(which node)
NPM_PATH=$(which npm)
PM2_PATH=$(which pm2)

## Create symlink to make NodeJS, NPM, and PM2 globally accessible
ln -sf "$NODE_PATH" /usr/bin/node
ln -sf "$NPM_PATH" /usr/bin/npm
ln -sf "$PM2_PATH" /usr/bin/pm2

## Fixed and shared HOME for pm2
export PM2_HOME=/opt/.pm2
mkdir -p $PM2_HOME
chown -R deploy-user:deploy-user $PM2_HOME
chmod -R 770 $PM2_HOME  # Permissão para dono e grupo, com sticky bit se desejar
chmod +t $PM2_HOME

## Ensure PM2_HOME is set for all users
echo "export PM2_HOME=/opt/.pm2" > /etc/profile.d/pm2_env.sh
chmod +x /etc/profile.d/pm2_env.sh

## Set read permissions to root and nvm directories
chmod 755 /root
chmod -R 755 /root/.nvm

mkdir -p /var/www
cd /var/www

## Clone from main (simple app with nginx for demo purposes)
git clone https://github.com/leonardoandrade1/nodejs-ec2-app.git app
cd app

## Install and build the app
npm install
npm run build --if-present

## Set NGINX permissions
chown -R deploy-user:nginx /var/www/app
chmod -R 755 /var/www/app

## Start the NodeJS app
sudo -u deploy-user PM2_HOME=/opt/.pm2 pm2 start /var/www/app/server.mjs --name "nodejs-ec2-app" -i 2
sudo -u deploy-user PM2_HOME=/opt/.pm2 pm2 save

## Configure PM2 to start on boot
sudo su -c "PM2_HOME=/opt/.pm2 pm2 startup systemd -u deploy-user --hp /home/deploy-user"

## Remove all default NGINX files
rm -f /etc/nginx/nginx.conf
rm -f /etc/nginx/conf.d/*.conf
rm -f /etc/nginx/default.d/

## Configure a simlink for NGINX conf
ln -sf /var/www/app/nginx/nginx.conf /etc/nginx/nginx.conf

## Set proper permissions for NGINX logs
touch /var/log/nginx/node_app_error.log /var/log/nginx/node_app_access.log
chown nginx:nginx /var/log/nginx/node_app_*.log
chown -R root:nginx /var/www/app
chmod -R 755 /var/www/app
## Allow NGINX make network connections for SELinux
setsebool -P httpd_can_network_connect 1

## Restart NGINX to apply changes
systemctl enable nginx
systemctl start nginx