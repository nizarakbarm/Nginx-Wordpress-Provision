#!/bin/bash

#create map for webp
cat <<EOF>/etc/nginx/map_webp.conf
map \$http_accept \$webp_suffix {
    default "";
    "~*webp" ".webp";
}
EOF