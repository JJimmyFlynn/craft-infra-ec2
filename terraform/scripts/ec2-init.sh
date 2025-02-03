#!/bin/bash
set -euo pipefail

function set_env_variables() {
    params=$(aws ssm get-parameters-by-path --with-decryption --path "$parameter_store_path")

    if (( $(echo "$params" | jq '.Parameters | length') == 0 )) ; then
        return 1
    fi

    # Loops through the environment variables in SSM and
    # outputs them to a .env file in format of ENV_VAR=VALUE
    jq -c '.Parameters[]' <<< "$params" | while read -r item; do
      var_name=$(jq -cr '.Name' <<< "$item" |  awk -F'/' '{print $NF}')
      var_value=$(jq -cr '.Value' <<< "$item")

      echo "$var_name=$var_value" >> "$site_path/.env"
      chown www-data: "$site_path/.env"
    done
}

function main {
  site_path="/var/www/${site_domain}"
  # The current build artifact is stored in Parameter Store by the Github Actions CI/CD
  parameter_store_path="${parameter_store_path}"
  filename=$(aws ssm get-parameter --name "$parameter_store_path/build_artifact_name" --output json | jq -r '.Parameter.Value')

  aws s3 cp "s3://${bucket_uri}/$filename" "$site_path"
  tar -xzf "$site_path/$filename" -C "$site_path" --strip-components=1
  rm "$site_path/$filename"
  chown -R www-data:www-data "$site_path"
  chmod -R 775 "$site_path/storage"

  # Set ENV Variables
  set_env_variables
}

# Run script
main
