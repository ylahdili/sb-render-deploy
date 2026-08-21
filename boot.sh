#!/bin/sh
set -e

# 1. Guarantee the target directory exists before doing anything
mkdir -p /space

# /space is ephemeral on Render Free.
# 2. Restore from GitHub on every cold start.
if [ ! -d /space/.git ]; then
  echo "[boot] Empty /space — cloning full history from GitHub..."
  
  # Clean out any leftover junk Render might have left in the ephemeral volume
  rm -rf /space/* /space/.[!.]* 2>/dev/null || true
  
  # Full clone (no --depth 1) so the History plugin can read past versions
  git clone "https://${SB_GIT_TOKEN}@github.com/${SB_GIT_REPO}.git" /space-tmp
  
  # Safely move the repo into the official mount point
  mv /space-tmp/.git /space/.git
  cp -a /space-tmp/. /space/
  rm -rf /space-tmp
  
  # Configure Git for the automated backup plugin
  cd /space
  git config user.name "SilverBullet on Render"
  git config user.email "render@silverbullet.local"
  git config pull.rebase false
  git branch --set-upstream-to=origin/"$(git rev-parse --abbrev-ref HEAD)" 2>/dev/null || true
else
  echo "[boot] /space already has .git — pulling latest..."
  cd /space && git pull --ff-only || true
fi

# Hand off to SilverBullet's official entrypoint script
# This automatically handles permissions and launches the actual Rust binary
exec /docker-entrypoint.sh "$@"
