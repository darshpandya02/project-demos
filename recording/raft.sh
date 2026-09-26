#!/usr/bin/env bash
# Session: 5-node raft-cluster-monitor cluster, leader failover, fault injection.
# Run from the root of a raft-cluster-monitor checkout.
set -u
source "$(dirname "$0")/lib.sh"
PROMPT_DIR="raft-cluster-monitor"

pkill -f 'build/raftd' 2>/dev/null
rm -rf .run/demo
mkdir -p .run/demo
clear

note "build from source (C++20, Apple clang, no dependencies beyond libc++ and POSIX sockets)"
run 'make clean >/dev/null && make -j8'
run 'build/unit_tests'

note "boot a 5-node cluster: every node is its own raftd process, talking TCP"
run 'export RAFT_CLUSTER=127.0.0.1:7200,127.0.0.1:7201,127.0.0.1:7202,127.0.0.1:7203,127.0.0.1:7204'
run 'for i in 0 1 2 3 4; do build/raftd --id $i --peers $RAFT_CLUSTER --data .run/demo/n$i 2>.run/demo/n$i.log & done; disown -a; sleep 1'
run 'build/raftctl leader'

note "writes and reads go through the replicated log"
run 'build/raftctl put region us-east'
run 'build/raftctl get region'
run 'build/raftctl report web-1 healthy 0.42'
run 'build/raftctl report db-1 degraded 3.10'
run 'build/raftctl health'
run 'build/raftctl status'

note "SIGKILL the current leader"
run 'LEADER=$(build/raftctl leader | awk "/^leader:/ {print \$2}"); echo "leader is $LEADER"'
run 'kill -9 $(lsof -t -iTCP:${LEADER##*:} -sTCP:LISTEN); echo "killed at $(python3 -c "import time; print(int(time.time()*1000))") ms"'
run 'sleep 1; build/raftctl leader'
run 'grep -h -E "ELECTION_START|BECAME_LEADER" .run/demo/n*.log | sort | tail -n 6'

note "the surviving 4-node majority keeps accepting writes, and old data is still there"
run 'build/raftctl put region us-west'
run 'build/raftctl get region'
run 'build/raftctl health'
run 'build/raftctl status'

note "restart the killed node: it reloads its log from disk and catches up"
run 'ID=$(( ${LEADER##*:} - 7200 )); build/raftd --id $ID --peers $RAFT_CLUSTER --data .run/demo/n$ID 2>>.run/demo/n$ID.log & disown; sleep 1.5'
run 'build/raftctl status'
run 'pkill -f "build/raftd --id"; sleep 0.5'

note "fault injection: 5 nodes, a client writing throughout, leader kill/pause, follower pause, minority kill"
run 'python3 tests/fault_injection.py --bin build --nodes 5 --runs 1 --rounds 2 --base-port 7300 --workdir .run/demo/fault'
sleep 2
