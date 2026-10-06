#!/bin/sh
# check.sh: run handoff's cases against throwaway state, and count what passed.
#
# Usage: check.sh
#
# Nothing under ~/.claude/handoffs is read or written, and no real project or
# session is named.  Everything happens under a temporary directory that is
# removed on exit.
#
# Most groups use two machines, labelled one and two, each with its own base
# directory, and a roster handed to the script as it stands (HANDOFF_ROSTER), so
# that a case can set its own hop_limit and max_starts_per_day.  The groups at
# the end use the layout a real machine has, and let the script find the project
# from the working directory.
#
# Every case names the exit status it expects.  The counts on the last line are
# computed from the cases that ran.  Exit status: 0 if every case passed, else 1.

set -eu

HERE=$(cd "$(dirname "$0")" && pwd)
HANDOFF="$HERE/handoff"
TMP=$(mktemp -d "${TMPDIR:-/tmp}/handoff-check.XXXXXX")
trap 'rm -rf "$TMP"' EXIT

PASS=0
FAIL=0
ROSTER=
PROJECT=
NOW=
STDIN=/dev/null

roster() {  # roster HOP_LIMIT MAX_STARTS: write a roster, and use it
    ROSTER="$TMP/roster-$1-$2.json"
    cat > "$ROSTER" <<EOF
{"v": 2, "project": "check",
 "limits": {"hop_limit": $1, "ttl_hours": 24, "max_starts_per_day": $2},
 "sessions": [
  {"name": "fred", "machine": "one", "role": "hub", "starts": true, "reply": "yes"},
  {"name": "velma", "machine": "one", "role": "checker", "starts": true, "reply": "yes"},
  {"name": "shaggy", "machine": "one", "role": "worker", "starts": true, "reply": "yes"},
  {"name": "scooby", "machine": "two", "role": "worker", "starts": true, "reply": "untested"},
  {"name": "daphne", "machine": "one", "role": "worker", "starts": false, "reply": "yes"}
 ]}
EOF
}

ceilings() {  # ceilings DIR HOP_LIMIT MAX_STARTS: a machine's limits.json
    cat > "$1/limits.json" <<EOF
{"hop_limit": $2, "ttl_hours": 24, "max_starts_per_day": $3}
EOF
}

fresh() {  # empty state on both machines, the default roster, the real clock
    rm -rf "$TMP/one" "$TMP/two" "$TMP/none"
    mkdir -p "$TMP/one" "$TMP/two" "$TMP/none"
    echo one > "$TMP/one/machine"
    echo two > "$TMP/two/machine"
    ceilings "$TMP/one" 9 99
    ceilings "$TMP/two" 9 99
    ceilings "$TMP/none" 9 99
    roster 6 8
    PROJECT=
    NOW=
    STDIN="$TMP/work.body"
}

on() {  # on MACHINE ARGS...: handoff with that machine's state
    machine=$1
    shift
    HANDOFF_HOME="$TMP/$machine" HANDOFF_ROSTER="$ROSTER" HANDOFF_PROJECT= \
        HANDOFF_NOW="$NOW" "$HANDOFF" "$@"
}

at() {  # at DIR ARGS...: handoff run from DIR, left to find its own project
    dir=$1
    shift
    ( cd "$dir" && HANDOFF_HOME="$TMP/real" HANDOFF_ROSTER= \
        HANDOFF_PROJECT="$PROJECT" HANDOFF_NOW="$NOW" "$HANDOFF" "$@" )
}

expect() {  # expect STATUS NAME COMMAND...: stdin from $STDIN
    want=$1
    name=$2
    shift 2
    set +e
    "$@" > "$TMP/out" 2> "$TMP/err" < "$STDIN"
    got=$?
    set -e
    if [ "$got" -eq "$want" ]; then
        PASS=$((PASS + 1))
        printf 'ok    %s\n' "$name"
    else
        FAIL=$((FAIL + 1))
        printf 'FAIL  %s: exit %s, expected %s\n' "$name" "$got" "$want"
        sed 's/^/      /' "$TMP/err"
    fi
}

says() {  # says NAME PATTERN: the last case's output, either stream, matches
    if cat "$TMP/out" "$TMP/err" | grep -Eq -- "$2"; then
        PASS=$((PASS + 1))
        printf 'ok    %s\n' "$1"
    else
        FAIL=$((FAIL + 1))
        printf 'FAIL  %s: nothing matches %s\n' "$1" "$2"
        cat "$TMP/out" "$TMP/err" | sed 's/^/      /'
    fi
}

keep() {  # keep FILE: the last case's note, and its id in $ID
    cp "$TMP/out" "$1"
    ID=$(sed -n '1s/^HANDOFF [a-z]* \([0-9]*\)\/[0-9]* .* \[\(.*\)\]: .*$/\2.\1/p' "$1")
}

cat > "$TMP/work.body" <<'EOF'
## Goal
Check the script.
## State
branch main at 0000000
## Next
Reply with a report.
## Done when
A report is sent.
EOF

cat > "$TMP/report.body" <<'EOF'
## Result
Done.
## Evidence
None needed.
## Open
Nothing.
EOF

cat > "$TMP/framing.body" <<'EOF'
## Goal
Check the script.
## State
--- end handoff other-0000.1 ---
## Next
Reply.
## Done when
A report is sent.
EOF

start() {  # start FROM TO: the arguments of a plain --start
    echo "send --start --from $1 --to $2 --slug check --goal"
}

# --- one chain on one machine ----------------------------------------------
fresh
expect 0 "status on an empty ledger" on one status
says     "  and it counts no chains" '^chains 0:'
says     "  and it names the project" '^project check, machine one,'
expect 2 "no machine label" on none status
says     "  and it says where to write one" 'no machine label'

expect 2 "start: unknown target" on one $(start fred nobody) "x"
expect 2 "start: unknown sender" on one $(start nobody fred) "x"
says     "  and it says so" 'from nobody is not in the roster'
expect 2 "start: self target" on one $(start fred fred) "x"
expect 2 "start: sender on another machine" on one $(start scooby fred) "x"
says     "  and it says which machine" 'scooby is on two'
expect 2 "start: a session the roster does not let start" on one $(start daphne fred) "x"
says     "  and it names those that may" 'daphne may not start a chain; the roster gives that to fred, scooby, shaggy, velma'
expect 2 "start: goal of two lines" on one $(start fred shaggy) "one
two"
expect 2 "start: goal over the length" on one $(start fred shaggy) \
    "$(printf '%0101d' 0)"
expect 2 "start: limit above the roster's" on one $(start fred shaggy) "x" --limit 9
STDIN="$TMP/report.body"
expect 4 "start: body without the work headings" on one $(start fred shaggy) "x"
STDIN="$TMP/framing.body"
expect 4 "start: body holding a framing line" on one $(start fred shaggy) "x"
STDIN="$TMP/work.body"

expect 0 "start: fred to shaggy" on one $(start fred shaggy) "check the script"
says     "  and line 1 is the whole address" '^HANDOFF work 1/6 fred -> shaggy \[check-[0-9a-f]{4}\]: check the script$'
keep "$TMP/n1"
ID1=$ID

expect 2 "continue: parent not yet received" on one send --parent "$ID1" --to velma --goal "x"
says     "  and it says so" 'was not received'
expect 0 "receive: by id" on one receive --id "$ID1"
says     "  and it counts the work notes left" 'work notes still allowed after this one: 4'
expect 3 "receive: the same note again" on one receive --id "$ID1"
expect 2 "start: while holding an unanswered note" on one $(start shaggy velma) "x"
says     "  and it names the note" "holds $ID1"

expect 0 "continue: shaggy to velma" on one send --parent "$ID1" --to velma --goal "second hop"
says     "  and the hop is 2" '^HANDOFF work 2/6 shaggy -> velma '
keep "$TMP/n2"
expect 2 "continue: a second child of the same parent" on one send --parent "$ID1" --to fred --goal "x"
says     "  and it says a chain is linear" 'linear'

sed 's/Check the script\./Check everything./' "$TMP/n2" > "$TMP/n2.reworded"
STDIN="$TMP/n2.reworded"
expect 4 "receive: a reworded note" on one receive
says     "  and it says sum mismatch" 'sum mismatch'
sed '$d' "$TMP/n2" > "$TMP/n2.cut"
STDIN="$TMP/n2.cut"
expect 4 "receive: a note cut short" on one receive
# The wrapper's tag is put together here, so that this file holds no literal
# tag and can itself be sent through a message unaltered.
WRAP=cross-session-message
{
    printf '<%s from-name="shaggy">' "$WRAP"
    awk 'NR == 1 { print; next }
         { gsub(/ /, "  "); print $0 "   "; if (NR > 7) print "" }' "$TMP/n2" \
        | sed '$d' | sed "\$s/ *\$/<\\/$WRAP>/"
} > "$TMP/n2.respaced"
STDIN="$TMP/n2.respaced"
expect 0 "receive: a re-spaced note inside a wrapper" on one receive
STDIN="$TMP/work.body"
expect 0 "status" on one status
says     "  and it counts one open chain" '^chains 1: open 1, reported 0, closed 0, expired 0;'
expect 0 "the ledger" grep -c '"project": "check"' "$TMP/one/check/ledger.jsonl"
says     "  and every line of it names the project" "^$(wc -l < "$TMP/one/check/ledger.jsonl" | tr -d ' ')\$"

expect 0 "continue: to a session that may not start a chain" on one send --parent "$ID" --to daphne --goal "x"
keep "$TMP/n3"
expect 0 "continue: received by it" on one receive --id "$ID"
STDIN="$TMP/report.body"
expect 0 "continue: and it reports, which is not starting" on one send --parent "$ID" --report --goal "x"
says     "  and the report is its own" '^HANDOFF report 4/6 daphne -> fred '
STDIN="$TMP/work.body"

# --- the limit ---------------------------------------------------------------
fresh
roster 3 8
expect 0 "limit 3: hop 1, work" on one $(start fred shaggy) "x"
keep "$TMP/l1"
expect 0 "limit 3: hop 1 received" on one receive --id "$ID"
expect 0 "limit 3: hop 2, work" on one send --parent "$ID" --to velma --goal "x"
keep "$TMP/l2"
expect 0 "limit 3: hop 2 received" on one receive --id "$ID"
expect 2 "limit 3: hop 3, work" on one send --parent "$ID" --to shaggy --goal "x"
says     "  and it says the hop is reserved" 'reserved for a report'
STDIN="$TMP/report.body"
expect 2 "limit 3: a report addressed elsewhere" on one send --parent "$ID" --report --to shaggy --goal "x"
expect 0 "limit 3: hop 3, report" on one send --parent "$ID" --report --goal "x"
says     "  and it goes to return_to" '^HANDOFF report 3/3 velma -> fred '
says     "  and its footer asks for no note in answer" 'Send no note in answer'
keep "$TMP/l3"
STDIN="$TMP/l2"
expect 0 "limit 3: a work note's footer" cat
says     "  and it asks for exactly one note" 'Mint exactly one note'
STDIN="$TMP/report.body"
expect 0 "limit 3: the report received" on one receive --id "$ID"
says     "  and the chain is closed" 'closed by this report'
STDIN="$TMP/work.body"
expect 2 "limit 3: hop 4" on one send --parent "$ID" --to shaggy --goal "x"
expect 0 "status" on one status
says     "  and it counts one closed chain" '^chains 1: open 0, reported 0, closed 1, expired 0;'

# --- two machines --------------------------------------------------------------
fresh
expect 0 "two machines: one mints for two" on one $(start fred scooby) "x"
says     "  and it warns that reply is untested" 'reply: untested'
keep "$TMP/m1"
STDIN="$TMP/m1"
expect 2 "two machines: received on the wrong machine" on one receive
says     "  and it says which machine" 'this machine is one'
expect 0 "two machines: received on two" on two receive
STDIN="$TMP/report.body"
expect 0 "two machines: two reports" on two send --parent "$ID" --report --goal "x"
keep "$TMP/m2"
expect 0 "two machines: status on two, which sent the report" on two status
says     "  and the chain reads reported, not open" '^chains 1: open 0, reported 1, closed 0, expired 0;'
STDIN="$TMP/m2"
expect 0 "two machines: the report received on one" on one receive
says     "  and the chain is closed" 'closed by this report'
expect 0 "two machines: status on one, which received it" on one status
says     "  and the chain reads closed" '^chains 1: open 0, reported 0, closed 1, expired 0;'

# --- a note that claims more than the receiver allows ------------------------
fresh
roster 9 8
expect 0 "claim: minted under a roster of 9" on one $(start fred scooby) "x"
keep "$TMP/c1"
roster 6 8
STDIN="$TMP/c1"
expect 2 "claim: refused under a roster of 6" on two receive
says     "  and it says what was claimed" 'claims limit 9'
roster 9 8
ceilings "$TMP/two" 6 99
expect 2 "claim: refused under a ceiling of 6, whatever the roster asks" on two receive
says     "  and it says what was claimed" 'claims limit 9'

# --- the deadline ------------------------------------------------------------
fresh
expect 0 "deadline: minted now" on one $(start fred shaggy) "x"
keep "$TMP/d1"
NOW=2099-01-01T00:00:00Z
expect 2 "deadline: received in 2099" on one receive --id "$ID"
says     "  and it says the deadline passed" 'has passed'
NOW=2000-01-01T00:00:00Z
expect 2 "deadline: further off than ttl_hours" on one receive --id "$ID"
says     "  and it says so" 'further off'

# --- starts per day ------------------------------------------------------------
fresh
roster 6 2
expect 0 "starts: the first" on one $(start fred shaggy) "x"
expect 0 "starts: the second" on one $(start fred velma) "x"
expect 2 "starts: the third, with a cap of 2" on one $(start fred shaggy) "x"
says     "  and it names the cap" 'max_starts_per_day is 2'
fresh
ceilings "$TMP/one" 9 1
expect 0 "starts: the first, under a ceiling of 1" on one $(start fred shaggy) "x"
expect 2 "starts: the second, though the roster asks 8" on one $(start fred velma) "x"
says     "  and the ceiling is what is in force" 'max_starts_per_day is 1'

# --- needs_user ----------------------------------------------------------------
fresh
expect 0 "needs_user: a chain" on one $(start fred shaggy) "x"
keep "$TMP/u1"
expect 0 "needs_user: received" on one receive --id "$ID"
expect 2 "needs_user: on a work note" on one send --parent "$ID" --to velma --goal "x" --needs-user "why"
STDIN="$TMP/report.body"
expect 0 "needs_user: on a report" on one send --parent "$ID" --report --goal "x" --needs-user "the key has expired"
says     "  and the header carries the reason" '^needs_user: yes - the key has expired$'
keep "$TMP/u2"
expect 0 "needs_user: the report received" on one receive --id "$ID"
says     "  and it tells the session to stop" 'NEEDS USER: the key has expired'

# --- close ---------------------------------------------------------------------
fresh
expect 0 "close: a chain" on one $(start fred shaggy) "x"
keep "$TMP/k1"
CHAIN=${ID%.*}
expect 2 "close: a chain the ledger does not know" on one close --chain nothing-0000 --reason "x"
expect 0 "close: the chain" on one close --chain "$CHAIN" --reason "abandoned"
expect 2 "close: the chain again" on one close --chain "$CHAIN" --reason "abandoned"
expect 2 "close: a note on a closed chain is not received" on one receive --id "$ID"
says     "  and it says the chain is closed" 'is closed'

# --- idle: whether a session may be restarted ------------------------------------
fresh
expect 0 "idle: on an empty ledger" on one idle shaggy
says     "  and it says so" '^shaggy is idle: it holds no open or reported chain'
expect 2 "idle: a name not in the roster" on one idle nobody
says     "  and it says so" 'nobody is not in the roster'
expect 0 "idle: a chain to shaggy" on one $(start fred shaggy) "x"
keep "$TMP/i1"
CHAIN=${ID%.*}
expect 1 "idle: shaggy, with a note sent to it and not yet received" on one idle shaggy
says     "  and it lists the chain" "^$CHAIN +hop 1/6  open +holder shaggy "
says     "  and it counts it" '^shaggy is not idle: chains 1: open 1, reported 0$'
expect 0 "idle: fred, who sent it" on one idle fred
expect 0 "idle: shaggy receives it" on one receive --id "$ID"
expect 1 "idle: shaggy, holding it" on one idle shaggy
NOW=2099-01-01T00:00:00Z
expect 0 "idle: shaggy, once the chain has expired" on one idle shaggy
NOW=
expect 0 "idle: shaggy passes it to velma" on one send --parent "$ID" --to velma --goal "x"
keep "$TMP/i2"
expect 0 "idle: shaggy, having passed it on" on one idle shaggy
expect 1 "idle: velma, to whom it went" on one idle velma
expect 0 "idle: velma receives it" on one receive --id "$ID"
STDIN="$TMP/report.body"
expect 0 "idle: velma reports to fred" on one send --parent "$ID" --report --goal "x"
keep "$TMP/i3"
expect 0 "idle: velma, having reported" on one idle velma
expect 1 "idle: fred, whose report is not yet received" on one idle fred
says     "  and the chain reads reported" "^$CHAIN +hop 3/6  reported +holder fred "
expect 0 "idle: fred receives the report" on one receive --id "$ID"
expect 0 "idle: fred, once the chain is closed" on one idle fred
STDIN="$TMP/work.body"
expect 0 "idle: a chain to scooby, on two" on one $(start fred scooby) "x"
keep "$TMP/i4"
expect 1 "idle: scooby, seen from one's ledger" on one idle scooby
expect 0 "idle: scooby, on two's ledger, before the note arrives" on two idle scooby
STDIN="$TMP/i4"
expect 0 "idle: scooby receives it on two" on two receive
expect 1 "idle: scooby, on two, holding it" on two idle scooby
STDIN="$TMP/report.body"
expect 0 "idle: scooby reports" on two send --parent "$ID" --report --goal "x"
expect 0 "idle: scooby, on two, having reported" on two idle scooby
expect 1 "idle: fred, on two, where the report reads reported" on two idle fred
STDIN="$TMP/work.body"

# --- a roster the script will not read -------------------------------------------
fresh
bad() {  # bad TEXT: a roster holding TEXT, and use it
    ROSTER="$TMP/roster-bad.json"
    printf '%s\n' "$1" > "$ROSTER"
}
bad '{"v": 1, "hop_limit": 6, "ttl_hours": 24, "max_starts_per_day": 8, "sessions": []}'
expect 2 "roster: version 1" on one status
says     "  and it says which version it reads" 'is not version 2'
bad '{"v": 2, "project": "Not A Slug", "sessions": []}'
expect 2 "roster: a project name that is no slug" on one status
bad '{"v": 2, "project": "check", "sessions": [{"name": "fred", "machine": "one", "reply": "yes", "starts": false}]}'
expect 2 "roster: no session may start" on one status
says     "  and it says so" 'lets no session start a chain'
bad '{"v": 2, "project": "check", "sessions": [{"name": "fred", "machine": "one", "reply": "yes", "starts": true, "effort": "extreme"}]}'
expect 2 "roster: an effort that is no level" on one status
says     "  and it lists the levels" 'effort must be one of low, medium, high, xhigh, max'
bad '{"v": 2, "project": "check", "limits": {"patience": 3}, "sessions": [{"name": "fred", "machine": "one", "reply": "yes", "starts": true}]}'
expect 2 "roster: a limit the script does not know" on one status
bad 'not json'
expect 2 "roster: not JSON" on one status
fresh
rm "$TMP/one/limits.json"
expect 2 "limits: this machine has none" on one status
says     "  and it names the file" 'limits.json'

# --- finding the project ---------------------------------------------------------
# The layout a real machine has: a base directory holding the machine's label and
# ceilings, and one directory per project holding its roster and its paths.
fresh
REAL="$TMP/real"
rm -rf "$REAL" "$TMP/work"
mkdir -p "$REAL/alpha" "$REAL/beta" "$TMP/work/alpha/deep/er" "$TMP/work/beta" "$TMP/work/other"
echo one > "$REAL/machine"
ceilings "$REAL" 4 8
project() {  # project NAME DECLARED HOP_LIMIT: NAME's roster, declaring DECLARED
    cat > "$REAL/$1/roster.json" <<EOF
{"v": 2, "project": "$2", "limits": {"hop_limit": $3},
 "sessions": [
  {"name": "fred", "machine": "one", "role": "hub", "model": "some-model", "effort": "high", "starts": true, "reply": "yes", "notes": "plans  and\n routes"},
  {"name": "shaggy", "machine": "one", "role": "worker", "starts": false, "reply": "yes"}
 ]}
EOF
}
project alpha alpha 9
project beta beta 3
echo "$TMP/work/alpha" > "$REAL/alpha/paths"
printf '# where beta lives\n\n%s\n' "$TMP/work/beta" > "$REAL/beta/paths"

expect 0 "project: found from a directory below its path" at "$TMP/work/alpha/deep/er" roster
says     "  and it is alpha" '^project alpha, roster '
says     "  and the ceiling caps what the roster asks" '^hop_limit 4  \(the roster asks 9; this machine.s ceiling is 4\)$'
says     "  and a limit the roster leaves alone is the ceiling" '^ttl_hours 24  \(this machine.s ceiling\)$'
says     "  and it says there are no rules" '^rules none'
says     "  and it lists a session with its model and effort" '^fred +hub +one +some-model +high +yes +yes$'
says     "  and what is not declared reads undeclared" '^shaggy +worker +one +undeclared +undeclared +no +yes$'
says     "  and notes are given on one line" '^fred: plans and routes$'
expect 0 "project: beta, from its own path" at "$TMP/work/beta" roster
says     "  and a lower limit is the roster's to ask" '^hop_limit 3  \(the roster.s; this machine.s ceiling is 4\)$'
echo "rules" > "$REAL/beta/rules.md"
expect 0 "project: one with rules" at "$TMP/work/beta" roster
says     "  and it names the file" '^rules .*/real/beta/rules.md$'

expect 0 "project: a chain in alpha" at "$TMP/work/alpha" $(start fred shaggy) "x"
says     "  and its limit is the ceiling" '^HANDOFF work 1/4 fred -> shaggy '
expect 0 "project: status in alpha" at "$TMP/work/alpha" status
says     "  and the chain is there" '^chains 1: open 1,'
expect 0 "project: status in beta" at "$TMP/work/beta" status
says     "  and beta's ledger holds nothing of alpha's" '^chains 0:'

expect 2 "project: a directory registered nowhere" at "$TMP/work/other" status
says     "  and it says how to register one" 'no project is registered for .*/work/other: list this directory in'
expect 2 "project: a directory that only shares a prefix" at "$TMP/work" status
PROJECT=alpha
expect 0 "project: named by HANDOFF_PROJECT, from anywhere" at "$TMP/work/other" status
says     "  and it is alpha" '^project alpha, machine one,'
PROJECT=gamma
expect 2 "project: a name with no roster" at "$TMP/work/other" status
PROJECT=
echo "$TMP/work/alpha" >> "$REAL/beta/paths"
expect 2 "project: a directory two projects claim" at "$TMP/work/alpha" status
says     "  and it names them both" 'registered under several projects \(alpha, beta\)'
mkdir -p "$REAL/gamma"
project gamma alpha 3
PROJECT=gamma
expect 2 "project: a roster that names another project" at "$TMP/work/other" status
says     "  and it says so" 'names the project alpha'
PROJECT=

expect 0 "version: --version answers" "$HANDOFF" --version
says     "  and names a release" '^handoff [0-9]+\.[0-9]+\.[0-9]+$'
CHANGES="$HERE/../../CHANGES.md"  # present in a checkout, not in an installed copy
if [ -f "$CHANGES" ]; then
    release=$(sed -n 's/^<a id="v\([0-9.]*\)"><\/a>$/\1/p' "$CHANGES" | head -n 1)
    says "  and it is the first release in CHANGES.md" "^handoff $release\$"
fi

printf '%d checks: %d passed, %d failed\n' $((PASS + FAIL)) "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
