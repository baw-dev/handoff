# handoff

[![ci](https://github.com/baw-dev/handoff/actions/workflows/ci.yml/badge.svg)](https://github.com/baw-dev/handoff/actions/workflows/ci.yml)
[![licence: MIT](https://img.shields.io/badge/licence-MIT-blue.svg)](LICENSE)

Claude Code sessions can message one another. This skill lets them hand work
over, and limits how far the handing-over can go.

One session sends another a note. A script writes the note, checks it when it
arrives, and keeps a ledger. Every chain of notes has a hop limit, and the last
hop is kept for a report, so a chain ends by telling someone what happened.

**Experimental.** handoff relies on Claude Code's messaging between sessions,
on Remote Control, and on the approval that holds a message between sessions
in different permission modes. These are new and may change. The live tests in
[docs/verification.md](docs/verification.md) ran in the last week of September
2026.

## Quick start

You need Python 3.8 or later and a POSIX shell.

```
./install.sh
echo laptop > ~/.claude/handoffs/machine
cp -R examples/mystery-inc ~/.claude/handoffs/my-project
```

Edit two files in `~/.claude/handoffs/my-project/`:

| File | Change |
|---|---|
| `roster.json` | `project` to `my-project`, and each `name` to one of your sessions' names |
| `paths` | Your project's directory |

The third file, `rules.md`, says what each role does. Edit it or delete it.

Check it, from inside your project's directory:

```
~/.claude/skills/handoff/scripts/handoff roster
```

Then ask your hub, in plain words, naming one of your sessions:

> Hand this to shaggy: check every window latch on the ground floor.

The hub writes a note, sends it, and ends its turn. The report comes back as a
message.

## How you might set it up, and why

Mystery Inc. has a case and four sessions.

| Session | Role | Why |
|---|---|---|
| `fred` | Hub | Someone has to say "let's split up." Fred plans the work, starts every chain and hears every report. One starter means one place to look when something goes wrong. |
| `velma` | Checker | Velma reads the plan before anyone acts on it, and the evidence afterwards. She runs a different model from Fred and starts fresh each time, so she neither shares his blind spots nor remembers his arguments. |
| `shaggy` | Worker | Shaggy does the job he is handed. If the plan says the cellar is empty and it isn't, he stops and says so. |
| `scooby` | Worker | The same, on another machine: the one that has what the job needs. |

A case runs like this:

1. You tell Fred what you want.
2. Fred sends Velma the plan. She answers "no blocking objection", or names the hole in it.
3. Fred hands Shaggy and Scooby a job each. Each reports back.
4. Fred sends Velma the results: the changes and the test output, not the workers' account of them.
5. Fred tells you what happened.

Three rules keep it honest:

- **Only Fred starts a chain.** The others can continue one and report on one.
- **Every chain is bounded.** Left alone, Shaggy and Scooby would keep adding
  layers to the sandwich all night. The hop limit is the top slice of bread.
- **Nobody marks their own homework.** Fred wrote the plan, so Velma judges the
  result.

Daphne is in the tests, where she plays the session that may not start a chain.

You don't need this cast. Two sessions and one role each is a fine start.

## What stops a chain

- **Your approval.** A session in a different permission mode from the sender's
  holds the message until you approve it there.
- **Distance.** A session on another machine is reachable only while Remote
  Control is on for the sender.
- **A refusal.** When the script refuses, the session stops and tells you why.

## Going further

| Read | For |
|---|---|
| [docs/configuration.md](docs/configuration.md) | Every file, limit, roster field, option and variable |
| [docs/protocol.md](docs/protocol.md) | The note, the chain, and what is refused |
| [docs/operating.md](docs/operating.md) | Running a team across restarts: succession, `handoff idle`, models, effort and tokens |
| [docs/verification.md](docs/verification.md) | What was tested, and what was not |

For a second machine, repeat the quick start there with that machine's label and
paths. `roster.json` is the same everywhere. `./install.sh --check` compares what
is installed with this checkout.

## What it does not do

- It does not stop a session from messaging another without the script. The limit
  holds for sessions that follow the skill.
- It does not verify a session's model or effort. The roster says what you
  intended; each report says what its sender found.
- Its checksum catches a note that was altered on the way. It is not a signature.
- **It is not a security boundary.** It cannot tell which session wrote a note:
  anything that can send a message can write one that passes. What holds a
  message you didn't intend is Claude Code's permission modes and your own
  approvals. See [SECURITY.md](SECURITY.md).
- It does not screen a note's body. The body is text the receiving session reads
  and may act on, like any message from another session.
- Its ledger is per machine. It sees another machine's chains only through the
  notes that arrive.
- It keeps what it is handed. Notes and the ledger stay under
  `~/.claude/handoffs/<project>/` until you delete them.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). handoff is released under the
[MIT licence](LICENSE).
