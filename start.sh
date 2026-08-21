#!/bin/sh
# Clone your private storage repo on boot using the token
git clone https://${GITHUB_TOKEN}@github.com/${GITHUB_USER}/${GITHUB_REPO}.git /space

# Configure git inside the container for the History plugin
cd /space
git config --global user.email "bot@example.com"
git config --global user.name "SilverBullet Bot"

# Launch SilverBullet
exec silverbullet /space
