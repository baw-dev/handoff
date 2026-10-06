# Configuration

Everything that can be set, and where. The examples use the Mystery Inc. cast
from the README: `fred`, `velma`, `shaggy` and `scooby`.

## Files

| File | Scope | Holds |
|---|---|---|
| `~/.claude/handoffs/machine` | Machine | One word: this machine's label, as the rosters spell it |
| `~/.claude/handoffs/limits.json` | Machine | The ceilings |
| `~/.claude/handoffs/<project>/roster.json` | Project, every machine | The sessions |
| `~/.claude/handoffs/<project>/paths` | Project, this machine | The project's directories, one to a line. `#` starts a comment. |
| `~/.claude/handoffs/<project>/rules.md` | Project | What each role does. Optional. Sessions read it. |

A session is in a project when its working directory is one listed in `paths`, or
below one. A directory that no project lists, or that two list, is refused.

Nothing is written into a project's repository.

## Limits

| Limit | Default | Least | Meaning |
|---|---|---|---|
| `hop_limit` | 6 | 2 | The most hops a chain may have, its report included |
| `ttl_hours` | 24 | 1 | How long a chain lives before its notes are refused |
| `max_starts_per_day` | 8 | 1 | How many chains a project may start on this machine in 24 hours |

`limits.json` holds this machine's ceilings. A roster may ask for less under
`"limits"`. It cannot get more: the lower of the two is in force. The ceilings are
the user's, and no project file raises them.

## The roster

```json
{
  "v": 2,
  "project": "mystery-inc",
  "limits": {"hop_limit": 4},
  "sessions": [
    {"name": "fred", "role": "hub", "machine": "laptop",
     "model": "claude-opus-5-5", "effort": "high",
     "starts": true, "reply": "untested",
     "notes": "Plans the work, starts every chain, receives every report."},
    {"name": "velma", "role": "checker", "machine": "laptop",
     "model": "claude-fable-5-1", "effort": "high",
     "starts": false, "reply": "untested"},
    {"name": "shaggy", "role": "worker", "machine": "laptop",
     "starts": false, "reply": "untested"},
    {"name": "scooby", "role": "worker", "machine": "buildbox",
     "starts": false, "reply": "untested"}
  ]
}
```

| Field | Required | Values |
|---|---|---|
| `v` | Yes | `2` |
| `project` | Yes | Lower-case words joined by hyphens. The same as the directory's name. |
| `limits` | No | Any of the three limits, to lower them for this project |
| `name` | Yes | Letters, digits and underscores. The session's name, exactly, case included. |
| `machine` | Yes | A machine's label |
| `reply` | Yes | `yes`, `no` or `untested`: whether this session has been seen to answer |
| `starts` | No | `true` lets the session start a chain. Absent means `false`. One session at least must have it. |
| `role` | No | Any word. `rules.md` says what it means. |
| `model` | No | A model id. A declaration: nothing verifies it. |
| `effort` | No | `low`, `medium`, `high`, `xhigh` or `max`. A declaration. |
| `notes` | No | Anything a sender should know before choosing this session |

## Commands

```
handoff roster                                  the project, the limits, the sessions
handoff status                                  every chain, its hop, holder and state
handoff idle <name>                             exit 0 if <name> holds no open or reported chain here, else 1
handoff send ...                                mint a note; the body is read from stdin
handoff receive [--id <id>]                     validate and record a note
handoff close --chain <chain> --reason "..."    end a chain that was abandoned
```

Exit statuses: 0 ok, 2 refused, 3 duplicate, 4 malformed or sum mismatch. `idle`
alone also exits 1, and lists the chains `<name>` holds.

## Options when minting a note

| Option | With | Meaning |
|---|---|---|
| `--start` | | Begin a chain. Needs `--from`, `--to`, `--slug`. |
| `--parent <id>` | | Continue the note `<id>`, or report on it |
| `--report` | `--parent` | A report to `return_to`, not a work note |
| `--goal "<text>"` | Always | One line, 100 characters at most |
| `--slug <words>` | `--start` | Names the chain. Four random hex digits are added. |
| `--return-to <name>` | `--start` | Who the report goes to. The sender, if not given. |
| `--limit <n>` | `--start` | A lower hop limit for this one chain |
| `--needs-user "<reason>"` | `--report` | Marks the report as needing the user |

## Environment

| Variable | Default | Meaning |
|---|---|---|
| `HANDOFF_HOME` | `~/.claude/handoffs` | The base directory |
| `HANDOFF_PROJECT` | None | The project by name, whatever the working directory |
| `CLAUDE_CONFIG_DIR` | `~/.claude` | Read by `install.sh` only: where the skill is installed |
| `HANDOFF_ROSTER` | None | A roster file to use as it stands. For `check.sh`. |
| `HANDOFF_NOW` | None | The clock. For `check.sh`. |

Every note's footer names the script as `~/.claude/skills/handoff/scripts/handoff`.
A skill installed anywhere else is not what a receiver will be told to run.

## What is in this repository

```
skill/SKILL.md            what a session reads
skill/scripts/handoff     mints, validates and records notes
skill/scripts/check.sh    runs the script's cases against throwaway state
examples/mystery-inc/     a project to copy: a roster, a paths file, a rules file,
                          and a hand-off file template for succession
examples/limits.json      the default ceilings
install.sh                copies skill/ into place, checks it, compares sums
```

Change the skill here and install it. Do not edit the installed copy.
