{
  description = "NixOS installer for Orange Pi RV2";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "riscv64-linux" ] (system:
      let
        isCross = system != "riscv64-linux";
        localSystem = if isCross then { system = "x86_64-linux"; } else { system = "riscv64-linux"; };
        crossSystem = if isCross then { system = "riscv64-linux"; } else null;

        pkgs = import nixpkgs {
          inherit localSystem;
          crossSystem = crossSystem;
          config = {
            allowUnfree = true;
          };
        };

        lib = pkgs.lib;
      in
      {
        packages = {
          installer = (pkgs.nixos {
            modules = [
              ./sd-image-orangepi-rv2-installer.nix
            ];
          }).config.system.build.sdImage;

          default = self.packages.${system}.installer;
        };
      }
    );
}
