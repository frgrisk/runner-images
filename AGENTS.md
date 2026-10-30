# Repo notes

This is a fork: `origin` is `frgrisk/runner-images`, `upstream` is `actions/runner-images`. Upstream builds on Azure; this fork builds AMIs on AWS.

- Commit and push straight to `main`: one maintainer, and every push to `main` starts Image Build, which builds real AMIs in each region. For a commit that changes nothing the images use (docs, agent files), add `[skip ci]` to the message so the push doesn't rebuild identical AMIs.
- Pass `--repo frgrisk/runner-images` to every `gh pr create`: without it, `gh` defaults to the upstream parent and the PR lands on `actions/runner-images`.
- Keep `concurrency.cancel-in-progress` and `strategy.fail-fast` off in `.github/workflows/image_build.yaml`, and let a running Image Build finish rather than cancelling it: cancellation skips Packer's cleanup and leaves orphaned EC2 instances, security groups, key pairs, and partial AMIs/snapshots in the AWS account.
- Merging an upstream release tag or resolving its conflicts: follow `.claude/skills/upstream-merge/SKILL.md`.
