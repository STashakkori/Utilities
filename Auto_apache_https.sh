#!/bin/bash
# $t@$h

DOMAIN="put_the_domain_name_here"
CERT_DIR="/etc/pki/tls"
SSL_CONF="/etc/httpd/conf.d/zzz-ssl-${DOMAIN}.conf"
REDIRECT_CONF="/etc/httpd/conf.d/zzz-redirect-${DOMAIN}.conf"
APACHE_SSL_PORT=443

mkdir -p "$CERT_DIR/certs" "$CERT_DIR/private" "$CERT_DIR/csr" # Ensure Directories Exist

echo "Installing mod_ssl and httpd-tools"
dnf install -y mod_ssl httpd-tools # Change this for distro

echo "Generating private key and self-signed cert"
openssl req -newkey rsa:2048 -nodes -keyout "$CERT_DIR/private/${DOMAIN}.key" \
    -x509 -days 365 -out "$CERT_DIR/certs/${DOMAIN}.crt" \
    -subj "/C=US/ST=State/L=City/O=Org/OU=IT/CN=$DOMAIN"

echo "Creating a CSR"
openssl req -new -key "$CERT_DIR/private/${DOMAIN}.key" \
    -out "$CERT_DIR/csr/${DOMAIN}.csr" \
    -subj "/C=US/ST=State/L=City/O=Org/OU=IT/CN=$DOMAIN"

echo "Writing SSL config to: $SSL_CONF"
cat > "$SSL_CONF" <<EOF
<VirtualHost *:${APACHE_SSL_PORT}>
    ServerName ${DOMAIN}
    DocumentRoot /var/www/html

    SSLEngine on
    SSLCertificateFile ${CERT_DIR}/certs/${DOMAIN}.crt
    SSLCertificateKeyFile ${CERT_DIR}/private/${DOMAIN}.key

    <Directory /var/www/html>
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog logs/ssl-${DOMAIN}-error.log
    CustomLog logs/ssl-${DOMAIN}-access.log combined
</VirtualHost>
EOF

echo "Writing redirect config to: $REDIRECT_CONF"
cat > "$REDIRECT_CONF" <<EOF
<VirtualHost *:80>
    ServerName ${DOMAIN}
    Redirect permanent / https://${DOMAIN}/
</VirtualHost>
EOF

apachectl configtest || { echo "Error: Apache config test failed."; exit 1; } # Test the config

systemctl enable --now httpd

echo "HTTPS configured for $DOMAIN with HTTP redirect. Check https://${DOMAIN}/"
echo "Can also check http://${DOMAIN}/ for redirection"
