# Security

**Answers:** what handoff protects against, and how to report a problem.

handoff bounds chains of hand-offs between Claude Code sessions. **It is not a
security boundary.** It cannot tell which session wrote a note, and a note's
body is text a session will read and may act on. What keeps a session from
acting on a message you didn't intend is Claude Code itself: its permission
modes, which hold messages from a session in a different mode until you
approve them, and each session's own approvals. The README's "What it does
not do" lists the limits.

To report a vulnerability, use GitHub's **private vulnerability reporting**:
the **Security** tab of this repository, then **Report a vulnerability**.
Please don't open a public issue for a security problem.
