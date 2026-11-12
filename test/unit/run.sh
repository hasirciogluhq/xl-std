#!/bin/bash
# Unit suites of the standard library: every `*.test.xl` here is a program that ends in `suiteRun` (std/testing); a non-zero exit
# status fails the file. Each one is built with `xlc` against this repository's stdlib and run on the host. The files are
# independent, so they build and run in parallel (batches of one job per CPU); the report keeps the file order.
#   test/unit/run.sh [path/to/xlc] [name-regex]        (compiler default: $XLC, else `xlc` on PATH)
set -u
here=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$here/../.." && pwd)
xlc=${1:-${XLC:-xlc}}
filter=${2:-}
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
jobs=$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)

# One suite: `ok`, `build` or `exit N` into $work/<name>.status, its compiler or program output into $work/<name>.out.
one() {
  local name=$1
  if ! "$xlc" "$here/$name.test.xl" -M "std=$root" --import std -DfeatureDefaultAllocator=true -o "$work/$name" >"$work/$name.out" 2>&1; then
    echo build >"$work/$name.status"; return
  fi
  "$work/$name" >"$work/$name.out" 2>&1
  local code=$?
  if [ "$code" = 0 ]; then echo ok; else echo "exit $code"; fi >"$work/$name.status"
}

names=()
for src in "$here"/*.test.xl; do
  name=$(basename "$src" .test.xl)
  if [ -n "$filter" ] && ! [[ $name =~ $filter ]]; then continue; fi
  names+=("$name")
  one "$name" &
  if [ $((${#names[@]} % jobs)) = 0 ]; then wait; fi
done
wait

pass=0; fail=0
for name in ${names[@]+"${names[@]}"}; do
  status=$(cat "$work/$name.status" 2>/dev/null || echo "no result")
  if [ "$status" = ok ]; then
    echo "ok   [unit/$name]"; pass=$((pass + 1))
  else
    echo "FAIL [unit/$name] $status"; cat "$work/$name.out"; fail=$((fail + 1))
  fi
done

echo "unit: $pass passed, $fail failed"
[ "$fail" = 0 ]
