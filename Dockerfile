FROM docker.io/alpine:latest

RUN apk add \
  keepalived \
  curl

CMD ["keepalived", "-nl", "-f", "/etc/keepalived/keepalived.conf"]
