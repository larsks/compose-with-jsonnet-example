FROM docker.io/alpine:latest

RUN apk add \
  keepalived \
  curl

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["sh", "/entrypoint.sh"]
CMD ["keepalived", "-nl", "-f", "/etc/keepalived/keepalived.conf"]
