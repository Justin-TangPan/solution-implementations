#!/usr/bin/env python3
"""Compatibility wrapper for uploading a Supabase test candidate.

OBS credentials and bucket configuration are read exclusively by
``scripts.obs.upload`` from the OBS_* environment variables.
"""

import subprocess
import sys


def main() -> int:
    command = [
        sys.executable,
        "-m",
        "scripts.obs.upload",
        "--practice",
        "supabase",
        *sys.argv[1:],
    ]
    return subprocess.call(command)


if __name__ == "__main__":
    raise SystemExit(main())
