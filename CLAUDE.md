# xl-std notes for Claude

This file is the working note for this repository. It starts nearly empty and grows with the
decisions that are not visible in the code.

## Comment tags

The tags a doc comment may carry are defined in `STD-TAGS.md`, with the rule and an example for
each one. Read it before writing a tag.

- A tag is written only where it is true and useful. A decorative tag is an error.
- One tag per line; a continuation line repeats the tag.
- `scripts/tags.sh check` refuses a broken tag, `scripts/tags.sh sync` updates the collected view
  in `STD-TAGS.md`, and the pre-commit hook runs both. `./scripts/install-hooks.sh` once per
  clone.
- The compiler vocabulary (`@grammar`, `@layout`, `@abi`, `@invariant`) is never used here.
