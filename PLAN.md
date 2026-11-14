# Plan

Open work only, in dependency order: each phase uses only what the phases before it deliver.
Finished work lives in the code, `xlang-docs/std/` and git history.

## 0. Language prerequisites
Check each against `xlc` and record the gap in `xlang-docs/known-limitations.md` before phase 1.
- How generic code reaches `hash`, `==` and `<` for a `T` (no constraints today): HashMap, sort and `Display` depend on it.
- Thread-local storage, for per-thread state (errno-style results, the allocator cache).

## 1. Core types
- `Option` and `Result` methods: `isNone`, `unwrap`, `expect`, `map`, `andThen`, `okOr`; remove the free `optionOrElse` / `resultIsOk` family.
- Hashing: one hash interface plus SipHash-1-3 as the default (HashDoS-resistant); FNV stays for checksums.
- `HashMap<K, V>`, `HashSet<T>`.
- Slice and `Vec` algorithms: `sort`, `sortBy` (stable), `binarySearch`, `reverse`, `dedup`, `contains`, `indexOf`.
- Iterator adaptors: `map`, `filter`, `enumerate`, `zip`, `collect`.
- `Deque` (ring buffer), `BinaryHeap`, `BTreeMap` (ordered, deterministic output).
- `Box`, `Rc`, `Arc`.
- Export `checksum` from `src/index.xl`.

## 2. Text
- `String` methods for what exists only as free `str` functions: `split`, `trim`, `lines`; add `join`.
- Character classes (`isDigit`, `isAlpha`, `isHex`, ...) in `str`; remove the private copies in `dns`, `json` and the other modules.
- Unicode on `String`: codepoint iteration and length; `utf8*` functions take `*String`.
- Float parsing (`toF64`, correctly rounded).
- Format specifiers: width, fill, alignment, precision, hex/binary (`{:08x}`, `{:.3}`).
- A `Display` interface so user types format through `{}`.
- A writer interface that `FmtSink`, `String` and files implement.

## 3. Time
- `Duration` and monotonic `Instant` (`now`, `elapsed`).
- `sleep(Duration)` on all three OSes.
- Local time zone: find and load the system zone through `tzifParse`.
- RFC 1123 / HTTP-date and strftime-style format and parse; RFC 3339 on `String`.

## 4. Concurrency
- Atomic types (`AtomicBool`, `AtomicU32`, `AtomicU64`, `AtomicPtr`) over the builtins.
- `Mutex<T>` and `RwLock<T>` with guards; remove the raw `mutexLock`/`mutexUnlock` struct API.
- Thread spawn from a closure with a joinable result; remove `threadStart(fn(*void), *void)`.
- Channel (mpsc), `WaitGroup`, `Semaphore`, `Barrier`.
- Thread pool.
- Run Windows threads (`CreateThread`, `WaitOnAddress`) under Wine / real Windows and set the `threads` Windows column.

## 5. IO and file system
- `Reader` / `Writer` interfaces; `io.copy`.
- `File` class: open modes, read, write, seek, flush, close.
- `BufReader`, `BufWriter`; `stdout()` / `stderr()` objects, buffered `print`.
- Path module: `join`, `parent`, `fileName`, `extension`, `normalize`, `relative`, per-OS separators.
- `copyFile`, recursive `walkDir`, `tempFile`, `tempDir`.
- Remove the `fs*` family (`*u8` paths); `files.*` on `*String` is the only file API.
- Compression and archive on `Reader` / `Writer` (streaming gzip, tar).

## 6. OS
- Signal handling (SIGINT, SIGTERM; `SetConsoleCtrlHandler` on Windows).
- Public `exit(code)`.
- Home, config and cache directories (XDG, `~/Library`, `%APPDATA%`); hostname, user name.
- `env.set` / `env.remove` on the real process environment.
- Command-line flag parser.
- Logging: levels, targets, structured fields.

## 7. Network
- `IpAddr` / `SocketAddr` with parse and format, IPv4 and IPv6.
- `TcpStream`, `TcpListener`, `UdpSocket` classes implementing `Reader` / `Writer`; IPv6 sockets.
- Connect timeout, non-blocking connect, `setNoDelay`, keepalive, UDP `sendTo` / `recvFrom`.
- DNS on `String`: AAAA, CNAME, MX, TXT.
- Public event loop over the existing `sysPoll*` (epoll, kqueue, IOCP).

## 8. Encoding
- JSON value tree (`parse` → `JsonValue`, serialize); one JSON module, remove `json.xl` (`*u8`).
- CSV writer; `csvRecord` on `*String`.
- URL encoding and query strings in `encoding` (moved out of `http/url`).
- INI and `.env`; YAML and XML later.

## 9. TLS
- Public API and record/handshake buffers on `String`, `Vec` and the phase 5 streams (`tlsConnect`, `tlsRead`, `tlsWrite`, credential loaders).
- TLS 1.3: HelloRetryRequest; P-256 / P-384 key shares.
- ALPN (RFC 7301); server-side SNI with several certificates; client certificates.
- Session resumption: 1.3 PSK tickets, 1.2 tickets (RFC 5077).
- AES-CCM suites; Ed25519 certificates.

## 10. HTTP
- Client per RFC 9110/9112: keep-alive and pooling, chunked request bodies, decompression, cookies (RFC 6265), proxies, `Expect: 100-continue`, an exchange timeout.
- Static files and range requests.
- WebSocket (RFC 6455).
- HTTP/2 (RFC 9113, 7541; needs ALPN).

## Later
- Regex.
- File locking, mmap, file watching (inotify, FSEvents, `ReadDirectoryChangesW`).
- `random` distributions (normal, exponential) and `choose` / `sample`.
- Math: `Complex`, statistics, `f32` variants.
- `testing`: generic `expectEq<T>`, benchmarks.

## Decisions
- TLS older than 1.2, RSA key transport, FFDHE and CBC suites stay out, as in rustls (RFC 8996 deprecates TLS 1.0 and 1.1).
- No TLS 1.3 0-RTT (replay risk, RFC 8446 section 8).
