#!/bin/bash
# art.schema.tokyo setup — run as root on the ConoHa VPS:
#   curl -fsSL https://raw.githubusercontent.com/84ken/chichibu-art/main/server-setup.sh | bash
set -e
REPO=https://github.com/84ken/chichibu-art.git
ROOT=/var/www/chichibu-art
DOMAIN=art.schema.tokyo
EMAIL=84ken@llschema.com

echo "== 1/5 git =="
if ! command -v git >/dev/null; then
  if command -v apt-get >/dev/null; then apt-get update -qq && apt-get install -y -qq git
  elif command -v dnf >/dev/null; then dnf install -y -q git
  else yum install -y -q git; fi
fi

echo "== 2/5 clone/update site =="
if [ -d "$ROOT/.git" ]; then
  git -C "$ROOT" pull --ff-only
else
  mkdir -p /var/www
  git clone -q "$REPO" "$ROOT"
fi

echo "== 3/5 nginx vhost =="
if [ -d /etc/nginx/sites-available ]; then
  CONF=/etc/nginx/sites-available/$DOMAIN.conf
  ln_target=/etc/nginx/sites-enabled/$DOMAIN.conf
else
  CONF=/etc/nginx/conf.d/$DOMAIN.conf
  ln_target=""
fi
cat > "$CONF" <<NGINXEOF
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN;
    root $ROOT;
    index index.html;
    charset utf-8;
    location / { try_files \$uri \$uri/ =404; }
    location ~ /\.git { deny all; }
}
NGINXEOF
if [ -n "$ln_target" ]; then ln -sf "$CONF" "$ln_target"; fi
nginx -t
systemctl reload nginx 2>/dev/null || service nginx reload

echo "== 4/5 SSL (Let's Encrypt) =="
if ! command -v certbot >/dev/null; then
  if command -v apt-get >/dev/null; then apt-get install -y -qq certbot python3-certbot-nginx
  elif command -v dnf >/dev/null; then dnf install -y -q certbot python3-certbot-nginx
  else yum install -y -q certbot python3-certbot-nginx; fi
fi
certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --email "$EMAIL" --redirect || echo "!! certbot failed — http will still work; rerun: certbot --nginx -d $DOMAIN"

echo "== 5/5 auto-deploy (git pull every 5 min) =="
( crontab -l 2>/dev/null | grep -v chichibu-art ; echo "*/5 * * * * git -C $ROOT pull --ff-only >/dev/null 2>&1" ) | crontab -

echo ""
echo "DONE -> https://$DOMAIN"
