#!/bin/bash
set -euo pipefail

start_time=$SECONDS
# TODO: replace hardcoded filename and site path
# TODO: Remove timing profiling commands
sitepath="/var/www/ec2.johnjflynn.net"
filename="example-application-356310c.tar.gz"

aws s3 cp "s3://${bucket_uri}/$filename" "$sitepath"
tar -xzf "$sitepath/$filename" -C "$sitepath" --strip-components=1
rm "$sitepath/$filename"
chown -R www-data:www-data "$sitepath"
chmod -R 775 "$sitepath/storage"
rm "$sitepath/.env"

# Set ENV Variables

end_time=$SECONDS
echo $((end_time - start_time)) > /script_time
