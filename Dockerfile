FROM nginx:alpine
MAINTAINER Ian McEwen <mian@cyverse.org>

ENV CONSUL_TEMPLATE_VERSION=0.16.0
ENV CONSUL_TEMPLATE_SHA256SUM=064b0b492bb7ca3663811d297436a4bbf3226de706d2b76adade7021cd22e156
ENV CONSUL_CONNECT=localhost:8500
ENV NGINX_TEMPLATE=/templates/nginx.conf.tmpl
ENV NGINX_CONF=/etc/nginx/nginx.conf
ENV ENTRYKIT_SHA256SUM=252120ea91a160fe03e3c8d67472147a13f8b3440b318d7e34f3a34d5bd8f80b
ENV ENTRYKIT_VERSION=0.4.0

ADD https://releases.hashicorp.com/consul-template/${CONSUL_TEMPLATE_VERSION}/consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip /
ADD https://github.com/progrium/entrykit/releases/download/v${ENTRYKIT_VERSION}/entrykit_${ENTRYKIT_VERSION}_Linux_x86_64.tgz /

RUN echo "${CONSUL_TEMPLATE_SHA256SUM}  consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip" | sha256sum -c - \
    && unzip consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip \
    && mkdir -p /usr/local/bin \
    && mv consul-template /usr/local/bin/consul-template

RUN echo "${ENTRYKIT_SHA256SUM}  entrykit_${ENTRYKIT_VERSION}_Linux_x86_64.tgz" | sha256sum -c - \
    && tar -xzvf entrykit_${ENTRYKIT_VERSION}_Linux_x86_64.tgz \
    && mkdir -p /usr/local/bin \
    && mv entrykit /usr/local/bin/entrykit \
    && entrykit --symlink

COPY run-consul-template.sh /usr/local/bin/run-consul-template.sh
COPY run-nginx.sh /usr/local/bin/run-nginx.sh
COPY nginx.conf.tmpl /templates/nginx.conf.tmpl
COPY nginx.conf.dummy /etc/nginx/nginx.conf

ENTRYPOINT ["prehook", "/usr/local/bin/run-consul-template.sh -once", "--", "codep", "/usr/local/bin/run-consul-template.sh", "/usr/local/bin/run-nginx.sh"]

ARG git_commit=unknown
ARG descriptive_version=unknown

LABEL org.cyverse.git-ref="$git_commit"
LABEL org.cyverse.descriptive-version="$descriptive_version"
LABEL org.label-schema.vcs-ref="$git_commit"
LABEL org.label-schema.vcs-url="https://github.com/cyverse-de/nginx-consul-template"
LABEL org.label-schema.version="$descriptive_version"
