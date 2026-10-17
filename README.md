# docktopus-messages

FlatBuffers wire messages for docktopus. The schema is `schema/docktopus.fbs`.

`Region` and `Location` follow the domain types in `docktopus-core`:

| Message | Domain type | Fields |
| --- | --- | --- |
| `Code` | `core::Code` | `CoreType` and a 16-byte UUID, same byte order as `boost::uuids::uuid` |
| `Coordinates` | `core::Coordinates` | `x`, `y`, `z` |
| `Region` | `data::Region` | code, name, created and modified times, polygon points, slices, slice width, rows, columns |
| `Location` | `data::Location` | code, name, created and modified times, parent region code, row, column |

`CoreType` uses the same ordinals as `core::CoreType`: `Location` 0, `Container` 1, `Booking` 2, `Region` 3. `Container` and `Booking` are reserved. Times are Unix epoch milliseconds. Grid sizes are `uint64`. Each buffer is an `Envelope` whose payload is a `Region` or a `Location`. The file identifier is `DKTP`.

`flatc` is **25.12.19**, the FlatBuffers package from the nixpkgs pin in `flake.nix`. The Rust crate `flatbuffers` is 25.12.19. The npm package `flatbuffers` is 25.9.23, the newest release published there. The TypeScript roundtrip test runs against that runtime.

## C++

The Nix package generates the headers and installs them for other flakes to include.

```bash
nix build
```

The result is header-only:

```text
result/include/docktopus/messages/docktopus_generated.h
result/lib/cmake/docktopus-messages/docktopus-messages-config.cmake
result/lib/pkgconfig/docktopus-messages.pc
result/share/docktopus-messages/docktopus.fbs
```

`nix build` also compiles `tests/roundtrip.cpp` against those headers. `nix develop` provides `flatc` 25.12.19.

A sibling C++ flake includes this package:

```nix
inputs.docktopus-messages.url = "path:../docktopus-messages";
```

```nix
buildInputs = [
  docktopus-messages.packages.${system}.default
];
```

The package propagates the FlatBuffers headers. With CMake:

```cmake
find_package(flatbuffers REQUIRED)
find_package(docktopus-messages REQUIRED)
target_link_libraries(app PRIVATE docktopus::messages)
```

```cpp
#include <docktopus/messages/docktopus_generated.h>

docktopus::messages::RegionT region;
region.name = "yard";
```

`nixpkgs` is pinned to the same commit as `docktopus-core`, so both builds see FlatBuffers 25.12.19.

## Rust

The crate in `rust/` is a normal Cargo package. It vendors the generated file `rust/src/docktopus_generated.rs`.

```bash
cargo test --manifest-path rust/Cargo.toml
```

Another crate depends on it by path:

```toml
docktopus-messages = { path = "../docktopus-messages/rust" }
```

```rust
use docktopus_messages::messages::{Region, Location, Envelope};
```

## TypeScript

The package in `typescript/` is a normal npm package. It vendors the generated files under `typescript/src/docktopus/`.

```bash
npm install --prefix typescript
npm test --prefix typescript
```

Another package depends on it by path, after `npm run build` in `typescript/`:

```json
"docktopus-messages": "file:../docktopus-messages/typescript"
```

```typescript
import { Region, Location, Envelope } from "docktopus-messages";
```

## Regenerate Rust and TypeScript

Edit `schema/docktopus.fbs`, then run:

```bash
./scripts/generate.sh
```

The script needs `flatc` 25.12.19 on `PATH`. `nix develop` provides that binary. Keep every field `id` stable. `nix flake check` rebuilds the C++ roundtrip and diffs the committed Rust and TypeScript bindings against a fresh `flatc` run.
