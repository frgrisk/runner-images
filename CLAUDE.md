# Repo notes

This is a fork. `origin` → `frgrisk/runner-images`, `upstream` → `actions/runner-images`.

- When opening PRs, ALWAYS pass `--repo frgrisk/runner-images` to `gh pr create`. Without it, `gh` defaults to the upstream parent and the PR lands on `actions/runner-images`.
- `.github/workflows/image_build.yaml` builds AMIs via Packer over a matrix of AWS regions. Do NOT re-enable `concurrency.cancel-in-progress` or `strategy.fail-fast` here — cancellation skips Packer's cleanup and leaves orphaned EC2 instances, security groups, key pairs, and partial AMIs/snapshots in the AWS account.
- Upstream merges periodically add new `images/ubuntu/templates/build.*.pkr.hcl` files that use `source.azure-arm.image` (upstream builds on Azure). This fork installs only the `amazon` plugin, and `packer build .` parses *every* `.pkr.hcl` in the dir even with `-only=`, so these fail fast with `Error: Unknown source type azure-arm`. Fix: switch each new file's `sources` line to `["source.amazon-ebs.build_image"]` (edit, don't delete — keeps future merges clean). Verify from `images/ubuntu/templates/`: `packer init . && packer validate -only=ubuntu-22_04.amazon-ebs.build_image -var region=us-east-2 -var=image_os=ubuntu22 .`
