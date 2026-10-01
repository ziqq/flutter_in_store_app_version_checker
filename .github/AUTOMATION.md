# Repository automation

This repository uses reusable actions pinned to
`ziqq/actions@ccd1a799683cd461a45d9303ac6fcb2792f8f5d2`.

## Semantic labels

`.github/labels.json` is the repository-owned source of truth. Automation uses
stable semantic IDs while GitHub displays configurable names:

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
- merging into `main` moves linked issues to `waiting for publish`;
- publishing a GitHub release moves matching issues to `done`;
- an author or assignee response resumes only an issue already marked
  `waiting for response`;
- manually assigning lifecycle labels normalizes mutually exclusive states;
- Markdown and test changes add their configured path labels to pull requests.

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

## Manual plan and apply

Run the `Semantic labels` workflow from the Actions tab. Manual runs default to
`sync-labels` with `dry_run: true`. Review the `plan` output before rerunning
with dry-run disabled. `apply` additionally requires a transition, target kind,
and comma-separated target numbers.

Pattern removal and label deletion are separate explicit inputs. The current
configuration never deletes unmanaged labels. Do not enable deletion without a
reviewed dry-run: deleting a GitHub label removes it from every issue and pull
request.

## Trust and concurrency

Pull request automation runs on `pull_request_target`, but the action reads the
configuration from the trusted base SHA through the GitHub API. No pull request
head code is checked out with a write token. The workflow serializes label
operations and does not cancel an in-progress transition.

The first pull request introducing this workflow cannot execute its own new
write-capable configuration. After merge, run one manual label sync; following
events will use the trusted default-branch file.

## Notifications

`.github/workflows/notifications.yml` sends a required notification to Discord
and Telegram when a new issue is opened.

The final `notify` job in `.github/workflows/checkout.yml` runs after every CI
result on pushes, manual runs, and same-repository pull requests. Fork and
Dependabot pull requests are skipped because GitHub does not expose repository
secrets to them. CI delivery is best-effort and cannot change the result of the
actual checks. A whole workflow canceled by concurrency may stop before the
notification job starts.

`.github/workflows/publish.yml` also runs a required notification after the
reusable publish job, including when publication fails.

Configure these repository Actions secrets:

| Secret | Value |
|---|---|
| `DISCORD_WEBHOOKS` | JSON object with a target list, for example `{"targets":[{"url":"https://discord.com/api/webhooks/..."}]}` |
| `TELEGRAM_BOT_TOKEN` | Token issued by BotFather |
| `TELEGRAM_TARGETS` | JSON object with a target list, for example `{"targets":[{"chatId":"123456789"}]}` |

To obtain a Telegram `chatId`, send the bot a message and call the official Bot
API `getUpdates` method. Read `message.chat.id`; channel updates use
`channel_post.chat.id`. A forum topic can add `"threadId":"42"` to the target.
`getUpdates` is unavailable while the bot has an outgoing webhook configured.
Never commit or paste the bot token, webhook URL, or target list into workflow
files.

All templates live in `.github/notify/templates/`. Dynamic issue titles are
escaped by the action. Delivery uses a 10-second per-request timeout and at
most five attempts for retryable failures. Logs and outputs contain neither
credentials, target identifiers, nor rendered message bodies.
