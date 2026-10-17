{
  description = "Docktopus FlatBuffers C++ messages";

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
        messages = pkgs.callPackage ./cpp/package.nix { repo = ./.; };
      in
      {
        packages = {
          default = messages;
          docktopus-messages = messages;
        };
        checks.cpp = messages;
        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.cmake
            pkgs.flatbuffers
          ];
        };
      }
    )
    // {
      overlays.default = final: _prev: {
        docktopus-messages = self.packages.${final.system}.default;
      };
    };
}
