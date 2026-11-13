# Plan

Open work only. Finished work lives in the code, `xlang-docs/std/` and git history.

## Now
- TLS 1.0, 1.1 and 1.2 next to 1.3, client and server, with downgrade protection (RFC 8446 4.1.3, RFC 7507).
- TLS algorithms: AES-256-GCM, AES-CCM, AES-CBC with HMAC, 3DES, ECDHE over P-256/P-384/X448, FFDHE, RSA key exchange.
- TLS features: HelloRetryRequest, ALPN, server SNI, client certificates, resumption, extended master secret, secure renegotiation.
- TLS and HTTP on `String`, `Vec` and classes.
- HTTP client per RFC 9110/9112: keep-alive and pooling, chunked request bodies, decompression, cookies (RFC 6265), proxies, `Expect: 100-continue`, an exchange timeout.
- Current syntax and base types everywhere.

## Next
- WebSocket (RFC 6455), static files and ranges, HTTP/2 (RFC 9113, 7541).
- IPv6 sockets and address types.
- Windows threads; fibers.

## Open decisions
- SSL 3.0 (forbidden by RFC 7568): not planned unless asked.
