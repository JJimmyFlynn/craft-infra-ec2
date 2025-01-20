#!/bin/bash
set -euo pipefail

start_time=$SECONDS
# TODO: replace hardcoded filename and site path
# TODO: Remove timing profiling commands
sitepath=/var/www/johnjflynn.net
filename=europa.tar.gz

aws s3 cp "s3://${bucket_uri}/$filename" /var/www/johnjflynn.net
tar -xzf "$sitepath/$filename" -C /var/www/johnjflynn.net --strip-components=1
rm "$sitepath/$filename"
chown -R www-data:www-data "$sitepath"
chmod -R 775 "$sitepath/storage"

end_time=$SECONDS
echo $((end_time - start_time)) > /script_time
