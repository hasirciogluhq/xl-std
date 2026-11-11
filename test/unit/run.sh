#!/bin/bash
# Unit suites of the standard library: every `*.test.xl` here is a program that ends in `suiteRun` (std/testing); a non-zero exit
# status fails the file. Each one is built with `xlc` against this repository's stdlib and run on the host.
#   test/unit/run.sh [path/to/xlc] [name-regex]        (compiler default: $XLC, else `xlc` on PATH)
set -u
here=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$here/../.." && pwd)
xlc=${1:-${XLC:-xlc}}
filter=${2:-}
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
pass=0; fail=0

for src in "$here"/*.test.xl; do
  name=$(basename "$src" .test.xl)
  if [ -n "$filter" ] && ! [[ $name =~ $filter ]]; then continue; fi
  if ! "$xlc" "$src" -M "std=$root" --import std -DfeatureDefaultAllocator=true -o "$work/$name" 2>"$work/$name.err"; then
    echo "FAIL [unit/$name] build"; cat "$work/$name.err"; fail=$((fail + 1)); continue
  fi
  out=$("$work/$name" 2>&1); code=$?
  if [ "$code" = 0 ]; then
    echo "ok   [unit/$name]"; pass=$((pass + 1))
  else
    echo "FAIL [unit/$name] exit $code"; echo "$out"; fail=$((fail + 1))
  fi
done

echo "unit: $pass passed, $fail failed"
[ "$fail" = 0 ]
