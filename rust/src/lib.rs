//! Wire messages generated from `schema/docktopus.fbs` when this crate is compiled.
//!
//! The build runs `flatc` 25.12.19. Set `FLATC` when that binary is not on `PATH`.

#[allow(dead_code, unused_imports, clippy::all)]
mod generated {
    include!(concat!(env!("OUT_DIR"), "/docktopus_generated.rs"));
}

pub use generated::docktopus::messages;
