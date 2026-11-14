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

### @contract (41)

```
./collections/arc.xl:19:/// @contract `inner` is non-nil and `inner.strong` counts the live `Arc` handles on it.
./collections/binaryheap.xl:9:/// @contract for every `i`, `cmp(parent(i), i) >= 0`, so the greatest element is at index `0`.
./collections/box.xl:6:/// @contract `ptr` points to one live `T` (or the `Box` was moved out and is never used again).
./collections/btreemap.xl:16:/// @contract `entries` is sorted by `cmp` and holds no two keys that compare `0`.
./collections/deque.xl:11:/// @contract `len` elements live in the `cap` slots of `slots` starting at `head`, wrapping once.
./collections/deque.xl:12:/// @contract `cap` is a power of two or `0`, so the wrap is a mask.
./collections/hash.xl:88:/// @contract every byte of `data` and both key words affect the tag; the same input and key give
./collections/hash.xl:89:/// @contract the same tag, and a different key gives an unrelated one.
./collections/hash.xl:163:/// @contract a fresh `SipHash13` keyed from OS entropy, so two calls (and so two tables) almost
./collections/hash.xl:164:/// @contract never share a key; the key is not reproducible and need not be.
./collections/hashmap.xl:138:    /// @contract the table owns `k` and `v`; an existing key is kept and the passed `k` is dropped.
./collections/hashset.xl:10:/// @contract every element appears at most once; two equal keys never coexist.
./collections/hashset.xl:34:    /// @contract the first insertion is kept, so a caller that re-adds an equal key does not
./collections/hashset.xl:35:    /// @contract disturb the stored one.
./collections/iter.xl:41:/// @contract the caller passes the element type and the adaptor type explicitly
./collections/iter.xl:42:/// @contract (`collect<i32, MapIter<i32, i32>>(&it)`), because neither `U` nor `I` is inferred from
./collections/iter.xl:43:/// @contract an adaptor value (see `xlang-docs/known-limitations.md`).
./collections/option.xl:40:    /// @contract the payload of a `Some`; panics on a `None` with a fixed message, because an
./collections/option.xl:41:    /// @contract optional that the caller believes present is a program error, not a value.
./collections/option.xl:51:    /// @contract the payload of a `Some`; panics on a `None` with a message ending in `msg`, which
./collections/option.xl:52:    /// @contract should name what the caller expected.
./collections/rc.xl:21:/// @contract `inner` is non-nil and `inner.strong` counts the live `Rc` handles on it.
./collections/result.xl:49:    /// @contract the success value of an `Ok`; panics on an `Err` with a fixed message, because a
./collections/result.xl:50:    /// @contract result the caller believes successful is a program error, not a value.
./collections/result.xl:60:    /// @contract the success value of an `Ok`; panics on an `Err` with a message ending in `msg`,
./collections/result.xl:61:    /// @contract which should name what the caller expected.
./collections/slice.xl:57:/// @contract `cmp` must be a consistent total order; the sort keeps equal elements in their order.
./collections/slice.xl:80:/// @contract the slice must be sorted by the order `cmp` describes, or the result is meaningless.
./collections/slice.xl:99:/// @contract only adjacent equal elements collapse, so a full dedup needs `sortSlice` first.
./collections/vec.xl:229:    /// @contract the relative order of elements that compare equal is kept, so a `sort` after a
./collections/vec.xl:230:    /// @contract `sortBy` on another field uses that field as the tiebreak.
./collections/vec.xl:242:    /// @contract `cmp` must be a consistent total order; an order that is not transitive leaves the
./collections/vec.xl:243:    /// @contract result unspecified, because the merge assumes a consistent answer.
./collections/vec.xl:314:    /// @contract the vector must be sorted by the order `cmp` describes; otherwise the result is
./collections/vec.xl:315:    /// @contract meaningless. On ties the leftmost matching index is returned.
./collections/vec.xl:333:    /// @contract `T` must not need drop: the operator takes its operand by value and drops it.
./collections/vec.xl:353:    /// @contract `T` must not need drop: the operator takes its operand by value and drops it.
./collections/vec.xl:375:    /// @contract only *adjacent* equal elements collapse, so a full dedup needs a `sort`/`sortBy`
./collections/vec.xl:376:    /// @contract first; without it the result keeps every element that differs from its predecessor.
./collections/vec.xl:377:    /// @contract `T` must not need drop: the operator takes its operand by value and drops it.
./collections/vec.xl:399:    /// @contract only adjacent elements are compared; sort by the same key first for a full dedup.
```

### @ownership (58)

```
./collections/arc.xl:20:/// @ownership dropping the last handle drops the value and frees the block.
./collections/arc.xl:68:/// @ownership `v` is moved into the block.
./collections/binaryheap.xl:73:    /// @ownership `v` is moved in.
./collections/binaryheap.xl:81:    /// @ownership the caller owns the returned element and drops it.
./collections/binaryheap.xl:99:    /// @ownership `items` is moved into the heap.
./collections/box.xl:7:/// @ownership one owner; there is no `clone`, because a copy would free the value twice.
./collections/box.xl:27:    /// @ownership `v` is moved in and is dropped by the `Box`.
./collections/box.xl:49:    /// @ownership the caller owns the returned value and drops it.
./collections/box.xl:60:/// @ownership `v` is moved in and is dropped by the returned `Box`.
./collections/btreemap.xl:76:    /// @ownership `k` is dropped when an equal key was already present; `v` replaces the old value.
./collections/btreemap.xl:94:    /// @ownership the removed key is dropped; the caller owns the returned value.
./collections/deque.xl:66:    /// @ownership `v` is moved in.
./collections/deque.xl:79:    /// @ownership `v` is moved in.
./collections/deque.xl:93:    /// @ownership the caller owns the returned element and drops it.
./collections/deque.xl:102:    /// @ownership the caller owns the returned element and drops it.
./collections/hash.xl:53:    /// @ownership `data` is borrowed for the call only and is never freed here.
./collections/hash.xl:92:/// @ownership `data` is borrowed for the call; it is never NUL-terminated, copied or freed.
./collections/hash.xl:129:/// @ownership `s` is borrowed; its bytes are hashed in place.
./collections/hash.xl:149:/// @ownership the value holds two words and owns no memory.
./collections/hash.xl:206:/// @ownership `s` is borrowed; its bytes are hashed in place.
./collections/hash.xl:212:/// @ownership `s` is borrowed; nothing is copied or freed.
./collections/hashmap.xl:32:/// @ownership the table owns every key and value it holds; `remove` moves the value out and drops
./collections/hashmap.xl:33:/// @ownership the key, and `drop` releases the slot array through the current allocator.
./collections/hashmap.xl:167:    /// @ownership the value is borrowed: it stays in the table and is invalidated by any insert
./collections/hashmap.xl:168:    /// @ownership that grows the table, so copy it out if it must outlive the next `put`.
./collections/hashmap.xl:190:    /// @ownership the returned value is moved out and owned by the caller.
./collections/hashmap.xl:239:/// @ownership the pointers borrow the table and are invalidated by the next `put` that grows it.
./collections/hashset.xl:36:    /// @ownership `k` is moved in; an already-present equal key is dropped.
./collections/hashset.xl:50:    /// @ownership the removed key is dropped.
./collections/iter.xl:17:/// @ownership `v` is borrowed; the adaptor owns nothing and stays valid only while `v` lives.
./collections/iter.xl:23:/// @ownership `v` is borrowed; the adaptor owns nothing and stays valid only while `v` lives.
./collections/iter.xl:29:/// @ownership `v` is borrowed; the adaptor owns nothing and stays valid only while `v` lives.
./collections/iter.xl:35:/// @ownership both vectors are borrowed; the adaptor owns nothing.
./collections/iter.xl:44:/// @ownership the returned vector owns its elements; the adaptor is consumed by the call.
./collections/option.xl:23:    /// @ownership `self` is borrowed, so a payload that needs drop is not dropped by the test.
./collections/option.xl:32:    /// @ownership `self` is borrowed, so a payload that needs drop is not dropped by the test.
./collections/option.xl:42:    /// @ownership the payload is moved out of `self`, which is left uninitialized and is not run
./collections/option.xl:43:    /// @ownership again, so a droppable payload is owned by the caller exactly once.
./collections/option.xl:53:    /// @ownership the payload is moved out of `self` exactly as `unwrap` moves it.
./collections/option.xl:67:    /// @ownership `self` is moved, so an unused payload is dropped here.
./collections/option.xl:112:    /// @ownership the payload is moved into `*out`; `self` is left unset and not run again.
./collections/rc.xl:22:/// @ownership dropping the last handle drops the value and frees the block.
./collections/rc.xl:67:/// @ownership `v` is moved into the block.
./collections/result.xl:32:    /// @ownership `self` is borrowed, so a payload that needs drop is not dropped by the test.
./collections/result.xl:41:    /// @ownership `self` is borrowed, so a payload that needs drop is not dropped by the test.
./collections/result.xl:51:    /// @ownership the value is moved out of `self`, and the error payload (if any) is dropped here,
./collections/result.xl:52:    /// @ownership so an `Ok` payload is owned by the caller exactly once.
./collections/result.xl:62:    /// @ownership the value is moved out exactly as `unwrap` moves it.
./collections/result.xl:147:    /// @ownership the payload is moved into `*out`; `self` is left unset and not run again.
./collections/result.xl:160:    /// @ownership the payload is moved into `*out`; `self` is left unset and not run again.
./collections/slice.xl:15:/// @ownership elements are moved through one temporary, so each is moved twice and dropped once.
./collections/slice.xl:58:/// @ownership elements are moved by swapping, never cloned, and nothing is dropped.
./collections/slice.xl:100:/// @ownership the removed elements are dropped in place, once each.
./collections/vec.xl:231:    /// @ownership the elements are moved, never cloned, so a droppable `T` is dropped exactly once.
./collections/vec.xl:244:    /// @ownership elements are moved, never cloned; `cmp` borrows each element and must not move
./collections/vec.xl:245:    /// @ownership or free it.
./collections/vec.xl:378:    /// @ownership each removed element is dropped in place, so every element is dropped once.
./collections/vec.xl:400:    /// @ownership each removed element is dropped in place, so every element is dropped once.
```

### @spec (4)

```
./collections/hash.xl:58:// @spec https://www.aumasson.jp/siphash/siphash.pdf section 2.3 for the four initial values.
./collections/hash.xl:90:/// @spec https://www.aumasson.jp/siphash/siphash.pdf section 2 for the construction; the test
./collections/hash.xl:91:/// @spec suite checks the output against the reference implementation's SipHash-1-3 vectors.
./collections/hash.xl:148:/// @spec https://www.aumasson.jp/siphash/siphash.pdf section 2 for the algorithm.
```

### @cost (96)

```
./collections/arc.xl:21:/// @cost `O(1)` clone and drop, one allocation.
./collections/arc.xl:46:    /// @cost `O(1)`.
./collections/arc.xl:55:    /// @cost `O(1)`.
./collections/arc.xl:61:    /// @cost `O(1)`.
./collections/arc.xl:69:/// @cost one allocation.
./collections/binaryheap.xl:10:/// @cost `O(log n)` per push and pop, `O(n)` to build from a vector.
./collections/binaryheap.xl:23:    /// @cost `O(1)`.
./collections/binaryheap.xl:29:    /// @cost `O(1)`.
./collections/binaryheap.xl:35:    /// @cost `O(1)`.
./collections/binaryheap.xl:42:    /// @cost `O(log n)` swaps.
./collections/binaryheap.xl:54:    /// @cost `O(log n)` swaps.
./collections/binaryheap.xl:74:    /// @cost `O(log n)`.
./collections/binaryheap.xl:82:    /// @cost `O(log n)`.
./collections/binaryheap.xl:93:    /// @cost `O(n)` drops.
./collections/binaryheap.xl:100:    /// @cost `O(n)` comparisons, cheaper than `n` pushes.
./collections/box.xl:8:/// @cost `O(1)` to create and to drop, one allocation.
./collections/box.xl:28:    /// @cost one allocation on the first `set`; the raw storage is reused after that.
./collections/box.xl:37:    /// @cost `O(1)`.
./collections/box.xl:43:    /// @cost `O(1)`.
./collections/box.xl:50:    /// @cost `O(1)` plus one free.
./collections/box.xl:61:/// @cost one allocation.
./collections/btreemap.xl:17:/// @cost `O(log n)` lookup, `O(n)` insert and remove, `O(n)` to build from sorted pairs.
./collections/btreemap.xl:30:    /// @cost `O(1)`.
./collections/btreemap.xl:36:    /// @cost `O(1)`.
./collections/btreemap.xl:42:    /// @cost `O(log n)` calls to `cmp`.
./collections/btreemap.xl:60:    /// @cost `O(log n)` calls to `cmp`.
./collections/btreemap.xl:70:    /// @cost `O(log n)` calls to `cmp`.
./collections/btreemap.xl:77:    /// @cost `O(n)` to move the later entries up by one.
./collections/btreemap.xl:95:    /// @cost `O(n)` to move the later entries down by one.
./collections/btreemap.xl:107:    /// @cost `O(1)`.
./collections/btreemap.xl:114:    /// @cost `O(1)`.
./collections/btreemap.xl:121:    /// @cost `O(n)` drops.
./collections/btreemap.xl:127:    /// @cost `O(1)` to build, one entry per round.
./collections/deque.xl:13:/// @cost `O(1)` at either end, one grow over the whole ring.
./collections/deque.xl:30:    /// @cost `O(1)`.
./collections/deque.xl:36:    /// @cost `O(1)`.
./collections/deque.xl:51:    /// @cost `O(n)` element moves.
./collections/deque.xl:67:    /// @cost `O(1)` expected, `O(n)` when the ring doubles.
./collections/deque.xl:80:    /// @cost `O(1)` expected, `O(n)` when the ring doubles.
./collections/deque.xl:94:    /// @cost `O(1)`.
./collections/deque.xl:103:    /// @cost `O(1)`.
./collections/deque.xl:113:    /// @cost `O(1)`.
./collections/deque.xl:121:    /// @cost `O(1)`.
./collections/deque.xl:129:    /// @cost `O(n)` drops.
./collections/hash.xl:93:/// @cost one pass over the input with one round per 8-byte block, then three finalization rounds;
./collections/hash.xl:94:/// @cost no allocation.
./collections/hash.xl:165:/// @cost one entropy read.
./collections/hash.xl:186:/// @cost one SipHash call, no allocation.
./collections/hash.xl:193:/// @cost one SipHash call, no allocation.
./collections/hashmap.xl:34:/// @cost a lookup is `O(1)` expected and `O(n)` only under an adversarial key stream, which the
./collections/hashmap.xl:35:/// @cost keyed hash prevents; an insert grows to twice the slots when the table passes 3/4 full,
./collections/hashmap.xl:36:/// @cost moving every live entry once (`O(n)` amortized to `O(1)` per insert).
./collections/hashmap.xl:99:    /// @cost `O(n)` moves, amortized to `O(1)` per insert over the life of the table.
./collections/hashmap.xl:139:    /// @cost `O(1)` expected, plus `O(n)` on a grow.
./collections/hashmap.xl:191:    /// @cost linear probing stops at the slot, then the following run of live slots is re-inserted
./collections/hashmap.xl:192:    /// @cost so no probe chain is broken; `O(1)` expected.
./collections/hashset.xl:11:/// @cost `O(1)` expected per operation, `O(n)` on a grow.
./collections/hashset.xl:22:    /// @cost `O(1)`.
./collections/hashset.xl:28:    /// @cost `O(1)`.
./collections/hashset.xl:37:    /// @cost `O(1)` expected, `O(n)` on a grow.
./collections/hashset.xl:44:    /// @cost `O(1)` expected.
./collections/hashset.xl:51:    /// @cost `O(1)` expected.
./collections/hashset.xl:57:    /// @cost `O(capacity)` to walk the slots, `O(n)` keys copied out.
./collections/hashset.xl:68:    /// @cost `O(1)` to build, one slot per round.
./collections/iter.xl:45:/// @cost one `Vec` grown by doubling, so `log n` reallocations for `n` elements.
./collections/option.xl:54:    /// @cost one `String` built only on the panic path, so the happy path allocates nothing.
./collections/option.xl:77:    /// @cost one move of the payload through `f`; a droppable `T` is dropped once, at the end.
./collections/rc.xl:23:/// @cost `O(1)` clone and drop, one allocation.
./collections/rc.xl:45:    /// @cost `O(1)`.
./collections/rc.xl:54:    /// @cost `O(1)`.
./collections/rc.xl:60:    /// @cost `O(1)`.
./collections/rc.xl:68:/// @cost one allocation.
./collections/result.xl:63:    /// @cost one `String` built only on the panic path, so the happy path allocates nothing.
./collections/result.xl:92:    /// @cost one move of the payload through `f`; a droppable `T` is dropped once, at the end.
./collections/slice.xl:16:/// @cost `n / 2` swaps and no allocation.
./collections/slice.xl:31:/// @cost up to `n` comparisons, stopping at the first match.
./collections/slice.xl:41:/// @cost up to `n` calls to `pred`, stopping at the first match.
./collections/slice.xl:50:/// @cost up to `n` comparisons, stopping at the first match.
./collections/slice.xl:59:/// @cost `O(n^2)` comparisons: for a slice longer than a hundred elements sort a `Vec` instead,
./collections/slice.xl:60:/// @cost whose merge sort is `n log n`.
./collections/slice.xl:81:/// @cost `log n` calls to `cmp`.
./collections/slice.xl:101:/// @cost one pass and one move per kept element.
./collections/vec.xl:232:    /// @cost `n log n` comparisons and one auxiliary buffer of `n` elements; a run of 8 or fewer
./collections/vec.xl:233:    /// @cost elements is insertion-sorted in place with no buffer.
./collections/vec.xl:246:    /// @cost `n log n` calls to `cmp` and one buffer of `n` elements; nothing is allocated for a
./collections/vec.xl:247:    /// @cost vector of 8 or fewer elements.
./collections/vec.xl:291:    /// @cost `log n` comparisons.
./collections/vec.xl:316:    /// @cost `log n` calls to `cmp`.
./collections/vec.xl:334:    /// @cost up to `n` comparisons, stopping at the first match.
./collections/vec.xl:344:    /// @cost up to `n` calls to `pred`, stopping at the first match.
./collections/vec.xl:354:    /// @cost up to `n` comparisons, stopping at the first match.
./collections/vec.xl:365:    /// @cost up to `n` calls to `pred`, stopping at the first match.
./collections/vec.xl:379:    /// @cost one pass and one move per kept element.
./collections/vec.xl:401:    /// @cost one pass and one call to `eq` per element after the first.
./str/string.xl:439:/// @cost `O(min(len))` byte comparisons.
./str/string.xl:445:/// @cost `O(min(len))` byte comparisons.
```

### @todo (17)

```
./collections/option.xl:78:    /// @todo `f` is a plain `fn(*T) -> U`, not a generic `F`, because a `U` reached only through an
./collections/option.xl:79:    /// @todo `F` parameter is not inferred (`E0724`); a capturing closure must be a named function.
./collections/result.xl:93:    /// @todo `f` is a plain `fn(*T) -> U`, not a generic `F`, because a `U` reached only through an
./collections/result.xl:94:    /// @todo `F` parameter is not inferred (`E0724`); a capturing closure must be a named function.
./collections/slice.xl:32:/// @todo needs `fn ==(T, T)`; a type without one uses `indexOfBySlice`.
./collections/slice.xl:51:/// @todo needs `fn ==(T, T)`, like `indexOfSlice`.
./collections/slice.xl:61:/// @todo this is the quadratic variant because a mutable slice has no room for the merge buffer
./collections/slice.xl:62:/// @todo the `Vec` sort allocates; a caller with many elements copies into a `Vec` first.
./collections/slice.xl:102:/// @todo needs `fn ==(T, T)` for the element type.
./collections/vec.xl:234:    /// @todo the element type needs `fn <`, found because this module imports `str/string`; a type
./collections/vec.xl:235:    /// @todo declared elsewhere without such an import does not resolve here, so it uses `sortBy`.
./collections/vec.xl:292:    /// @todo an element without `fn <` must use `binarySearchBy` with an explicit comparator.
./collections/vec.xl:335:    /// @todo needs `fn ==(T, T)` for the element type; a droppable type uses `containsBy`.
./collections/vec.xl:355:    /// @todo needs `fn ==(T, T)` for the element type; a droppable type uses `indexOfBy`.
./collections/vec.xl:380:    /// @todo needs `fn ==(T, T)` for the element type; a droppable type uses `dedupBy`.
./collections/vec.xl:426:/// @todo the language cannot declare `fn <(a: *T, b: *T)` (a pointer operator is `E0709`), and a
./collections/vec.xl:427:/// @todo generic `T` has no borrow, so this split cannot be closed inside the stdlib.
```

### @safety (6)

```
./collections/deque.xl:42:    /// @safety `i` must be below `len`; every public method bounds it first.
./collections/hash.xl:44:    /// @safety `other` must point to a value of the implementing type; a table only ever passes a
./collections/hash.xl:45:    /// @safety lookup key of the same `K`, so the cast inside an implementation is sound.
./collections/hash.xl:136:/// @safety `at + 8` must not exceed the length of `data`; the only caller tests `i + 8 <= n`.
./collections/vec.xl:435:/// @safety `i` must be within the array `p` points to; the merge below bounds it by the run end.
./collections/vec.xl:442:/// @safety `lo <= mid <= hi <= len`; `sortBy` computes the three from the pass width.
```

Total: 222 tag lines.
<!-- END COLLECTED TAGS -->
