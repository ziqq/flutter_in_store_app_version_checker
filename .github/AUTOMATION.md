# Repository automation

This repository uses reusable actions pinned to
`ziqq/actions@ccd1a799683cd461a45d9303ac6fcb2792f8f5d2`.

## Semantic labels

`.github/labels.json` is the repository-owned source of truth. Automation uses
stable semantic IDs while visible label names remain configurable:

| Semantic ID | Visible label |
|---|---|
| `bug` | `bug` |
| `documentation` | `documentation` |
| `completed` | `done` |
| `duplicate` | `duplicate` |
| `help_wanted` | `help wanted` |
| `improvement` | `improvement` |
| `needs_testing` | `need test's` |
| `new_feature` | `new feature` |
| `waiting_for_release` | `waiting for publish` |
| `waiting_for_pull_request` | `waiting for pull request` |
| `waiting_for_response` | `waiting for response` |
| `in_progress` | `working in progress` |

The initial names, colors, and descriptions come from
`flutter_in_store_app_version_checker`. Existing repository-specific labels
are preserved because `sync.orphanPolicy` is `keep`.

Lifecycle transitions:

- a `github-<number>` branch starts work and links the branch to the issue;
- opening a linked pull request keeps the issue in progress;
- merging into `main` moves linked issues to `waiting_for_release`;
- publishing a GitHub release moves matching issues to `completed`;
- an author or assignee response resumes work waiting for a response;
- assigning lifecycle labels normalizes mutually exclusive states;
- documentation and test changes add path labels to pull requests.

Run the `Semantic labels` workflow manually to preview or apply an operation.
Manual runs default to `sync-labels` with `dry_run: true`. Pattern removal
and label deletion remain separate explicit inputs. The current configuration
does not delete unmanaged labels.

The `pull_request_target` jobs read the trusted base-branch configuration
through the GitHub API. No pull request head code is checked out with a write
token. Label jobs receive only the permissions needed for their operation;
only branch-to-issue linking receives `contents: write`.

The successful publication job in `.github/workflows/publish.yml` now calls
`release-completed`, pinned to
`ziqq/actions/labeler@a991545704ba3fc43380d2b6024db3ca6935e4a7`.
All publication/deployment prerequisites must succeed; failed, cancelled and
skipped runs never complete issues. The hook reads the default-branch label
configuration through the API and shares the label workflow's concurrency group.
It selects issues by `events.releasePublished`, moves them from
`waiting_for_release` to `completed`, and preserves unrelated labels. Empty
selections are allowed; pattern removal is explicitly enabled and bulk work is
limited to 100 issues. Manually published releases still use `release-published`.
No additional PAT is required for releases created with `GITHUB_TOKEN`.
See [GitHub token event rules](https://docs.github.com/en/actions/concepts/security/github_token).

## GitHub releases

`.github/workflows/release.yml` creates a GitHub release when an exact stable
semantic version tag such as `v3.1.0` is pushed. The release is named
`Release v3.1.0` and uses `Automated release for version v3.1.0` as its body.
Existing releases are left unchanged, so rerunning the workflow is safe.

The release workflow runs independently from the pub.dev publication workflow.
Both are triggered by the version tag created and pushed with
`mise exec -- just tag`.

## Pinned SDK and CI reports

Checkout, Android/iOS builds, and pub.dev validation/publication install tools
from `mise.toml` and `mise.lock` using `jdx/mise-action`. Dart comes from Flutter;
the workflows do not independently install a different Dart SDK. Local
validation runs with `mise exec -- just precommit`.

The Checkout job explicitly uses Bash with `pipefail`, so piping test output
through `tee` cannot hide a failing test exit code. Test artifacts are uploaded
only when a report exists. The reporter runs only after an artifact was
uploaded and only for trusted same-repository runs; fork and Dependabot PRs
still run checks/tests and upload reports but cannot create write-token checks.
Its job-scoped token permits only repository reads, artifact reads, and check
creation. No PR head runs with `pull_request_target` privileges.

The repository-local publish workflow preserves the 110-point pana gate and
requires the exact tag, pubspec version, and first changelog version to match.
It uses the existing `PUB_CREDENTIAL_JSON` secret with the pinned Dart CLI,
rather than a Docker publisher that installs a separate SDK. Credentials are
written only to the ephemeral runner's Dart config with owner-only permissions,
never printed, and removed after the publication step. No new secret or pub.dev
account configuration is required. Actual publication is not part of local
validation; `just publish-check` performs a dry run.

## Notifications

`.github/workflows/notifications.yml` calls
`ziqq/actions/.github/workflows/notify-events.yml@7737ce8c4d87c656b7ccf5f78138d8d7e53a1b62`
to send required Discord and Telegram notifications for newly opened issues
and pull requests (including drafts and forks).

Both events are explicitly enabled here with `notify-issues: true` and
`notify-pull-requests: true`. Set either input to `false` to disable that event;
the reusable workflow defaults both inputs to `false`. Edits, reopened items,
and draft-to-ready changes do not send another notification.

Templates belong to this repository: `.github/notify/templates/issue.md` and
`.github/notify/templates/pull-request.md`. Pull request notifications use
`pull_request_target` and check out only the trusted base SHA, never PR-head
code with repository secrets.

`.github/workflows/checkout.yml` sends a best-effort notification after CI results.
Fork and Dependabot CI pull requests are skipped because notification secrets
are not exposed to those runs. New-item notifications still support fork PRs.
A whole workflow cancelled by concurrency may stop before its notify job starts.

`.github/workflows/publish.yml` sends a required notification after publish/release/deploy,
including failed runs. The result summarizes all prerequisite jobs, including
matrix deployments.

Notifications use bold text at normal size, without heading markers or icons.
Only the version-checker package includes its optional `pub_dev_url` link.
The manual test sender remains in `ziqq/actions`; no test dispatch was added here.

Configure these Actions secrets in this repository:

| Secret | Value |
|---|---|
| `DISCORD_WEBHOOKS` | JSON object such as `{"targets":[{"url":"https://discord.com/api/webhooks/..."}]}` |
| `TELEGRAM_BOT_TOKEN` | Token issued by BotFather |
| `TELEGRAM_TARGETS` | JSON object such as `{"targets":[{"chatId":"123456789"}]}` |

To obtain a Telegram `chatId`, send the bot a message and call the official Bot
API `getUpdates` method. Read `message.chat.id`; channel updates use
`channel_post.chat.id`. A forum topic can add `"threadId":"42"` to the target.
`getUpdates` is unavailable while the bot has an outgoing webhook configured.
Never commit or paste the bot token, webhook URL, or target list into workflow
files.

Templates live in `.github/notify/templates/`. Dynamic values are escaped by
the action. Delivery uses a 10-second per-request timeout and at most five
attempts for retryable failures. Logs and outputs contain neither credentials,
target identifiers, nor rendered message bodies.

## CI action maintenance

The coverage uploader uses Codecov v5 pinned to an immutable commit instead of
the obsolete v3 runner. Coverage paths and the existing `CODECOV_TOKEN` contract
are unchanged.
