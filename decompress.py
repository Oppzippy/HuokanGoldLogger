#!/usr/bin/env python3

import sys
import re
import base64
import zlib
import json


def read_log_file(file_path: str):
    with open(file_path, "r") as f:
        log = []
        readingLog = False
        for line in f:
            line = line.rstrip("\n")
            if line == "HuokanGoldLog = {":
                readingLog = True
            elif readingLog:
                if line == "}":
                    break
                string = read_log_file_line(line)
                log.append(string)
        if not readingLog:
            raise Exception("File didn't contain a log.")
        return log


def read_log_file_line(line: str) -> str:
    match = re.match(r'^\t"(.*)", -- \[\d+\]$', line)
    if match is None:
        raise Exception(f"Error parsing line: {line}")
    return match.group(1)


def parse_log(log: list) -> list:
    events = []
    for entry_b64 in log:
        entry_compressed = base64.b64decode(entry_b64)
        entry_json = zlib.decompress(entry_compressed, -15)  # no deflate headers
        entry = json.loads(entry_json)
        if isinstance(entry, list):
            events.extend(entry)
        else:
            events.append(entry)
    return events


if len(sys.argv) == 1:
    print("Usage: ./decompress.py HuokanGoldLogger.lua")
else:
    log = read_log_file(sys.argv[1])
    print(json.dumps(parse_log(log)))
