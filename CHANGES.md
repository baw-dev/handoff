# Changes

**Answers:** what changed in each release of handoff.

The release is `__version__` in `skill/scripts/handoff`, printed by
`handoff --version`, and `check.sh` fails if it differs from the first entry
below. It is separate from the note format (`v:` in every note, now 1) and the
roster format (`"v"` in `roster.json`, now 2). A change to either format is a
major release. Each entry has a permanent anchor, `#vMAJOR.MINOR.PATCH`, and a
matching git tag.

<a id="v1.0.1"></a>
## 1.0.1: a pointer for a target on the same machine (note format 1, roster format 2)

- **Sending to a session on the same machine** now sends the note's first line
  and the path of the stored note, instead of the whole text. The receiver
  records it with `handoff receive --id` and reads the stored note, which the
  script has already checked. A target on another machine still gets the
  whole note, verbatim.
- The script is unchanged apart from its version: `receive --id` already read
  the stored note.

<a id="v1.0.0"></a>
## 1.0.0: first public release (note format 1, roster format 2)

- **Hand-off notes** minted, validated and recorded by one Python script,
  with a checksum, a per-machine ledger, and a hop limit whose last hop is
  kept for a report.
- **One starter:** only the sessions the roster allows may begin a chain.
- **Per-project rosters and per-machine ceilings,** so a project can ask for
  tighter limits and never looser ones.
- **`check.sh`,** cases run against throwaway state, and an installer that
  copies, checks, and compares checksums.
- **An example setup,** Mystery Inc., in `examples/`.

Experimental: it relies on Claude Code's messaging between sessions, which may
change. See the README.
