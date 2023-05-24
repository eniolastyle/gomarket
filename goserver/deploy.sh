#!/bin/bash

REPO_DIR="/home/ubuntu/gomarket"

# Check if the repository directory exists
if [ -d "$REPO_DIR" ]; then
  echo "Repository already exists. Performing git pull..."
  cd $REPO_DIR
  git pull 
else
  echo "Repository not found. Cloning the repository..."
  git clone https://github.com/eniolastyle/gomarket.git $REPO_DIR
  cd $REPO_DIR
fi

# Deployment script
cd goserver
touch .env
echo "${env.SERVER_ENV}" > .env
npm install
sudo pm2 delete goserver || true
pm2 start app.js --name goserver
sudo rm -rf /etc/nginx/sites-available/default
sudo cp default /etc/nginx/sites-available/ -r
sudo systemctl restart nginx

