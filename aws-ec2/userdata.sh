#!/bin/bash

## Upgrade packages and install NGINX
sudo dnf update -y
sudo dnf install git nginx -y

## Install NodeJS LTS Version
export NVM_DIR="/usr/local/nvm"
mkdir -p $NVM_DIR
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source /root/.bashrc
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

nvm install --lts
npm install pm2 -g

mkdir -p /var/www
cd /var/www

## Clone from main (simple app with nginx for demo purposes)
git clone https://github.com/leonardoandrade1/nodejs-ec2-app.git app
cd app

## Install and build the app
npm install
npm run build --if-present

## Set NGINX permissions
chown -R root:nginx /var/www/app
chmod -R 755 /var/www/app

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

## Configure NGINX
if [ -f "/var/www/app/nginx/nginx.conf" ]; then
    ## Remove the default config to avoid conflicts
    rm -f /etc/nginx/conf.d/*.conf
    # Copy custom NGINX config from the repository
    cp /var/www/app/nginx/nginx.conf /etc/nginx/conf.d/node_app.conf

    touch /var/log/nginx/node_app_error.log
    chown nginx:nginx /var/log/nginx/node_app_error.log
fi

## Restart NGINX to apply changes
systemctl enable nginx
systemctl start nginx

## Sharing NodeJS and PM2 with another shell sessions
NODE_PATH=$(which node)
NPM_PATH=$(which npm)
PM2_PATH=$(which pm2)

## Create symlink to make NodeJS, NPM, and PM2 globally accessible
ln -sf "$NODE_PATH" /usr/bin/node
ln -sf "$NPM_PATH" /usr/bin/npm
ln -sf "$PM2_PATH" /usr/bin/pm2

## Fixed home for pm2
export PM2_HOME=/opt/.pm2
mkdir -p $PM2_HOME

## Make pm2 home accessible
echo "export PM2_HOME=/opt/.pm2" > /etc/profile.d/pm2_env.sh
chmod +x /etc/profile.d/pm2_env.sh
chmod -R 777 /opt/.pm2
# Allow sticky bit
chmod +t /opt/.pm2

## Set read permissions to root and nvm directories
chmod 755 /root
chmod -R 755 /root/.nvm

## Start the NodeJS app with PM2
PM2_HOME=/opt/.pm2 pm2 start /var/www/app/server.mjs --name "nodejs-ec2-app" -i 2

## Configure PM2 to start on boot
PM2_HOME=/opt/.pm2 pm2 startup systemd -u root --hp /opt/.pm2
PM2_HOME=/opt/.pm2 pm2 save