FROM ghcr.io/silverbulletmd/silverbullet:latest

# Switch to root to install git and drop the boot script in
USER root
RUN apk add --no-cache git

COPY boot.sh /boot.sh
RUN chmod +x /boot.sh

# Override SilverBullet's entrypoint with our boot wrapper.
# tini stays as PID 1; boot.sh clones /space then execs the original entrypoint.
ENTRYPOINT ["/sbin/tini", "--", "/boot.sh"]
