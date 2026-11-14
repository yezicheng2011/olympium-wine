#!/bin/sh
# Copyright 2026 Ye Zicheng
# SPDX-License-Identifier: Apache-2.0
# Starts the slim runtime with no emulator window.
# Linkspan passes --display host-window, --memory, --appearance, and --share.
set -eu
display="host-window"
for arg in "$@"; do
  if [ "$arg" = "gtk" ] || [ "$arg" = "qemu-window" ]; then
    echo "Refusing a nested emulator window." >&2
    exit 2
  fi
done
echo "linkspan-runtime: display=$display (host window only)"
if ! command -v qemu-system-x86_64 >/dev/null 2>&1 && ! command -v qemu-system-aarch64 >/dev/null 2>&1; then
  echo "QEMU is not installed. Linkspan does not bundle it." >&2
  exit 1
fi
echo "Start the guest with -display none and let linkspan-surface own the window."
