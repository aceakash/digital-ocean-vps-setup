FROM golang:1.24-alpine AS build
RUN apk add --no-cache git
RUN go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest
WORKDIR /src
RUN xcaddy build v2.10.0 --with github.com/caddy-dns/digitalocean@latest
FROM caddy:2.10.0
COPY --from=build /src/caddy /usr/bin/caddy
