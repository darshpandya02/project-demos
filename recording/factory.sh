#!/usr/bin/env bash
# Session: BSDS PA3 primary-backup robot factory.
# Run from an empty working directory; the source is cloned from GitHub.
set -u
source "$(dirname "$0")/lib.sh"

pkill -f './server 1200' 2>/dev/null
rm -rf BSDS
clear

PROMPT_DIR="work"
note "fresh clone, then build PA3 (primary-backup robot factory) from source with clang++"
run 'git clone -q https://github.com/darshpandya02/BSDS && cd BSDS/PA3/factory_src'
PROMPT_DIR="factory_src"
run 'make CXX=clang++'

note "usage: server [port] [unique ID] [# peers] (repeat [ID] [IP] [port])"
note "three factories, each told about the other two; logs go to files"
run './server 12000 0 2 1 127.0.0.1 12001 2 127.0.0.1 12002 > f0.log 2>&1 &'
run './server 12001 1 2 0 127.0.0.1 12000 2 127.0.0.1 12002 > f1.log 2>&1 &'
run './server 12002 2 2 0 127.0.0.1 12000 1 127.0.0.1 12001 > f2.log 2>&1 & disown -a; sleep 0.5'
run 'lsof -nP -iTCP -sTCP:LISTEN | grep -E "COMMAND|server"'

note "usage: client [ip] [port] [# customers] [# orders] [request type]"
note "type 1 = robot orders (writes). The factory that receives orders becomes the primary"
note "and replicates every order to the backups before it ships the robot."
note "latencies are in microseconds, throughput in requests per second"
run './client 127.0.0.1 12000 8 2000 1'
note "type 2 = customer record reads (8 customers x 2000 reads; tail keeps only the stats line)"
run './client 127.0.0.1 12000 8 2000 2 | tail -n 1'
note "type 3 = dump customer records. Asking backup 12001 shows the replicated copy"
note "(customer id, last order number). Backups apply an entry once the next message commits it."
run './client 127.0.0.1 12001 1 7 3'

note "kill backup 12002 while the primary keeps taking orders"
run 'kill -9 $(lsof -t -iTCP:12002 -sTCP:LISTEN)'
run './client 127.0.0.1 12000 4 500 1'
note "restart it empty: on the next order the primary reconnects and replays its committed log"
run './server 12002 2 2 0 127.0.0.1 12000 1 127.0.0.1 12001 > f2.log 2>&1 & disown; sleep 0.5'
run './client 127.0.0.1 12000 1 3 1'
note "(the large max latency is the first order waiting while the primary replays its log to 12002)"
run './client 127.0.0.1 12002 1 7 3'

note "now kill the primary 12000 and send orders to backup 12001 instead"
run 'kill -9 $(lsof -t -iTCP:12000 -sTCP:LISTEN)'
run './client 127.0.0.1 12001 4 500 1'
note "12001 took over as primary and replicates to 12002 (12000 is unreachable and skipped)"
run './client 127.0.0.1 12001 1 7 3'
run './client 127.0.0.1 12002 1 7 3'
run 'pkill -f "./server 1200"'
sleep 2
