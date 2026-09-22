# Repository automation

This repository uses reusable actions pinned to
`ziqq/actions@6bc6fdad743d4054c9b0603bb75f6aefa5235be6`.

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
| `DISCORD_WEBHOOKS` | JSON array of webhook URLs, for example `["https://discord.com/api/webhooks/..."]` |
| `TELEGRAM_BOT_TOKEN` | Token issued by BotFather |
| `TELEGRAM_TARGETS` | JSON object with a target list, for example `{"targets":[{"chatId":"123456789"}]}` |

To obtain a Telegram `chatId`, send the bot a message and call the official Bot
API `getUpdates` method. Read `message.chat.id`; channel updates use
`channel_post.chat.id`. A forum topic can add `"threadId":"42"` to the target.
`getUpdates` is unavailable while the bot has an outgoing webhook configured.
Never commit or paste the bot token, webhook URL, or target list into workflow
files.

All templates live in `.github/notify/`. Dynamic issue titles are escaped by
the action. Delivery uses a 10-second per-request timeout and at most five
attempts for retryable failures. Logs and outputs contain neither credentials,
target identifiers, nor rendered message bodies.
