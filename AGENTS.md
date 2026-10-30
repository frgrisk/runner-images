# Repo notes

This is a fork: `origin` is `frgrisk/runner-images`, `upstream` is `actions/runner-images`. Upstream builds on Azure; this fork builds AMIs on AWS.

- Commit and push straight to `main`: one maintainer, and every push to `main` starts Image Build, which builds real AMIs in each region. For a commit that changes nothing the images use (docs, agent files), add `[skip ci]` to the message so the push doesn't rebuild identical AMIs.
- Pass `--repo frgrisk/runner-images` to every `gh pr create`: without it, `gh` defaults to the upstream parent and the PR lands on `actions/runner-images`.
- Keep `concurrency.cancel-in-progress` and `strategy.fail-fast` off in `.github/workflows/image_build.yaml`, and let a running Image Build finish rather than cancelling it: cancellation skips Packer's cleanup and leaves orphaned EC2 instances, security groups, key pairs, and partial AMIs/snapshots in the AWS account.
- Upstream merges periodically add new `images/ubuntu/templates/build.*.pkr.hcl` files that use `source.azure-arm.image`. This fork installs only the `amazon` plugin, and `packer build .` parses *every* `.pkr.hcl` in the dir even with `-only=`, so these fail fast with `Error: Unknown source type azure-arm`. Fix: switch each new file's `sources` line to `["source.amazon-ebs.build_image"]` (edit rather than delete, so future merges stay clean). Verify from `images/ubuntu/templates/`: `packer init . && packer validate -only=ubuntu-22_04.amazon-ebs.build_image -var region=us-east-2 -var=image_os=ubuntu22 .`
