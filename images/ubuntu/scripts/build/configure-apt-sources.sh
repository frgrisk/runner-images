#!/bin/bash -e
################################################################################
##  File:  configure-apt-sources.sh
##  Desc:  Configure apt sources with failover from the EC2 regional mirror to Ubuntu archives.
################################################################################

source $HELPER_SCRIPTS/os.sh

if ! is_ubuntu22; then
    sources_file=/etc/apt/sources.list.d/ubuntu.sources
else
    sources_file=/etc/apt/sources.list
fi

# EC2 base images point apt at the build region's mirror. Ports-archive images (22.04 and 24.04 arm64)
# have no such URI, so their sources stay unchanged and the mirror list goes unused.
ec2_mirror_regex='http://[a-z0-9-]+\.ec2\.archive\.ubuntu\.com/ubuntu/'
ec2_mirror=$(grep -m1 -oE "$ec2_mirror_regex" "$sources_file" || true)

touch /etc/apt/apt-mirrors.txt

if [[ -n "$ec2_mirror" ]]; then
    printf "%s\tpriority:1\n" "$ec2_mirror" | tee -a /etc/apt/apt-mirrors.txt
fi
printf "https://archive.ubuntu.com/ubuntu/\tpriority:2\n" | tee -a /etc/apt/apt-mirrors.txt
printf "https://security.ubuntu.com/ubuntu/\tpriority:3\n" | tee -a /etc/apt/apt-mirrors.txt

sed -i -E "s|${ec2_mirror_regex}|mirror+file:/etc/apt/apt-mirrors.txt|" "$sources_file"

# Apt changes to survive Cloud Init
if ! is_ubuntu22; then
    cp -f "$sources_file" /etc/cloud/templates/sources.list.ubuntu.deb822.tmpl
else
    cp -f "$sources_file" /etc/cloud/templates/sources.list.ubuntu.tmpl
fi
