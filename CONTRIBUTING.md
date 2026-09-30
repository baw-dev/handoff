# Contributing

**Answers:** how to change handoff and check the change before proposing it.

- **Change `skill/`, then run `./install.sh`;** never edit an installed copy.
- **Run `sh skill/scripts/check.sh`,** and `dash skill/scripts/check.sh` if you
  have dash. Every case must pass. A change in behaviour needs a case that
  fails without it.
- **Anything under `skill/` needs a release** in `__version__` and an entry in
  [CHANGES.md](CHANGES.md). A change to the note or roster format is a major
  release.
- **Record live tests** in `docs/verification.md`: what ran, on what, with what
  result, dated. It decides nothing.

Example rosters and rules for other shapes of team are welcome. Report
problems and ideas as [issues](https://github.com/baw-dev/handoff/issues).
