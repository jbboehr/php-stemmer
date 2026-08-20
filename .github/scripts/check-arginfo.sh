#!/usr/bin/env bash

set -euo pipefail

readonly stub_file="stemmer.stub.php"
readonly arginfo_file="stemmer_arginfo.h"

actual_hash="$(sed 's/\r$//' "$stub_file" | sha1sum | cut -d ' ' -f 1)"
expected_hash="$(sed -n 's/^ \* Stub hash: \([0-9a-f]\{40\}\) \*\/$/\1/p' "$arginfo_file")"

if [[ -z "$expected_hash" ]]; then
    echo "Unable to read the stub hash from $arginfo_file" >&2
    exit 1
fi

if [[ "$actual_hash" != "$expected_hash" ]]; then
    echo "$arginfo_file is out of date; regenerate it from $stub_file" >&2
    exit 1
fi
