#!/usr/bin/env python3
"""Choose next automatic release version; docs-only commits never call this."""
import re
import sys

if len(sys.argv) != 2:
    raise SystemExit("Usage: next_version.py MAJOR.MINOR.PATCH < previous-tags")
pattern = re.compile(r"^v?(\d+)\.(\d+)\.(\d+)$")


def parse(text: str) -> tuple[int, int, int] | None:
    match = pattern.fullmatch(text.strip())
    return tuple(map(int, match.groups())) if match else None


base = parse(sys.argv[1])
if base is None:
    raise SystemExit("Invalid base version")
previous = [parsed for line in sys.stdin if (parsed := parse(line)) is not None]
if previous:
    last = max(previous)
    proposed = (last[0], last[1], last[2] + 1)
    version = max(base, proposed)
else:
    version = base
print("v" + ".".join(map(str, version)))
