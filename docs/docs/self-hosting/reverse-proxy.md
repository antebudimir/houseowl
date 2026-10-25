# Reverse proxy configurations

These are community provided and might need to be adapted to your specific setup.

### HAProxy

Assumes HAProxy is part of your HouseOwl docker compose stack, and you use the multiservice setup method.

```
global
  log stdout local0

defaults
  mode http
  log global
  option httplog
  option forwardfor if-none
  retries                 3
  timeout http-request    10s
  timeout queue           1m
  timeout connect         10s
  timeout client          1m
  timeout server          1m
  timeout http-keep-alive 10s
  timeout check           10s
  default-server init-addr last,libc,none

resolvers docker
  parse-resolv-conf

#-----------------------#
#  http
#-----------------------#
frontend efeu-http
  bind :::80 v4v6
  bind :::443 v4v6 ssl crt /etc/letsencrypt/live/domain/domain.pem

  redirect scheme https if !{ ssl_fc }

  # hsts max-age is mandatory
  # 16000000 seconds is a bit more than 6 months
  http-response set-header Strict-Transport-Security "max-age=16000000; includeSubDomains; preload;"

  default_backend houseowl

backend houseowl
  server houseowl front:80 resolvers docker

```

### Traefik v2

This example configuration assumes that you are:

- Running Traefik on the `web` docker network
- Use the entrypoint `websecure` for HTTPS and have configured it for a wildcard SSL certificate
- Have a security@docker middleware (see below)

```yml
version: "3"

services:
  houseowl:
    image: ghcr.io/antebudimir/houseowl:latest
    networks:
      - default
      - web
    restart: unless-stopped
    environment:
      - FRONT_URL=https://your.domain.here
      - JWT_SECRET_KEY=PLEASE_CHANGE_ME
    volumes:
      - houseowl_data:/data
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=web"
      - "traefik.http.routers.houseowl.rule=Host(`your.domain.here`)"
      - "traefik.http.routers.houseowl.entrypoints=websecure"
      - "traefik.http.routers.houseowl.middlewares=security@docker" # Use to apply security middlewares

networks:
  web:
    external: true

volumes:
  houseowl_data:
```

Traefik can add extra security headers to add a level of protection to your HouseOwl instance. You can specify a middleware in your Traefik docker-compose.yml using labels.

```yml
labels:
  - "traefik.http.middlewares.security.headers.addvaryheader=true"
  - "traefik.http.middlewares.security.headers.sslredirect=true"
  - "traefik.http.middlewares.security.headers.browserxssfilter=true"
  - "traefik.http.middlewares.security.headers.contenttypenosniff=true"
  - "traefik.http.middlewares.security.headers.forcestsheader=true"
  - "traefik.http.middlewares.security.headers.stsincludesubdomains=true"
  - "traefik.http.middlewares.security.headers.stspreload=true"
  - "traefik.http.middlewares.security.headers.stsseconds=63072000"
  - "traefik.http.middlewares.security.headers.customframeoptionsvalue=SAMEORIGIN"
  - "traefik.http.middlewares.security.headers.referrerpolicy=same-origin"
```

### Traefik ingress

This example configuration assumes that you are:

- running HouseOwl in a kubernetes environment where traefik is your ingress controller
- you have set up traefik CRDs according to [https://doc.traefik.io/traefik/reference/install-configuration/providers/kubernetes/kubernetes-crd/](https://doc.traefik.io/traefik/reference/install-configuration/providers/kubernetes/kubernetes-crd/) (in particular you intend to use the `IngressRoute` resource instead of the kubernetes-native `Ingress`.)
- HouseOwl is deployed using a service named `houseowl-web` in the `default` namespace.

```yml
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: houseowl-ingressroute

spec:
  entryPoints:
    - websecure
  routes:
  - match: Host(`<your.domain.here>`)
    middlewares:
      - name: houseowl
    kind: Rule
    services:
    - name: houseowl-web
      port: 8080

  tls:
    certResolver: default-tls
---
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: houseowl
spec:
  headers:
    customRequestHeaders:
      X-Forwarded-Proto: "https"
      # enable websockets
      Upgrade: "websocket"
```

In this setup a new middleware is added to enable websocket support on this ingress since it is not enabled by default by the ingress controller.

### Apache

The following assumptions are made by this config:

- You have a (sub)domain for your HouseOwl instance. eg: houseowl.example.org
- You are running the docker images from the given docker-compose.yml with the "ports" changed from "80:80" to "8080:80"
- You have certbot (or some other letsencrypt client) installed and running on your host system
- You have apache running on your host with the default ports for http/https (80/443)

```
<VirtualHost *:80>
        ServerName houseowl.example.org
        ServerAdmin webmaster@example.org

        ErrorLog ${APACHE_LOG_DIR}/houseowl_error.log
        CustomLog ${APACHE_LOG_DIR}/houseowl_access.log combined

        Redirect permanent / https://houseowl.example.org
</VirtualHost>

<VirtualHost *:443>
        ServerName houseowl.example.org
        ServerAdmin webmaster@example.org

        <IfModule mod_headers.c>
                Header always set Strict-Transport-Security "max-age=15552000; includeSubDomains; preload"
        </IfModule>


        ErrorLog ${APACHE_LOG_DIR}/houseowl_error.log
        CustomLog ${APACHE_LOG_DIR}/houseowl_access.log combined

        ProxyPass / http://localhost:8080/
        ProxyPassReverse / http://localhost:8080/

SSLCertificateFile /etc/letsencrypt/live/houseowl.example.org/fullchain.pem
SSLCertificateKeyFile /etc/letsencrypt/live/houseowl.example.org/privkey.pem
Include /etc/letsencrypt/options-ssl-apache.conf
</VirtualHost>
```

### Nginx

The following assumptions are made by this config:

- You have a (sub)domain for your HouseOwl instance. eg: houseowl.example.org
- You are running the docker images from the given docker-compose.yml with the "ports" changed from "80:80" to "8080:80"
- You have certbot (or some other letsencrypt client) installed and running on your host system
- You have nginx running on your host with the default ports for http/https (80/443)

```
server {
    server_name houseowl.example.org;
    listen [::]:443 ssl ipv6only=on; # managed by Certbot
    listen 443 ssl; # managed by Certbot

    # https://www.nginx.com/blog/http-strict-transport-security-hsts-and-nginx/
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    location / {
        proxy_pass http://localhost:8080;
    }

    ssl_certificate /etc/letsencrypt/live/houseowl.example.org/fullchain.pem; # managed by
 Certbot
    ssl_certificate_key /etc/letsencrypt/live/houseowl.example.org/privkey.pem; # managed
by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot
}
server {
    if ($host = houseowl.example.org) {
        return 301 https://$host$request_uri;
    } # managed by Certbot

    server_name houseowl.example.org;
    listen 80;
    listen [::]:80;
    return 404; # managed by Certbot
}
```

### Caddy

Caddy will automatically set up an SSL certificate for the specified hostname.

```caddyfile
houseowl.example.org {
        reverse_proxy localhost:8080 # Set the address of your HouseOwl frontend here
        encode gzip
        header {
                X-Frame-Options "SAMEORIGIN"
                X-XSS-Protection "1; mode=block"
                X-Content-Type-Options "nosniff"
                Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
                Referrer-Policy "strict-origin-when-cross-origin"
        }
}
```
