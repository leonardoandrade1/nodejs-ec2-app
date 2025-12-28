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

## Creating a simple systemd service to run the NodeJS app
NODE_PATH=$(which node)
cat <<EOF > /etc/systemd/system/node-app.service
[Unit]
Description=Simple WebApp Node.js
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/var/www/app
# Set entrypoint
ExecStart=$NODE_PATH server.mjs
Restart=on-failure
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

## Enable nodejs app service
systemctl daemon-reload
systemctl enable node-app
systemctl start node-app