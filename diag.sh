#!/bin/bash
# 診断用: art.schema.tokyo が403になる原因を調べる(閲覧のみ・何も変更しません)
#   curl -fsSL https://raw.githubusercontent.com/84ken/chichibu-art/main/diag.sh | bash
echo "=== 1. nginx内の art.schema.tokyo 設定箇所 ==="
grep -rn "art.schema.tokyo" /etc/nginx/ 2>/dev/null
echo ""
echo "=== 2. nginxが実際に読み込んでいるserver_name一覧 ==="
nginx -T 2>/dev/null | grep -nE "^# configuration file|server_name|proxy_pass|root " | head -60
echo ""
echo "=== 3. サイトファイルの有無 ==="
ls -la /var/www/chichibu-art/ 2>/dev/null | head -8 || echo "-> /var/www/chichibu-art がありません(cloneされていない)"
echo ""
echo "=== 4. 自動更新cron ==="
crontab -l 2>/dev/null | grep chichibu || echo "-> cron未登録"
echo ""
echo "=== 5. Apache のバーチャルホスト ==="
(apachectl -S 2>/dev/null || httpd -S 2>/dev/null || apache2ctl -S 2>/dev/null) | head -25
echo ""
echo "=== 診断ここまで。この出力を貼り付けてください ==="
