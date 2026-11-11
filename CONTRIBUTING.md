# Contributing to xl-std

`xl-std` is licensed under the [Apache License 2.0](LICENSE). Unless you state otherwise, any contribution you submit is licensed under the same terms (Apache-2.0 §5).

## Rules

- **The library is a pyramid.** The compiler owns `str`, slices, arrays and pointers; the library builds `String`, `Vec<T>`, `Option` and `Result` on them, and everything above uses those types. Public and internal signatures take `*String` to borrow and return `String` to give; raw pointers and `str` appear only at real boundaries (syscalls, FFI, base-type internals).
- **Every feature works on Linux, macOS and Windows** (x86-64 and arm64 where the OS supports it). Where an OS cannot support it, the result is a clear compile-time error documented in `known-limitations`.
- **OS code lives in `sys/`**, one file per area, routed with `#if os`. Read the vendor documentation first and cite it in comments.
- **Layout:** `<area>/<file>.xl` with `<area>/index.xl` re-exporting the area. Names carry no module prefix.
- Use the newest syntax the language offers; if the language lacks a form you need, open an issue instead of working around it.

## Workflow

1. Fork, branch from `main`, keep the change focused.
2. Run the tests of what you changed, then the full suites once:
   ```
   xlc index.xl --check -DfeatureDefaultAllocator=true
   test/unit/run.sh
   test/e2e/run.sh
   ```
3. Add or update tests (`test/unit/*.test.xl`, `test/e2e/` and `tests.txt`) and the matching pages in [xlang-docs](https://github.com/hasirciogluhq/xlang-docs).
4. Open a pull request against `main` and fill in the template.

## Security and conduct

Report vulnerabilities privately as described in [SECURITY.md](SECURITY.md). Participation is governed by the [Code of Conduct](CODE_OF_CONDUCT.md).
