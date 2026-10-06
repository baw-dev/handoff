# Succession: fred, at the end of the ground-floor phase

<!-- A template. The outgoing hub copies it into the project, fills every
     section, and gives the copy's path and sha256 in the successor's prompt.
     Keep it short: point to files, do not restate them. -->

Written by the outgoing `fred` on `laptop`, 2026-10-05T18:00:00Z, at a boundary
the user picked. **Before acting on anything, check the sha256 of every file
below. If one differs or is missing, stop and tell the user.**

## Role and standing instructions

- You are `fred`, the hub of `mystery-inc`, on `laptop`. Take that name once the
  user has retitled the old session; `ListAgents` must show it on one row.
- You start every chain, and only on the user's instruction. Read
  `~/.claude/handoffs/mystery-inc/rules.md`.
- Standing instructions from the user, each with where it is recorded:
  - Velma checks every plan before work starts. (`rules.md`, Hub)
  - Nothing in the attic is touched until the user says so. (`case/rulings.md`, R-012)

## State

- Repository `mystery-inc`, branch `main` at `<commit>`. The working tree is clean.
- Phase: the ground floor is done; the cellar is next.
- Loop: stopped at 17:55. Restart it with `<the loop command and its interval>`.
- `handoff status` at the boundary: chains 7, open 0, reported 0, closed 7.

## Files the work rests on

| File | sha256 |
|---|---|
| `case/plan.md` | `<64 hex digits>` |
| `case/rulings.md` | `<64 hex digits>` |
| `case/evidence/latches.md` | `<64 hex digits>` |
| `case/jobs.md` | `<64 hex digits>` |

Check with `shasum -a 256 <file>` or `sha256sum <file>`.

## Next ids

Ruling R-013. Job J-032. Defect D-008.

## Queue

1. J-032: survey the cellar doors; `scooby`, cheap model, effort low.
2. J-033: fix the cellar latch, once J-032 is in; `shaggy`, effort high.
3. Review J-033's result; `velma`.

## Waiting on the user

- Whether the attic is in scope (asked 2026-10-05, R-012).

## At the next boundary

- At the end of the cellar phase, write this file again and hand over.
- Restart `shaggy` and `scooby` there, each once `handoff idle <name>` exits 0
  on its own machine and on `laptop`. `idle` sees only the ledger of the machine
  it runs on, and a note on its way is not in the receiver's ledger yet.
