#!/usr/bin/env bash
# Regenerates the Rust and TypeScript bindings from schema/docktopus.fbs.
# Requires flatc 25.12.19 on PATH. That is the compiler pinned by flake.nix.
# C++ headers are produced by `nix build`, which uses the same schema.

set -euo pipefail

expected="25.12.19"
root="$(cd "$(dirname "$0")/.." && pwd)"
schema="$root/schema/docktopus.fbs"

if ! command -v flatc >/dev/null 2>&1; then
  echo "flatc ${expected} is required on PATH." >&2
  echo "nix develop in this directory provides that compiler." >&2
  exit 1
fi

actual="$(flatc --version | awk '{print $NF}')"
if [[ "$actual" != "$expected" ]]; then
  echo "flatc ${expected} is required, found ${actual}." >&2
  exit 1
fi

flatc --rust --gen-mutable --gen-name-strings --require-explicit-ids \
  -o "$root/rust/src" "$schema"
flatc --ts --gen-all --gen-mutable --gen-name-strings --require-explicit-ids \
  -o "$root/typescript/src" "$schema"
