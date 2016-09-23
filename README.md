nginx-consul-template
=====================

This repository contains a Dockerfile and associated support files for an image ordinarily published as discoenv/nginx-consul-template. This is an nginx-based image which includes consul-template and some simple template files, which accepts environment variables to control its behavior. As an example, in docker-compose syntax:

```yaml
anon_files_nginx:
  image: discoenv/nginx-consul-template:${DE_TAG}
  restart: unless-stopped
  ports:
    - "30000:30000"
  environment:
    - CONSUL_CONNECT=${HOSTNAME}:8500
    - NGINX_PROXY_SERVICE_NAME=anon-files
    - NGINX_PROXY_PORT=30000
    - DE_ENV=${DE_ENV}
    - SERVICE_80_IGNORE=true
    - SERVICE_443_IGNORE=true
    - SERVICE_30000_NAME=anon-files-nginx
    - SERVICE_30000_CHECK_HTTP=/?expecting=anon-files
    - SERVICE_30000_CHECK_INTERVAL=10s
    - SERVICE_30000_TAGS=${DE_ENV}
  log_driver: "syslog"
  log_opt:
    tag: "{{.ImageName}}/{{.Name}}"
  volumes:
    - /etc/localtime:/etc/localtime
    - /etc/timezone:/etc/timezone
```

For further details, reading the nginx.conf.tmpl file is recommended.
