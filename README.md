# github-actions

Central, reusable GitHub Actions workflows shared across my repos. Edit the logic
here **once**; every consuming repo picks it up on its next run via `uses:` — no
copy-paste, no package manager.

## Workflows

| Reusable workflow | What it does |
|---|---|
| `.github/workflows/claude-review.yml` | Automated Claude PR review (official `code-review` plugin + web tools). Skips drafts and PRs labeled `skip-review`. |
| `.github/workflows/claude-mention.yml` | On-demand `@claude` responder on issues/PRs. |

Consuming repos don't copy these — they add a tiny **caller** that delegates here
(see [`examples/`](./examples)). The caller never changes; all real logic is central.

## Add Claude to a repo

```sh
cd ~/github/<repo>
~/github/github-actions/install-claude.sh          # writes callers + label
# one-time auth (draws on your Claude subscription, not metered API):
claude setup-token
CLAUDE_CODE_OAUTH_TOKEN=<token> ~/github/github-actions/install-claude.sh
git add .github/workflows && git commit -m "ci: Claude review + mentions" && git push
```

Prereq: the [Claude GitHub App](https://github.com/apps/claude) installed on the repo
(install once account-wide).

## The gating flow

- **Draft PR** → no auto-review. Mark **ready** → reviews once.
- **`skip-review` label** → skips even a ready PR.
- **`@claude review`** in a comment → on-demand review anytime (via `claude-mention.yml`).

## Versioning

Callers pin `@v1`. Improve a workflow here, move the `v1` tag (or push `main`), and
all repos inherit it on their next PR. Pin a commit SHA instead of `@v1` for
immutability.
