use std::env;
use std::path::PathBuf;
use std::process::Command;

const FLATC_VERSION: &str = "25.12.19";

fn main() {
    let manifest_dir = PathBuf::from(env::var("CARGO_MANIFEST_DIR").expect("CARGO_MANIFEST_DIR"));
    let schema = manifest_dir.join("../schema/docktopus.fbs");
    let schema = schema.canonicalize().unwrap_or_else(|error| {
        panic!(
            "schema not found at {}: {error}",
            manifest_dir.join("../schema/docktopus.fbs").display()
        )
    });
    let out_dir = PathBuf::from(env::var("OUT_DIR").expect("OUT_DIR"));
    let flatc = env::var("FLATC").unwrap_or_else(|_| "flatc".to_string());

    println!("cargo:rerun-if-changed={}", schema.display());
    println!("cargo:rerun-if-env-changed=FLATC");

    let version = Command::new(&flatc).arg("--version").output().unwrap_or_else(|error| {
        panic!("flatc {FLATC_VERSION} is required to build docktopus-messages: {error}");
    });
    if !version.status.success() {
        panic!("flatc {FLATC_VERSION} is required to build docktopus-messages");
    }
    let version_text = String::from_utf8_lossy(&version.stdout);
    let found = version_text.split_whitespace().last().unwrap_or("");
    if found != FLATC_VERSION {
        panic!("flatc {FLATC_VERSION} is required to build docktopus-messages, found {found}");
    }

    let status = Command::new(&flatc)
        .args([
            "--rust",
            "--gen-mutable",
            "--gen-name-strings",
            "--require-explicit-ids",
            "-o",
        ])
        .arg(&out_dir)
        .arg(&schema)
        .status()
        .unwrap_or_else(|error| panic!("failed to run flatc: {error}"));
    if !status.success() {
        panic!("flatc failed to generate the Rust messages");
    }
}
