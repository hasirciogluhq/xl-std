# Standard library comment tags

This file defines the tags that may appear as a doc comment (`///`) above a declaration in the
standard library source (`xl-std/`). Each tag is one grep handle, so a reader or a tool finds
every place a fact is recorded without reading the code.

The standard library is a separate repository from the compiler, and its tags answer different
questions. The compiler tags record what the language is: its grammar, its ABI, its layout. The
standard library tags record what the library promises its callers and what it needs from the
operating system: the API contract, the ownership of memory, the system error, the platform
difference, the protocol reference.

Rule: a tag is written only where it is true and useful. A tag that is only decoration is an
error. When the code under a tag changes, the tag changes in the same edit.

Rule: one tag per line. The tag word starts the line, and a line that continues a tag repeats it.
A long tag is wrapped with the tag on every line, never with a bare `///` continuation, so grep
returns the whole tag and nothing is lost:

    /// @contract `pop` returns the last element; on an empty `Vec` it panics, it never returns
    /// @contract a default value.

This makes every tag collectable with one grep, with no state and no tool:

    grep -rn "@contract" .
    grep -rn "@ownership" .
    grep -rn "@errno" .
    grep -rn "@platform" .
    grep -rn "@spec" .
    grep -rn "@cost" .
    grep -rn "@todo" .
    grep -rn "@safety" .
    grep -rn "@init" .

The tag word is always lower case ASCII and always followed by one space, so `@todo` and
`@todos` are different tags and a tag is never a prefix of another by accident.

## The tag set

Nine tags, each one a question a reader of this library asks and the code alone does not answer.

| tag | answers |
| --- | --- |
| `@contract` | what a public function promises and what the caller must hold true |
| `@ownership` | who owns a value or a buffer, who frees it, when it is borrowed |
| `@errno` | which OS error appears, with the number and the meaning |
| `@platform` | a difference between Linux, macOS and Windows and how it is handled |
| `@spec` | the RFC, man page or vendor document a rule implements |
| `@cost` | an allocation, a copy or a quadratic loop at a hot point |
| `@todo` | a known gap, with the reason it is acceptable now |
| `@safety` | code that is only sound under a precondition nobody checks |
| `@init` | a one time setup that a public creator depends on |

## @contract

What a public function promises: its result on each input, its side effects, and what the caller
must guarantee before the call. Goes only on an exported declaration, at the point where the
signature is not enough.

    /// @contract `get` returns a pointer to element `i`, or `nil` when `i >= length`; the
    /// @contract pointer stays valid until the next call that grows the `Vec`.
    export fn get(self, i: usize) -> *T {

Rule: the contract states behavior, not implementation. A contract that says how the code works
is a plain comment and belongs in the doc text above it.

## @ownership

Who owns a heap value, who frees it, and who must not. The standard library hands out pointers
and borrows buffers constantly, and the compiler does not check either, so the rule has to be
written down at the boundary.

    /// @ownership the returned `String` is freshly allocated from `currentAllocator` and the
    /// @ownership caller frees it; the input `str` is borrowed and never freed here.

Used where a value crosses a function boundary with a different ownership than the reader would
guess from the type alone.

## @errno

The operating system error that a call produces and what it means for this function. Used at a
syscall, an OS library call or an error check, with the number of each target and the behavior
the code expects, never a guess.

    /// @errno `read` returns `-EINTR` (4 on Linux, 4 on macOS) when a signal arrives; the loop
    /// @errno retries it rather than reporting a short read.

Only Linux, macOS and Windows values are recorded, each with its source.

## @platform

A difference that is real between Linux, macOS and Windows, and what the code does about it. The
whole library is one source tree with `#if os` branches, so every branch needs a reason that a
reader on another platform can check.

    /// @platform macOS returns `ENOTCONN` where Linux returns `EPIPE` for a write to a closed
    /// @platform pipe; both map to `IoError.closed` so the caller sees one error.

Not for a comment that says which line is which OS; that is what `#if` says already.

## @spec

A citation for a rule the code implements: an RFC, a man page, a vendor document, a protocol
specification. The URL, the section, and the one sentence being implemented.

    /// @spec https://www.rfc-editor.org/rfc/rfc6265#section-5.2 for the cookie date parser.

## @cost

A measured or clearly reasoned cost at a hot point: an allocation per call, a copy, a quadratic
loop. Says the size and what would fix it, so it is visible without a profiler.

    /// @cost one `String` allocation per element in `join`: acceptable because a join is
    /// @cost called once per message; a builder taking an out buffer would remove it.

## @todo

A known gap with a reason and a boundary, not a wish. Names what is missing, why it is acceptable
now, and what would make it wrong later. A gap that a user can meet also goes into
`xlang-docs/known-limitations.md` in the documentation repository.

    /// @todo only TLS 1.3 session tickets are resumed; a TLS 1.2 server falls back to a full
    /// @todo handshake, which is correct but slower, so this is a cost and not an error.

## @safety

A place where the code is sound only because of a precondition that nothing checks: a length
that must match a buffer, an index that must be in range, a pointer that must be aligned. Says
the precondition, and who guarantees it.

    /// @safety `slot(i)` computes the address without a bounds check; every caller must test
    /// @safety `i < len`, and `get` is the only public function that calls it unchecked.

The compiler's `--safety=checked` build checks indexing and array bounds; it checks nothing
about a raw pointer, so this tag is the record for the rest.

## @init

A one time setup that a public creator depends on, and the state it leaves behind. The library
hides per platform setup behind one function per area, and this tag is where that is recorded.

    /// @init `socketsUp` calls `WSAStartup` once per process and is called by every function
    /// @init that creates a socket; calling it twice is free.
    fn socketsUp() -> bool {

## Adding a tag

A new tag is added to this file first, with its rule, its example and the reason it is a tag and
not a plain comment. Then the sites are tagged in the same change. Two tags never mean the same
thing.

A tag from the compiler set (`@grammar`, `@layout`, `@abi` and the rest) is not used here: it
answers a question about the language, and the standard library is written in the language, not
about it. A fact that belongs to the compiler is recorded in the compiler repository.

## Collected view

Everything between the two markers is generated by `scripts/tags.sh sync` from the source, so it
is never edited by hand. The pre-commit hook runs the sync and stages this file when it changed,
which keeps the view in the same commit as the tag it came from.

<!-- BEGIN COLLECTED TAGS -->
<!-- written by scripts/tags.sh sync; every line below is a tag found in the .xl
     sources, grouped by tag and then by file. Do not edit inside the markers. -->

Total: 0 tag lines.
<!-- END COLLECTED TAGS -->
