#!/bin/bash -e
################################################################################
##  File:  install-mkcert.sh
##  Desc:  Install mkcert (fork-only: vor-stream CI's prepare-host action)
##  Supply chain security: mkcert - pinned version and checksum
################################################################################
# vor-stream's .github/actions/prepare-host pins the same version and
# checksums and skips its download only when /usr/local/bin/mkcert matches.
# Bump both together, or every job downloads mkcert from GitHub again.

# Source the helpers for use with the script
source $HELPER_SCRIPTS/install.sh
source $HELPER_SCRIPTS/os.sh

version="v1.4.4"
if is_x64; then
  arch="amd64"
  sha256="6d31c65b03972c6dc4a14ab429f2928300518b26503f58723e532d1b0a3bbb52"
elif is_arm64; then
  arch="arm64"
  sha256="b98f2cc69fd9147fe4d405d859c57504571adec0d3611c3eefd04107c7ac00d0"
else
  echo "Unsupported architecture"
  exit 1
fi

binary_path=$(download_with_retry "https://github.com/FiloSottile/mkcert/releases/download/${version}/mkcert-${version}-linux-${arch}")
use_checksum_comparison "$binary_path" "$sha256"
install -m 0755 "$binary_path" /usr/local/bin/mkcert

mkcert -version
