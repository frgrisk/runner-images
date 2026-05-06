# Repo notes

This is a fork. `origin` → `frgrisk/runner-images`, `upstream` → `actions/runner-images`.

- When opening PRs, ALWAYS pass `--repo frgrisk/runner-images` to `gh pr create`. Without it, `gh` defaults to the upstream parent and the PR lands on `actions/runner-images`.
- `.github/workflows/image_build.yaml` builds AMIs via Packer over a matrix of AWS regions. Do NOT re-enable `concurrency.cancel-in-progress` or `strategy.fail-fast` here — cancellation skips Packer's cleanup and leaves orphaned EC2 instances, security groups, key pairs, and partial AMIs/snapshots in the AWS account.
