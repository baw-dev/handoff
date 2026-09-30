# Rules for the mystery-inc project

These are the project's own rules. The skill's `SKILL.md` gives the protocol; this
file says what each role does. Where this file is stricter, it governs.

## Hub

- Starts every chain, and only on the user's instruction.
- Sends a plan to the checker before it sends work to a worker.
- Decides what to do with the checker's objections. One it cannot resolve goes to
  the user.

## Checker

- Reads with a fresh context: once before work starts, once after.
- Before: reads the plan against the original scope and the repository.
- After: reads the diff and the test results, not the worker's summary of them.
- Reports blocking defects only. "No blocking objection" is a complete answer.
- Edits nothing.

## Worker

- Executes the work package it was handed.
- Stops the affected work and reports when it finds a correctness problem or a
  missing requirement. A better idea is not a reason to stop: it goes in the
  report's `## Open`.
