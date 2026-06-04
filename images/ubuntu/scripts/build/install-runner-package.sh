#!/bin/bash -e
################################################################################
##  File:  install-runner-package.sh
##  Desc:  Download and pre-extract runner package for faster instance startup
################################################################################

# Source the helpers for use with the script
source $HELPER_SCRIPTS/install.sh
source $HELPER_SCRIPTS/os.sh

if is_x64; then
  runner_arch="x64"
elif is_arm64; then
  runner_arch="arm64"
else
  echo "Unsupported architecture"
  exit 1
fi

download_url=$(resolve_github_release_asset_url "actions/runner" 'test("actions-runner-linux-'"${runner_arch}"'-[0-9]+\\.[0-9]{3}\\.[0-9]+\\.tar\\.gz$")' "latest")
archive_name="${download_url##*/}"
archive_path=$(download_with_retry "$download_url")

# Pre-extract runner for faster instance startup
mkdir -p /opt/actions-runner
tar xzf "$archive_path" -C /opt/actions-runner

# Set ownership to ubuntu user for runtime
chown -R ubuntu:ubuntu /opt/actions-runner

# Keep a copy of the archive for reference/backup
mkdir -p /opt/runner-cache
mv "$archive_path" "/opt/runner-cache/$archive_name"
