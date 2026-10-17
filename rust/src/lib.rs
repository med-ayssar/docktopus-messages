//! Wire messages generated from `schema/docktopus.fbs`.
//!
//! `scripts/generate.sh` refreshes this crate. Building it needs Cargo and the
//! `flatbuffers` crate, and does not need Nix.

mod docktopus_generated;

pub use docktopus_generated::docktopus::messages;
