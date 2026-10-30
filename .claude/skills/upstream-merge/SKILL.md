---
name: upstream-merge
description: Merge an actions/runner-images release tag into this AWS fork and get Image Build green on main.
disable-model-invocation: true
---

# Upstream merge

Upstream builds on Azure; this fork builds AMIs on AWS with only the Packer `amazon` plugin. Every merge risks carrying an Azure assumption into a **divergence point**: a file where the fork keeps an AWS version of upstream's Azure code. The merge is done when Image Build on `main` is green in every region of its matrix.

## Steps

1. **Merge.** On `main`: `git fetch upstream --tags`, then `git merge <tag>` (tags look like `ubuntu24/20261026.354`). Done when `git status` lists the conflicted paths.

2. **Resolve hunk by hunk.** Edit inside each conflict block so upstream's clean hunks elsewhere in the same file survive. `git checkout --ours <file>` replaces the whole file and discards them; `git checkout -m <file>` restores the conflict if that happens. Where upstream's side of a hunk is Azure-only, keep the fork's side. Done when `git diff --name-only --diff-filter=U` is empty and `git diff MERGE_HEAD -- <file>` shows only the fork's AWS changes for each resolved file.

3. **Audit divergence points.** A clean merge can still carry an Azure assumption. Read `git diff HEAD...MERGE_HEAD` for every path in the table below, and for every new or changed test under `images/ubuntu/scripts/tests/`: a new test can assert Azure-only behavior the fork never had. Done when every Azure assumption is adapted to AWS or confirmed harmless on EC2.

4. **Validate.** `packer init images/ubuntu/templates`, then `packer validate -var region=us-east-2 -var image_os=ubuntu24 images/ubuntu/templates`. Done when it prints `The configuration is valid.`

5. **Ship.** Commit the merge on `main`, push, and watch the Image Build run for that commit to the end. On failure, read the failed job's own log (`gh run view --job <id> --log-failed`) and fix forward with new commits on `main`. Done when the run is green in every region.

## Divergence points

| Path | Fork's AWS version | Upstream's Azure version |
|---|---|---|
| `images/ubuntu/templates/source.ubuntu.pkr.hcl` | `amazon-ebs` sources `build_image` and `build_image_arm64`, with the spot fleet settings | `source "azure-arm" "image"` |
| `images/ubuntu/templates/build.*.pkr.hcl` | `sources` names an `amazon-ebs` source | `source.azure-arm.image` |
| `images/ubuntu/scripts/build/configure-environment.sh` | no Azure agent or resource-disk setup | `waagent.conf` swap, cloud-init `/mnt` resource-disk mount |
| `images/ubuntu/scripts/build/configure-apt-sources.sh` | mirror list starts with the EC2 regional mirror | mirror list starts with `azure.archive.ubuntu.com` |

New upstream build files: Packer parses every `.pkr.hcl` in the directory even with `-only=`, so a new `build.*.pkr.hcl` on `source.azure-arm.image` fails every build with `Error: Unknown source type azure-arm`. Edit its `sources` line to `["source.amazon-ebs.build_image"]` and keep the file, so later merges stay clean.
