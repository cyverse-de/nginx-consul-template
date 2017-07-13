#!/bin/sh

exec consul-template -once -consul $CONSUL_CONNECT -template "$NGINX_META_TEMPLATE:$NGINX_TEMPLATE"
