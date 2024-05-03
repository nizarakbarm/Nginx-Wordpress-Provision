#!/bin/bash

#create ssl secure configuration
cat <<EOF >/etc/nginx/ssl_secure.conf
# CIS Benchmark Nginx: 4.1.6
ssl_dhparam /etc/nginx/ssl/dhparam.pem;

# CIS Benchmark Nginx: 4.1.7
ssl_stapling on;
ssl_stapling_verify on;

# CIS Benchmark Nginx: 4.1.8
add_header Strict-Transport-Security "max-age=15768000;" always;

# CIS Benchmark Nginx: 4.1.12
ssl_session_tickets off;

# CIS Benchmark Nginx: 4.1.4
ssl_protocols TLSv1.2 TLSv1.3;
# CIS Benchmark Nginx: 4.1.5
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
EOF

#create a security header config
cat <<EOF>/etc/nginx/security_header.conf
# CIS Benchmark Nginx: 5.3.1
add_header X-Frame-Options "SAMEORIGIN" always;

# CIS Benchmark Nginx: 5.3.2
add_header X-Content-Type-Options "nosniff" always;

# CIS Benchmark Nginx: 5.3.3
add_header Content-Security-Policy "default-src 'self'" always;
EOF