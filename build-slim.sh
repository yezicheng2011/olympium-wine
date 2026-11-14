#!/bin/sh
# Copyright 2026 Ye Zicheng
# SPDX-License-Identifier: Apache-2.0
set -eu
echo "This script prepares the slim olympium-wine release. It does not download a guest image into Linkspan."
echo "It refuses HarmonyOS commercial images and Apple system images."
for arg in "$@"; do
  case "$arg" in
    *harmonyos*|*HarmonyOS*|*huawei.com*)
      echo "Refusing a HarmonyOS or Huawei commercial input." >&2
      exit 2
      ;;
  esac
done
echo "Follow README.md. Put the finished tarball in dist/ and do not commit it."
mkdir -p dist
printf '%s\n' "wine-slim 0.1.0" > dist/EDITION.example
