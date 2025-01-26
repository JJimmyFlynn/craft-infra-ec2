#!/bin/bash
set -euo pipefail

function set_env_variables() {
    params=$(aws ssm get-parameters-by-path --with-decryption --path "$parameter_store_path")

    if (( $(echo "$params" | jq '.Parameters | length') = 0 )) ; then
        return 1
    fi

    jq -c '.Parameters[]' <<< "$params" | while read -r item; do
      var_name=$(jq -cr '.Name' <<< "$item" |  awk -F'/' '{print $NF}')
      var_value=$(jq -cr '.Value' <<< "$item")

      echo "$var_name=$var_value" >> "$site_path/.env"
      chown "$site_path/.env" www-data:
    done
}

function main {
  start_time=$SECONDS
  # TODO: replace hardcoded filename and site path
  # TODO: Remove timing profiling commands
  site_path="/var/www/ec2.johnjflynn.net"
  filename="example-application-356310c.tar.gz"
  parameter_store_path="/example-application/dev"

  aws s3 cp "s3://${bucket_uri}/$filename" "$site_path"
  tar -xzf "$site_path/$filename" -C "$site_path" --strip-components=1
  rm "$site_path/$filename"
  chown -R www-data:www-data "$site_path"
  chmod -R 775 "$site_path/storage"
  rm "$site_path/.env"

  # Set ENV Variables
  set_env_variables

  end_time=$SECONDS
  echo $((end_time - start_time)) > /script_time
}

# Run script
main
