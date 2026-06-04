#!/bin/bash -e
################################################################################
##  File:  install-consul.sh
##  Desc:  Install consul
################################################################################

source $HELPER_SCRIPTS/install.sh
source $HELPER_SCRIPTS/os.sh

if is_x64; then
  consul_arch="amd64"
elif is_arm64; then
  consul_arch="arm64"
else
  echo "Unsupported architecture"
  exit 1
fi

# Install Consul
download_url=$(curl -fsSL https://api.releases.hashicorp.com/v1/releases/consul/latest | jq -r ".builds[] | select((.arch==\"$consul_arch\") and (.os==\"linux\")).url")
archive_path=$(download_with_retry "${download_url}")
unzip -o -qq "$archive_path" -d /usr/local/bin

invoke_tests "Tools" "Consul"
