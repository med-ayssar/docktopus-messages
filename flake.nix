{
  description = "Docktopus FlatBuffers messages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/e7439b6b14ad3cc35d05608ebca9bce01a25f5f8";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        messages = pkgs.callPackage ./package.nix { };
        # Same flatc flags as scripts/generate.sh. Fails when the committed
        # Rust or TypeScript bindings drift from schema/docktopus.fbs.
        bindings = pkgs.runCommand "docktopus-messages-bindings" {
          nativeBuildInputs = [ pkgs.flatbuffers ];
        } ''
          mkdir -p generated/schema generated/rust generated/ts
          cp ${./schema/docktopus.fbs} generated/schema/docktopus.fbs
          flatc --rust --gen-mutable --gen-name-strings --require-explicit-ids \
            -o generated/rust generated/schema/docktopus.fbs
          flatc --ts --gen-all --gen-mutable --gen-name-strings --require-explicit-ids \
            -o generated/ts generated/schema/docktopus.fbs
          diff -u ${./rust/src/docktopus_generated.rs} generated/rust/docktopus_generated.rs
          diff -ru ${./typescript/src/docktopus} generated/ts/docktopus
          touch "$out"
        '';
      in
      {
        packages = {
          default = messages;
          docktopus-messages = messages;
        };
        checks = {
          cpp = messages;
          bindings = bindings;
        };
        devShells.default = pkgs.mkShell {
          packages = [ pkgs.flatbuffers ];
        };
      }
    )
    // {
      overlays.default = final: _prev: {
        docktopus-messages = self.packages.${final.system}.default;
      };
    };
}
