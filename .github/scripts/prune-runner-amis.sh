#!/usr/bin/env bash
# Removes the runner AMIs this repository built that nothing needs, with their snapshots.
#
#   prune-runner-amis.sh <region> <keep>     keep: how many of the newest to leave
#   DRY_RUN=true prune-runner-amis.sh ...    prints what it would remove, changes nothing
#
# An AMI goes only when the build tagged it runner-images:prunable=true, it is not among the
# <keep> newest of those in <region>, no deploy has tagged it runner-ami:in-use:<env>, and its
# deregistration protection is off. The deploy step of vor-stream-sdlc-terraform
# (configuration/github-runner-autoscaler/deploy.sh) tags an AMI and turns protection on
# before a stack launches from it, so EC2 refuses the removal if that lands after this read.
set -Eeuo pipefail

region=${1:?usage: prune-runner-amis.sh <region> <keep>}
keep=${2:?usage: prune-runner-amis.sh <region> <keep>}
if [[ ! $keep =~ ^[1-9][0-9]*$ ]]; then
  printf 'prune: keep must be a positive integer, got %q\n' "$keep" >&2
  exit 64
fi

# Newest first: "<ami> <protection> <number of in-use tags>" per line.
rows=$(aws ec2 describe-images --region "$region" --owners self \
  --filters Name=tag:runner-images:prunable,Values=true \
  --query "reverse(sort_by(Images, &CreationDate))[].[ImageId, DeregistrationProtection || 'disabled', length(Tags[?starts_with(Key, 'runner-ami:in-use:')] || \`[]\`)]" \
  --output text)

n=0 failed=0
while read -r ami protection marks <&3; do
  [[ -n $ami ]] || continue
  n=$((n + 1))
  if ((n <= keep)); then
    printf 'keep %s: one of the %d newest\n' "$ami" "$keep"
  elif ((marks > 0)); then
    printf 'keep %s: a deploy marked it in use\n' "$ami"
  elif [[ $protection != disabled ]]; then
    printf 'keep %s: deregistration protection is %s\n' "$ami" "$protection"
  elif [[ ${DRY_RUN:-false} == true ]]; then
    printf 'would remove %s\n' "$ami"
  elif ! left=$(aws ec2 deregister-image --region "$region" --image-id "$ami" --delete-associated-snapshots \
    --query "DeleteSnapshotResults[?ReturnCode != 'success' && ReturnCode != 'skipped'].[SnapshotId, ReturnCode]" \
    --output text); then
    failed=$((failed + 1))
  elif [[ -n $left ]]; then
    printf 'removed %s; snapshot not deleted: %s\n' "$ami" "$left" >&2
    failed=$((failed + 1))
  else
    printf 'removed %s\n' "$ami"
  fi
done 3<<<"$rows"

((failed == 0))
