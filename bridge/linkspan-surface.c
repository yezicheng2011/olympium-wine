/* Copyright 2026 Ye Zicheng
 * SPDX-License-Identifier: Apache-2.0
 * Host window bridge for a slim guest runtime.
 * It does not translate guest APIs. If no guest surface is connected,
 * it exits instead of opening an emulator frame.
 */
#include <stdio.h>

int main(int argc, char **argv) {
    (void)argc;
    (void)argv;
    fprintf(stderr, "linkspan-surface: no guest surface is connected. Refusing to open a nested emulator window.\n");
    return 1;
}
