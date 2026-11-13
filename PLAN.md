# Plan

Open work only. Finished work lives in the code, `xlang-docs/std/` and git history.

## Now
- TLS and HTTP on `String`, `Vec` and classes: the public TLS calls (`tlsConnect`, `tlsRead`, `tlsWrite`, the credential loaders) and the record and handshake buffers still take `*u8` + length.
- TLS 1.3: HelloRetryRequest, and P-256/P-384 key shares (TLS 1.2 already has both curves).
- TLS features: ALPN (RFC 7301), server-side SNI with several certificates, client certificates, session resumption (1.3 PSK tickets, 1.2 tickets per RFC 5077), AES-CCM suites.
- HTTP client per RFC 9110/9112: keep-alive and pooling, chunked request bodies, decompression, cookies (RFC 6265), proxies, `Expect: 100-continue`, an exchange timeout.
- Current syntax and base types everywhere.

## Next
- WebSocket (RFC 6455), static files and ranges, HTTP/2 (RFC 9113, 7541; needs ALPN).
- IPv6 sockets and address types (TLS and HTTP included).
- Windows threads; fibers.
- Ed25519 certificates in TLS; 0-RTT only if a real user asks (replay risk, RFC 8446 section 8).

## Open decisions
- TLS older than 1.2, RSA key transport, FFDHE and CBC suites stay out, as in rustls (RFC 8996 deprecates TLS 1.0 and 1.1).
