# Running a team

**Answers:** how to run a team of sessions across restarts, with tokens low and
quality high.

This is guidance. The script enforces none of it, apart from `handoff idle`.
`skill/SKILL.md` says what a session must do; this file says why, and what has
worked. The examples use the Mystery Inc. cast: `fred` the hub, `velma` the
checker, and `shaggy` and `scooby` the workers.

## Why restart at all

A long session pays for its whole context on every turn, and after it compacts
it works from a summary of its own past. Restarting at a boundary keeps each
turn cheap and each session working from files rather than from memory. It only
works if what matters is already in files: rulings, evidence and the queue.
Nothing that decides the work should live only in a conversation.

## The hub's restart: succession

Your user picks the boundary, for example the end of a phase. At it, the
outgoing hub:

1. Writes a hand-off file from the template in
   [examples/mystery-inc/succession.md](../examples/mystery-inc/succession.md):
   its role and standing instructions, the state, the files the work rests on
   with the sha256 of each, the next ids, the queue, what waits on the user,
   and what to do at the next boundary.
2. Stops its loop, so two hubs never run at once.
3. Offers the user a one-click card that starts the successor, with a prompt
   naming the hand-off file and its sha256. Sessions cannot open sessions; the
   user clicks.
4. Asks the user to retitle the old session, say to `fred-old`, so the name
   `fred` routes to the successor.
5. Tells the workers that reports still go to `fred` and should be held, not
   sent to the old session, until the successor says it is up.

The successor reads the file, checks every sha256 before it acts, and stops if
one differs. It takes the name `fred`, checks the chains with `handoff status`,
tells the workers it is up, and resumes.

Start the successor on the hub's machine. The ledger is per machine, and the
successor carries on with it.

Keep the gap short. A report held past its chain's deadline is refused at
`send`; one sent before the deadline and received after it is refused at
`receive`. The work then has to be restated in a new chain. A chain whose report
was sent and then refused at `receive` stays `reported` on the ledger that sent
it, so
`handoff idle fred` there exits 1 until the chain is ended with `handoff close`.

## Worker restarts

Restart a worker only between chains, when it holds no open note: at the hub's
boundaries, or when it has compacted. Ask the script first:

```
handoff idle shaggy
```

It exits 0 when `shaggy` holds no open or reported chain on that machine's
ledger, and 1 otherwise, listing the chains. A chain's holder is the session
its latest note is addressed to, as `handoff status` shows it, so a report on
its way to `fred` is held by `fred` until he records it.

`idle` sees only the ledger of the machine it runs on. A note sent to `scooby`
from `laptop` is not in `buildbox`'s ledger until `scooby` receives it, so
`idle scooby` on `buildbox` alone can say 0 while a note is on its way. Run it on
the worker's machine and on the machine of every session that may send to the
worker, in practice the hub's. Restart the worker only when every one exits 0.

A worker restarted in a new session keeps its roster name. Ask the user to
retitle the old session first, so the name is on one row only.

## Models

Choose a model per job, not per session:

- **Fact-gathering surveys** and **diff-only re-checks of a fix:** a cheap
  model. The survey's answers are checked where they are used; the re-check
  reads only the fix.
- **One reviewer on results,** on a different model from the author's.
- **A second reviewer, on yet another model,** only where a miss is costly:
  questions put to the user, and changes to authority or permissions.

## Effort

Start a worker's effort from the kind of job:

| Job | Effort |
|---|---|
| Survey, re-check of a fix | `low` |
| Docs, configuration | `medium` |
| Code | `high`, never below `high` |
| Review of a plan or a result | `high` |

Then move it by what the reviews find:

- **Raise it one level for the next two jobs** after a review finds a blocker
  in a result, a regression, or a mismatch between what the hub checked and
  what the report said.
- **Lower it one level after three clean jobs,** never below `high` for code.
- **Revert at once** if a lowered effort is followed by a defect.

Keep a ledger in the project, one line per job: the date, the chain, the
session, its model and effort, the tokens the job used, and the defects its
review found. Write `unknown` for a figure the app does not give. The ledger is
what the rules above are applied to.

When an effort or a model changes, change the roster's row with it. Each
report's `Running as` line then shows whether the two still match.

## Keeping tokens low

- **Short reports.** Commits, digests of the files written, the test tally,
  departures from the brief, and open items. The full evidence goes in the
  project's own record, and the report says where.

  ```
  ## Result
  Done: ground-floor latches. Departures: none.
  ## Evidence
  Commits: 1a2b3c4. Record: evidence/latches.md, sha256 5e6f...
  Tests: one full run, 212 passed, 0 failed.
  Running as: <model>, effort high. The roster declares: <model>, effort high.
  ## Open
  Nothing.
  ```
- **One full test run per job.** Run the narrow tests while working and the
  whole suite once, at the end.
- **Reviewer briefs that say what the hub already checked,** so the reviewer
  spends its reading on what nobody has.
- **Shared fact surveys.** One survey, written to a file, serves every job that
  needs the same facts.
- **Two or three related pieces per job.** One is wasteful of the brief and the
  start-up; more is hard to review.
- **A pre-flight list** of the defects reviewers keep finding, kept in the
  project. The author runs through it before sending work for review, and the
  same list is applied to a reviewer's suggested fixes before they are made.
