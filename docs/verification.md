# What was tested, and what was not

A dated record. It says what ran, on what, with what result. It decides nothing.
Later changes to the script are not covered by the live tests below unless a line
says so.

## 2026-09-27: live tests between sessions

Four sessions took part: a controller, a planner and a worker on a Mac, all in the
Claude desktop app, and a worker on a Linux amd64 machine in a Docker sandbox,
reached over Remote Control. The controller and the planner ran one model; the two
workers ran another. The roster then was version 1 and lived beside the skill.

| Chain | Path | Hops | Result |
|---|---|---|---|
| `ping-dcb4` | controller, Mac worker, controller | 2 | Closed by report |
| `ping-c6c6` | controller, planner, controller | 2 | Closed by report |
| `ping-8dbb` | controller to Linux worker | 1 | Closed by hand: the skill was not installed there, and the worker said so in plain words |
| `ping-9936` | controller, Linux worker, controller | 2 | Closed by report |
| `main-compare-ee44` | controller, planner, Linux worker, controller | 3 | Closed by report |
| `limit-test-0dc0` | controller, Mac worker, planner, controller; limit 3 | 3 | Closed by report, after one refusal |

What those established:

- A session can trigger another with a prompt, and the other can answer, on one
  machine and across two.
- A note typed into a message by one session and piped to the script by another
  passed its checksum, in both directions across machines.
- A session that had never seen the skill learned the protocol from a note's footer.
- A live session minted a continuation with `--parent`, and the hop count, deadline
  and `return_to` were inherited.
- At a limit of 3, a session's attempt at a third work note was refused with exit
  status 2. It made no second attempt and sent the report in the reserved hop. A
  hop 4 attempted afterwards was refused because the chain was closed.
- A session on one machine gets one notice when a session on the same machine goes
  idle. A session on another machine gives none.
- Files of 30 kB sent as message text arrived byte for byte: every sha256 matched.
- A session asked by a peer to install the skill would not do so on the peer's word.
  It staged the files, asked its own user, and installed when the user agreed.

Two faults were found by the live tests and fixed the same day:

| Fault | Fix |
|---|---|
| A report carried a work note's footer, which asked for a note in answer to a chain the report had just closed | A report has its own footer |
| The machine that sent a report went on showing the chain as open | `status` shows such a chain as `reported` |

## 2026-09-27: the script's own cases

`skill/scripts/check.sh` was run after the change to version 2 of the roster.

| On | Shell | Python | Result |
|---|---|---|---|
| macOS, arm64 | `sh` | 3.14.4 | Every case passed |
| macOS, arm64 | `dash` | 3.14.4 | Every case passed |

Before that change, the version 1 script and its cases also passed on Linux amd64
under Python 3.11.2, and the script ran on Python 3.9.6.

## 2026-09-30: continuous integration

GitHub Actions ran `skill/scripts/check.sh` and the install round trip on every
push to the release commit.

| On | Shell | Python | Result |
|---|---|---|---|
| Ubuntu 22.04, amd64 | `sh` and `dash` | 3.8 to 3.13 | Every case passed |
| macOS, arm64 | `sh` | 3.9 to 3.13 | Every case passed |

No live session took part. The workflow is `.github/workflows/ci.yml`.

## 2026-10-05: release 1.1.0, the script's own cases

`skill/scripts/check.sh` was run on the `succession` branch, before it was
pushed. It now runs 174 checks, 30 of them for `handoff idle`.

| On | Shell | Python | Result |
|---|---|---|---|
| macOS, arm64 | `sh` | 3.14.4 | Every case passed |
| macOS, arm64 | `dash` | 3.14.4 | Every case passed |
| macOS, arm64 | `sh` | 3.9.6 | Every case passed |

CI has not run on this release: the branch has not been pushed. No live session
has run `idle`, and no hub has been restarted by the succession steps. The
guidance in `docs/operating.md` is advice drawn from use, not a tested result.

## Not tested

- **The version 2 script between live sessions.** Every live test above ran on
  version 1. The note format did not change, so the two versions exchange notes,
  but that has not been run.
- **The version 2 script on Linux.** *2026-09-30: its cases now pass on Linux
  in CI (above); no live session on Linux has run it.*
- **Finding the project from the working directory, in a live session.** The cases
  cover it; no session has yet relied on it.
- **A chain run with the user away.** Every hop in every live test waited for the
  user's approval in the receiving session, because the sessions were in a
  different permission mode from the sender's.
- **Python 3.8.** The script was written to run on it and has not been run on it.
  *2026-09-30: its cases now pass on Python 3.8 in CI (above), on Linux.*
- **Succession between live sessions.** No outgoing hub has written a hand-off
  file, and no successor has checked one and taken the roster name, under 1.1.0.
- **`handoff idle` in a live session,** and on Linux. Its cases pass on macOS
  only.
- **Two projects in use on one machine at once.** The cases cover separate ledgers;
  no two real projects have run side by side.

## Risks that remain

- Enforcement is advisory. A session can call `SendMessage` without the script.
- The checksum detects a changed note. It is not a signature: any session on the
  account can mint a valid note.
- Names are addresses. A renamed session, or two with one name, breaks routing.
- A roster's `model` and `effort` are declarations.
- A session on another machine, or a desktop session, returns no delivery report.
  Silence is not agreement.
- The baton rule, that a sender stops touching what it handed over, is an
  instruction and not a lock.
- All of it rests on features of the Claude desktop app and Claude Code that may
  change between versions.
