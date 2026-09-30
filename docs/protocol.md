# The protocol

This is the reference for what the script accepts and refuses. `skill/SKILL.md` is
what a session follows; this file is what a maintainer reads.

The examples use a made-up project, `mystery-inc`, whose sessions are `fred` the
hub, `velma` the checker, and `shaggy` and `scooby` the workers.

## The note

```
HANDOFF work 2/6 fred -> shaggy [unmask-ghost-7f3a]: check every window latch on the ground floor
v: 1
return_to: fred
needs_user: no
deadline: 2026-09-28T18:05:00Z
sum: 3f9a1c0b7d2e4a61

## Goal
## State
## Next
## Done when

--- handoff v1: how to act on this note ---
...
--- end handoff unmask-ghost-7f3a.2 ---
```

| Part | Rule |
|---|---|
| Line 1 | The only carrier of kind, hop, limit, sender, target, chain and goal. It is what the receiver's user sees as a preview, so it is a whole sentence. |
| Kind | `work` or `report` |
| Chain | The slug given at the start, a hyphen, and four random hex digits |
| Id | `<chain>.<hop>` |
| Goal | One line, 100 characters at most |
| `v` | The note version, 1. The roster has its own version. |
| `return_to` | Set at the start, inherited by every later note |
| `needs_user` | `no`, or `yes - <reason>`. Only a report may carry `yes`. |
| `deadline` | Set at the start from `ttl_hours`, inherited by every later note |
| `sum` | The first 16 hex digits of a sha256 over the note, with the `sum` line dropped and all whitespace collapsed |
| Body | 8000 characters at most. Work: `## Goal`, `## State`, `## Next`, `## Done when`. Report: `## Result`, `## Evidence`, `## Open`. |
| Footer | Generated. A work note's asks for exactly one note in answer. A report's asks for none. |

Because whitespace is collapsed before the sum is taken, a note that was re-wrapped
or re-spaced in passing still matches. A note that was reworded does not.

The note is found inside a message by its `HANDOFF` line and its end marker, so the
wrapper a harness puts around a message does not hide it.

## The chain

- **The note's text is the authority** for chain, hop and limit. Ledgers are per
  machine and per project. They dedupe and audit.
- **Every message is a hop**, a report included.
- **The last hop is reserved for a report.** With a limit of 6, work notes use hops
  1 to 5. A chain therefore ends with a report, not in silence.
- **A chain is linear.** A note's file is created exclusively, and a parent that has
  a child is refused another.
- **A chain is started with `--start` or continued with `--parent`**, never both.
  A session that holds a note it has not answered is refused a start.
- **A report goes to `return_to`**, and nowhere else.

## States

| State | Meaning | Written where |
|---|---|---|
| `open` | A note is out and unanswered | |
| `reported` | This machine sent the chain's report | Read from the ledger; nothing is written |
| `closed` | This machine received the report, or the chain was closed by hand | A `closed` event |
| `expired` | The deadline passed | Read from the ledger; nothing is written |

A chain is closed where its report is received. The machine that sent the report
hears nothing more, which is why it has a state of its own.

## What is refused

Exit status 2, `REFUSED`:

| At | Refused |
|---|---|
| Any command | No project for this directory, or more than one. No machine label. No `limits.json`. A roster that is not version 2, names another project, lists no session that may start, or holds an unknown limit or effort. |
| `send --start` | A sender or target not in the roster. A sender on another machine. A sender the roster does not let start. A target that is the sender. A sender holding an unanswered note. The daily start cap reached. A limit above the one in force. |
| `send --parent` | A parent not received here. A parent that already has a child. A closed chain. A passed deadline. A work note at the last hop. A work note carrying `needs_user`. A report addressed to anyone but `return_to`. A report from `return_to` to itself. |
| `receive` | A note for a session on another machine. A limit above the one in force. A deadline that has passed, or lies further off than `ttl_hours` allows. A closed chain. |
| `close` | A chain the ledger does not know, or one already closed. |

Exit status 3, `DUPLICATE`: a note already received here.

Exit status 4, `MALFORMED`: no `HANDOFF` line, no end marker, a missing header, a
body without its headings or holding a line that reads as framing, a sum that does
not match.

A refusal prints one line on standard error and nothing on standard output, so a
refused note cannot be sent by mistake. It is written to the ledger when there is a
ledger to write to.

## The roster

```json
{
  "v": 2,
  "project": "mystery-inc",
  "limits": {"hop_limit": 4},
  "sessions": [
    {"name": "fred", "role": "hub", "machine": "laptop",
     "model": "claude-opus-5-5", "effort": "high",
     "starts": true, "reply": "untested", "notes": "..."}
  ]
}
```

| Field | Required | Read by the script |
|---|---|---|
| `v` | Yes, 2 | Yes |
| `project` | Yes. A slug, and the name of the directory the roster is in. | Yes |
| `limits` | No | Yes. Each is capped by the machine's ceiling. |
| `name` | Yes. Letters, digits and underscores. | Yes. It is the address. |
| `machine` | Yes | Yes |
| `reply` | Yes: `yes`, `no` or `untested` | For a warning only |
| `starts` | No; absent means false | Yes |
| `effort` | No: `low`, `medium`, `high`, `xhigh` or `max` | Checked for spelling, otherwise shown |
| `role`, `model`, `notes` | No | Shown by `handoff roster` |

`model` and `effort` are declarations. Nothing verifies them.

## The ledger

One JSON object to a line, appended under a lock, never rewritten.

| Event | When |
|---|---|
| `sent` | A note was minted. Carries `parent`, null for a start. |
| `received` | A note was validated and recorded |
| `refused` | A command was refused. Carries `command`, `code`, `reason`. |
| `closed` | A report was received, or `close` was run. Carries `reason`. |

Every event carries `ts`, `machine` and `project`. Events written before version 2
of the roster carry no `project`.

A chain that crosses machines has its events split between their ledgers: each
holds what happened on it.

## An open question

`SKILL.md` tells a session to stop and tell its user whenever the script prints
`REFUSED`. It also tells a session whose chain is at its limit to report what is
done and what is open. When the refusal is the limit itself, the two pull apart.
A session met this in a live test, reported, and said which rule it had followed.
Which rule governs has not been decided.
