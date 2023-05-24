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
cd goclient
touch .env
echo REACT_APP_API_URL=http://"${{ needs.goinfra_launch.outputs.SERVER_PUBLIC_IP }}" > .env
npm install
rm -rf build || true
npm run build
sudo pm2 delete goclient || true
pm2 serve build/ 3000 -f --name "goclient" --spa
sudo rm -rf /etc/nginx/sites-available/default
sudo cp default /etc/nginx/sites-available/ -r
sudo systemctl restart nginx
