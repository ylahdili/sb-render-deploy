#!/bin/sh
# Exit immediately if any command fails (returns a non-zero status)
set -e

# ==========================================
# 1. GUARANTEE TARGET DIRECTORY
# ==========================================
# We must ensure the target directory exists before doing anything. 
# Even though Render provisions ephemeral storage, explicitly creating 
# the folder prevents 'No such file or directory' errors when moving files.
mkdir -p /space


# ==========================================
# 2. RESTORE FROM GITHUB ON COLD START
# ==========================================
# /space is completely ephemeral on Render Free. 
# Every time the app sleeps (after 15 mins of inactivity) and wakes back up, 
# the local disk is wiped clean. We use GitHub as our permanent hard drive.

if [ ! -d /space/.git ]; then
  echo "[boot] Empty /space detected — cloning full history from GitHub..."
  
  # Clean out any leftover junk or hidden files Render might have left 
  # in the ephemeral volume during initialization.
  rm -rf /space/* /space/.[!.]* 2>/dev/null || true
  
  # Perform a FULL clone into a temporary directory. 
  # We purposely do not use '--depth 1'. While '--depth 1' makes cold starts 
  # slightly faster, it destroys the git log. The SilverBullet History plugin 
  # REQUIRES the full git history to let you revert past mistakes.
  git clone "https://${SB_GIT_TOKEN}@github.com/${SB_GIT_REPO}.git" /space-tmp
  
  # Safely move the repository into the official /space mount point.
  # We use a temp directory because Git will refuse to clone directly 
  # into /space since our 'mkdir' command made it a non-empty directory.
  mv /space-tmp/.git /space/.git
  cp -a /space-tmp/. /space/
  rm -rf /space-tmp
  
  # Configure Git identity for the automated sync plugin.
  # When you or your visitors edit pages, the background auto-sync 
  # will use these credentials to push the commits to GitHub.
  cd /space
  git config user.name "SilverBullet on Render"
  git config user.email "render@silverbullet.local"
  git config pull.rebase false
  
  # Link the local main branch to the remote origin to prevent push/pull conflicts
  git branch --set-upstream-to=origin/"$(git rev-parse --abbrev-ref HEAD)" 2>/dev/null || true

else
  # If /space/.git already exists, it means the container hasn't slept yet, 
  # or you transitioned to a paid Render tier with a persistent disk.
  echo "[boot] /space already has .git — pulling latest changes..."
  cd /space && git pull --ff-only || true
fi


# ==========================================
# 3. LAUNCH SILVERBULLET
# ==========================================
# Hand off execution to SilverBullet's compiled binary.
# 
# WARNING: Do not use '/docker-entrypoint.sh "$@"'. The official SilverBullet 
# image does not use a wrapper script; the executable is located directly at 
# the root as '/silverbullet'.
# 
# We use 'exec' so that SilverBullet replaces this bash script as Process ID 1. 
# This ensures the server cleanly receives shutdown signals from Render.
exec /silverbullet /space
