#!/usr/bin/env bash
# Usage: run-pester-block.sh <test file> <name filter> [<setup command>]
#   <test file>      path under images/ubuntu/scripts/tests/, e.g. System.Tests.ps1
#   <name filter>    Pester FullName filter, e.g. "Azure resource disk mount timeout.*"
#   <setup command>  bash run first in the container, with the repo at /repo and HELPER_SCRIPTS set,
#                    e.g. "bash /repo/images/ubuntu/scripts/build/configure-apt-sources.sh"
# Runs one Pester block in an Ubuntu container in seconds, instead of a full AMI build.
# The container is not an EC2 image: it only proves what the setup command writes and what the block asserts.
# UBUNTU_VERSION (default 24.04) sets what lsb_release and the Test-IsUbuntu* helpers report.
set -euo pipefail
test_file=$1 filter=$2 setup=${3:-true}
version=${UBUNTU_VERSION:-24.04}
repo=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)

docker build -q --platform linux/amd64 -t runner-images-pester - > /dev/null <<'EOF'
FROM mcr.microsoft.com/powershell:7.4-ubuntu-22.04
RUN pwsh -NoProfile -Command "Install-Module Pester -RequiredVersion 5.6.1 -Force -Scope AllUsers"
EOF

docker run --rm --platform linux/amd64 -v "$repo:/repo:ro" \
  -e TEST_FILE="$test_file" -e FILTER="$filter" -e SETUP="$setup" -e UBUNTU_VERSION="$version" \
  runner-images-pester bash -c '
  set -e
  printf "#!/bin/sh\necho %s\n" "$UBUNTU_VERSION" > /usr/local/bin/lsb_release && chmod +x /usr/local/bin/lsb_release
  HELPER_SCRIPTS=/repo/images/ubuntu/scripts/helpers bash -ec "$SETUP"
  pwsh -NoProfile -Command "
    # Discovery evaluates -Skip conditions in every block; report the chosen release like the image would.
    function global:Test-IsUbuntu22 { \$env:UBUNTU_VERSION -eq \"22.04\" }
    function global:Test-IsUbuntu24 { \$env:UBUNTU_VERSION -eq \"24.04\" }
    function global:Test-IsUbuntu26 { \$env:UBUNTU_VERSION -eq \"26.04\" }
    \$c = New-PesterConfiguration
    \$c.Run.Path = \"/repo/images/ubuntu/scripts/tests/\$env:TEST_FILE\"
    \$c.Filter.FullName = \$env:FILTER
    \$c.Run.Exit = \$true
    \$c.Output.Verbosity = \"Detailed\"
    Invoke-Pester -Configuration \$c"
'
