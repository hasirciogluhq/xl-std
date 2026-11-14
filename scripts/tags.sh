#!/bin/sh
# Generator: collects the standard library comment tags into one view, and checks that every tag
# is well-formed. This is the tool behind STD-TAGS.md; it needs nothing but grep and awk.
#
#   scripts/tags.sh list [tag]    print every tag line, grouped by tag then file, as grep finds it
#   scripts/tags.sh check         validate the tags and exit non-zero when one is malformed
#   scripts/tags.sh sync          rewrite the collected view inside STD-TAGS.md, when it differs
#
# `sync` owns exactly one block of STD-TAGS.md, between the BEGIN and END marker lines.
# Everything outside the markers is written by hand and is never touched. The block is always
# derived from the source, so it is reproduced byte for byte on a clean tree.
#
# `check` enforces the rules STD-TAGS.md states:
#   - a tag starts the comment and is lower case ASCII, so `grep -rn "@tag" .` finds all of it,
#   - a line that continues a tag repeats the tag instead of continuing with a bare `///`,
#   - only known tags are used,
#   - a compiler tag from the xlc repository is never used here,
#   - a tag is not left without a following declaration.
#
# Exit codes: 0 clean, 1 rule violation, 2 bad usage.
set -eu

repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
# The library sources. xlang.toml names `root = "src"`, so everything under src/ is the package and
# nothing else is scanned: no exclusion list can drift out of date.
root=$repo/src
# The tag vocabulary, exactly the set STD-TAGS.md defines.
known="contract ownership errno platform spec cost todo safety init"
# The xlc vocabulary. A compiler question is answered in the compiler, never here.
foreign="grammar layout abi invariant"

usage() {
    echo "usage: scripts/tags.sh list [tag] | check | sync" >&2
    exit 2
}

# Every scanned source: the library itself, one .xl file per area or sub area. The tests and the docs
# live outside root and never carry tags.
sources() {
    cd "$root" && find . -name '*.xl' -not -path './.*' | sort
}

# The files grep scans. Same set as sources(), used by the rules that read the source text.
scan() {
    cd "$root" && grep -rn "$@" --include='*.xl' \
        --exclude-dir=test --exclude-dir=archive --exclude-dir=.\* . 2>/dev/null || true
}

cmd_list() {
    want=${1:-}
    for tag in $known; do
        if [ -n "$want" ] && [ "$want" != "$tag" ]; then
            continue
        fi
        hits=$(cd "$root" && grep -rn "@$tag " --include='*.xl' --exclude-dir=test \
        --exclude-dir=archive . 2>/dev/null || true)
        if [ -n "$hits" ]; then
            echo "== @$tag"
            echo "$hits"
            echo
        fi
    done
}

cmd_check() {
    status=0

    # 1. An unknown tag: a comment that starts with `@` and a word that is not in the vocabulary.
    unknown=$(cd "$root" && grep -rnE '^[[:space:]]*///[[:space:]]+@[a-z]+' --include='*.xl' \
        --exclude-dir=test --exclude-dir=archive . 2>/dev/null |
        sed -E 's/.*\/\/\/[[:space:]]+@([a-z]+).*/\1/' | sort -u)
    for word in $unknown; do
        case " $known " in
        *" $word "*) ;;
        *)
            case " $foreign " in
            *" $word "*)
                echo "STD-TAGS.md: @$word is a compiler tag; it belongs in the xlc repository"
                ;;
            *)
                echo "STD-TAGS.md: unknown tag @$word"
                ;;
            esac
            (cd "$root" && grep -rnE "^[[:space:]]*///[[:space:]]+@$word" --include='*.xl' \
                --exclude-dir=test --exclude-dir=archive . 2>/dev/null | sed 's/^/  /') || true
            status=1
            ;;
        esac
    done

    # 2. A continuation line: a `///` doc comment directly after a tag line that repeats no tag.
    #    That is the line the grep would lose.
    orphans=$(cd "$root" && awk '
        FNR == 1 { prev_tag = 0 }
        {
            is_doc = ($0 ~ /^[[:space:]]*\/\/\//)
            has_tag = ($0 ~ /^[[:space:]]*\/\/\/[[:space:]]+@[a-z]+/)
            if (is_doc && prev_tag && !has_tag) {
                print FILENAME ":" FNR ":" $0
            }
            prev_tag = has_tag ? 1 : 0
            if (!is_doc) prev_tag = 0
        }
    ' $(sources))
    if [ -n "$orphans" ]; then
        echo "STD-TAGS.md: a tag continuation line must repeat its tag:"
        echo "$orphans" | sed 's/^/  /'
        status=1
    fi

    # 3. A tag with nothing under it: the next line must not be blank or another non-doc line.
    dangling=$(cd "$root" && awk '
        FNR == 1 { pending = 0 }
        {
            if (pending) {
                is_doc = ($0 ~ /^[[:space:]]*\/\/\//)
                if ($0 ~ /^[[:space:]]*$/) {
                    print FILENAME ":" FNR - 1 ": tag is followed by a blank line"
                    pending = 0
                } else if (!is_doc) {
                    pending = 0
                }
            }
            if ($0 ~ /^[[:space:]]*\/\/\/[[:space:]]+@[a-z]+/) pending = 1
        }
    ' $(sources))
    if [ -n "$dangling" ]; then
        echo "STD-TAGS.md: a tag must sit right above its declaration:"
        echo "$dangling" | sed 's/^/  /'
        status=1
    fi

    if [ "$status" -eq 0 ]; then
        contract=$(cd "$root" && grep -rc "@contract" --include='*.xl' --exclude-dir=test \
            --exclude-dir=archive . 2>/dev/null |
            awk -F: '{s += $2} END {print s + 0}')
        echo "tags ok: $(echo $known | wc -w | tr -d ' ') tags, $contract @contract lines, grep finds all of them"
    fi
    return "$status"
}

# The collected view is rewritten into the marked block of STD-TAGS.md. It is built from the
# source alone and carries no timestamp, so a clean tree reproduces it byte for byte.
cmd_sync() {
    doc=$repo/STD-TAGS.md
    if [ ! -f "$doc" ]; then
        echo "STD-TAGS.md: $doc is missing" >&2
        return 1
    fi
    begin='<!-- BEGIN COLLECTED TAGS -->'
    end='<!-- END COLLECTED TAGS -->'
    if ! grep -qF "$begin" "$doc" || ! grep -qF "$end" "$doc"; then
        echo "STD-TAGS.md: the '$begin' / '$end' markers are missing" >&2
        return 1
    fi

    tmp=$(mktemp)
    block=$(mktemp)
    trap 'rm -f "$tmp" "$block"' EXIT

    {
        echo "$begin"
        echo "<!-- written by scripts/tags.sh sync; every line below is a tag found in the .xl"
        echo "     sources, grouped by tag and then by file. Do not edit inside the markers. -->"
        echo
        total=0
        for tag in $known; do
            # `grep -r` walks directories in filesystem order (APFS and ext4 differ), so the hits
            # are sorted by file, then line number, for one view on every host.
            hits=$(cd "$root" && grep -rn "@$tag " --include='*.xl' --exclude-dir=test \
        --exclude-dir=archive . 2>/dev/null | LC_ALL=C sort -t: -k1,1 -k2,2n || true)
            [ -n "$hits" ] || continue
            count=$(echo "$hits" | wc -l | tr -d ' ')
            total=$((total + count))
            echo "### @$tag ($count)"
            echo
            echo '```'
            echo "$hits"
            echo '```'
            echo
        done
        echo "Total: $total tag lines."
        echo "$end"
    } >"$block"

    # Replace only what sits between the markers; the rest of the document is hand written.
    awk -v begin="$begin" -v end="$end" -v block="$block" '
        $0 == begin { while ((getline line < block) > 0) print line; skip = 1; next }
        $0 == end   { skip = 0; next }
        !skip       { print }
    ' "$doc" >"$tmp"

    if cmp -s "$tmp" "$doc"; then
        echo "tags sync: STD-TAGS.md is up to date"
        return 0
    fi
    cat "$tmp" >"$doc"
    echo "tags sync: STD-TAGS.md updated"
    return 0
}

case "${1:-}" in
list) shift; cmd_list "${1:-}" ;;
check) cmd_check ;;
sync) cmd_sync ;;
*) usage ;;
esac
