# xl-std

The standard library of the [xlang](https://github.com/hasirciogluhq/xlang) language, written in xlang. It is a plain package: a directory of `.xl` source with `index.xl` at its root, versioned by git tags. The compiler [`xlc`](https://github.com/hasirciogluhq/xlc) does not know it; the library is passed to the compiler as a module root. Documentation lives in [xlang-docs](https://github.com/hasirciogluhq/xlang-docs) (`std/`).

## Layout

```
index.xl          re-exports every area (`import "std"` gives all of it)
<area>/           one folder per area, each with its own index.xl: runtime, mem, str, collections, io, os, sys, net, tls, http, ...
  index.xl        what the area exports
  <file>.xl       the code; siblings import as "name", parents as "../name"
sys/              the only place with OS calls (syscalls, libSystem, kernel32/ntdll), one file per area, routed with `#if os`
test/
  unit/           `*.test.xl` suites (std/testing); run.sh builds and runs them
  e2e/            one program per feature; tests.txt is the table, run.sh and runner.xl run it
.github/          CI and release workflows, and the script that installs the compiler
```

The root of the repository is the root of the library, because the package system needs `index.xl` there. Tests, CI files and this README are not part of a release archive.

## Using it

```
xlc app.xl -M std=<path to this repository> --import std -DfeatureDefaultAllocator=true -o app
```

`-M std=<dir>` makes `import "std"` and `import "std/<area>"` resolve inside the directory; `--import std` loads the library so its default `register`ed functions (`alloc`, `free`, `panic`, `unwind`) and `@init` functions take part. Features are plain definitions (`-DfeatureDefaultAllocator=true`).

## Processes

`std/os/process` starts and controls child processes on Linux, macOS and Windows:

```
from "std" import String, optionIsSome, print
from "std/os/process" import Command, Stdio

@entry fn main() -> i32 {
    local git: Command = Command(String("git"))
    git.arg(String("status"))
    git.arg(String("--short"))
    git.cwd(String("/work"))
    if optionIsSome(git.output()) { return 1 }      // could not start
    print(&git.outText)                              // git.status.code is its exit status
    return 0
}
```

A `Command` holds the child: `start`, `wait`, `tryWait`, `isRunning`, `terminate`, `kill`, the pipes `inPipe` / `outPipe` / `errPipe` (`std/io/stream`, with `readLine` and `readAll`), the environment (`env`, `clearEnv`), the working directory, and redirection to a file or the null device. `id()`, `exists(pid)`, `terminate(pid)`, `kill(pid)`, `isElevated()` and `executable()` work without a child. `std/os/env` reads the environment. `std/io/stream` also gives `stdin()`.

## Tests

```
xlc index.xl --check -DfeatureDefaultAllocator=true      # type-check the whole library (add --target <triple>)
test/unit/run.sh                                         # unit suites on the host
test/e2e/run.sh                                          # end-to-end programs: host, Linux containers (Docker), Windows (CrossOver `cxrun`)
XLANG_E2E_FILTER='^process$' test/e2e/run.sh             # one program
```

Both scripts take the compiler as the first argument (default `$XLC`, then `xlc` on `PATH`). While working, run only the tests of what changed; run the whole suite once at the end.

## CI and releases

`.github/workflows/ci.yml` installs `xlc` with `.github/scripts/install-xlc.sh`: the newest **stable** release of the compiler when it has one, otherwise the newest **pre-release** (`-rc.N`). It then type-checks the library for every supported target and runs the unit and end-to-end suites on Linux (x86-64, arm64), macOS (arm64, x86-64) and Windows. While the compiler repository is private, add the repository secret `XLC_TOKEN` (a token with read access to it).

A release is a version tag: `git tag v1.2.0 && git push origin v1.2.0`. `.github/workflows/release.yml` checks the tag (`vMAJOR.MINOR.PATCH`, a suffix after `-` makes it a pre-release), runs the CI workflow, and attaches `xl-std_<version>.tar.gz` and its checksum to a GitHub release. A tag never moves.

## Contributing

The library is a pyramid (the compiler owns `str`, slices, arrays and pointers; the library builds `String`, `Vec`, `Option`, `Result` on them), signatures take `*String` and return `String`, OS code stays in `sys/`, and every OS feature is written for Linux, macOS and Windows. See [CONTRIBUTING.md](CONTRIBUTING.md), [SECURITY.md](SECURITY.md) and the [Code of Conduct](CODE_OF_CONDUCT.md).

## License

Licensed under the [Apache License, Version 2.0](LICENSE).
