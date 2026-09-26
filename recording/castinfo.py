#!/usr/bin/env python3
"""Print raw and idle-limited duration of asciicast v2 files."""
import json, sys
for path in sys.argv[1:]:
    with open(path) as f:
        header = json.loads(f.readline())
        limit = header.get("idle_time_limit") or float("inf")
        prev = eff = 0.0
        n = 0
        for line in f:
            t = json.loads(line)[0]
            eff += min(t - prev, limit)
            prev = t
            n += 1
    print(f"{path}: {n} events, raw {prev:.1f}s, played {eff:.1f}s (idle limit {header.get('idle_time_limit')})")
