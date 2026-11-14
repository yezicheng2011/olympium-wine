# Slim Wine runtime for Linkspan

A slim Wine build for Windows programs. Wine stays under the Wine license. It is not a Windows license, and Linkspan does not use it for OpenHarmony.

The scripts here are Apache-2.0, Copyright 2026 Ye Zicheng. The image they build is not committed. Linkspan downloads a published GitHub Release of this repository at runtime. A China mirror is selected by Linkspan from the client IP. The mirror must serve the same bytes. Linkspan checks SHA-256.

The official site is https://olympium.net. Do not commit `*.img`, `*.tar.gz`, certificates, or keys.

## Build

```bash
./build-slim.sh
```


1. Build upstream Wine for the host architecture. Do not vendor the Wine source in this repository.
2. Pack `bin/wine` and an empty prefix into the asset named below.
3. Do not enable a virtual desktop. Windows should open as host windows.
4. Do not include a Windows system image or a product key.


After a build, fill `sha256` in `runtime-lock.json`, set `"published": true` in this file and in Linkspan's `share/runtime-lock.json`, tag `v0.1.0`, and attach the `.tar.gz` assets to the GitHub Release. Until that release exists, Linkspan reports that the image is not published.

## Assets

- `wine-slim-x86_64.tar.gz`
- `wine-slim-aarch64.tar.gz`
