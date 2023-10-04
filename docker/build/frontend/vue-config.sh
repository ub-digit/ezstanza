#/bin/sh
CONFIG=$(envsubst < /root/config.json)
REPLACEMENT="APP_CONFIG = $CONFIG" perl -i -pe 's/APP_CONFIG\s*=\s*[^;]+/$ENV{REPLACEMENT}/' /var/share/nginx/html/index.html
