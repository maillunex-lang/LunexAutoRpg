#!/usr/bin/env python3
"""Sample CPU (percent of one core) and RSS for one Linux server process."""

import argparse
import json
import os
from pathlib import Path
import time


def read_sample(process):
    fields = (process / "stat").read_text().rsplit(")", 1)[1].split()
    cpu_ticks = int(fields[11]) + int(fields[12])
    rss = next(
        int(line.split()[1])
        for line in (process / "status").read_text().splitlines()
        if line.startswith("VmRSS:")
    )
    return cpu_ticks, rss / 1024, fields[19]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("pid", type=int)
    parser.add_argument("--seconds", type=int, default=15)
    args = parser.parse_args()
    if args.pid <= 0 or args.seconds <= 0:
        parser.error("PID and sample duration must be positive")

    process = Path("/proc") / str(args.pid)
    initial_ticks, rss, start_time = read_sample(process)
    samples = [rss]
    started = time.monotonic()
    final_ticks = initial_ticks
    for _ in range(args.seconds):
        time.sleep(1)
        final_ticks, rss, current_start_time = read_sample(process)
        if current_start_time != start_time:
            raise RuntimeError("The server process restarted during the sample")
        samples.append(rss)

    elapsed = time.monotonic() - started
    cpu_percent = (final_ticks - initial_ticks) / os.sysconf("SC_CLK_TCK") / elapsed * 100
    print(json.dumps({
        "seconds": round(elapsed, 2),
        "cpu_one_core_percent": round(cpu_percent, 2),
        "rss_mean_mib": round(sum(samples) / len(samples), 2),
        "rss_max_mib": round(max(samples), 2),
    }))


if __name__ == "__main__":
    main()
