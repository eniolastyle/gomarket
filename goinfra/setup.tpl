#!/bin/bash

echo "---Update and Git---"
sudo apt-get update
sudo apt-get install git -y
# Set rebase to be true globally 
git config --global pull.rebase true

echo "---NVM (Node Version Manager) - NODE & NPM---"
# Install NVM (Node Version Manager)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
# Load NVM into the shell
source ~/.bashrc
# Install Node.js 16
nvm install 16
# Set Node.js 16 as the default version
nvm alias default 16
# Display the installed Node.js version
node --version
npm --version


echo "-----PM2------"
sudo npm install -g pm2
sudo pm2 startup systemd

echo "-----NGINX------"
sudo apt-get install -y nginx

echo "---FIREWALL---"
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw --force enable 
