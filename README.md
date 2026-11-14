# Slim Wine runtime for Linkspan

A slim build of upstream Wine 11.0 for 64-bit Windows programs. Wine stays under the LGPL-2.1-or-later. It is not a Windows license, and Linkspan does not use it for OpenHarmony.

The scripts here are Apache-2.0, Copyright 2026 Ye Zicheng. The Wine binaries are not committed and are not relicensed. Linkspan downloads a published GitHub Release at runtime, chooses GitHub or a China mirror from the client IP, and checks SHA-256.

The official site is https://olympium.net. Do not commit `*.tar.gz`, certificates, or keys.

## Build

```bash
./build-slim.sh
```

The script downloads `https://dl.winehq.org/wine/source/11.0/wine-11.0.tar.xz`, checks SHA-256 `c07a6857933c1fc60dff5448d79f39c92481c1e9db5aa628db9d0358446e0701`, and configures it with `--enable-archs=x86_64`. It does not vendor the Wine source. Wine Mono and Wine Gecko are not downloaded.

## What 0.1.0 contains

`wine-slim-x86_64.tar.gz` is a Linux x86_64 build. A PE32+ console program printed `linkspan-guest-ok platform=windows format=exe`. A 32-bit PE was run and failed, so this release does not claim wow64. There is no aarch64 archive. The binaries were not built or tested on macOS or Windows. OpenGL, sound, and a visible GUI window were not part of the smoke test. X11 was enabled at configure time so a GUI program can open a host window when the host has the libraries Wine loads for that.

`HOST_OS` in the archive says `linux`. Linkspan uses `bin/wine` only on a Linux host.

## Assets

- `wine-slim-x86_64.tar.gz`
