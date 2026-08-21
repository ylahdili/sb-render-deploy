FROM ghcr.io/silverbulletmd/silverbullet:latest
RUN apk add --no-cache git
COPY start.sh /start.sh
RUN chmod +x /start.sh
ENTRYPOINT ["/start.sh"]
