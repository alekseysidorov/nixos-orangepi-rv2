{
  description = "NixOS installer for Orange Pi RV2";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  # Nix configuration is passed via CLI arguments
  # to avoid security and trust issues

  outputs = { self, nixpkgs, flake-utils, treefmt-nix, ... }:
    let
      # Export overlay for use in other flakes
      overlay = import ./default.nix;
    in
    flake-utils.lib.eachDefaultSystem
      (localSystem:
        let
          # Always cross-compile to riscv64, regardless of host system
          crossSystem = "riscv64-linux";
          # Use the host system to cross-compile to riscv64
          pkgs = import nixpkgs {
            inherit localSystem crossSystem;

            overlays = [ overlay ];
          };

          # Add treefmt formatter.
          localPkgs = import nixpkgs { inherit localSystem; };
          treefmt = treefmt-nix.lib.evalModule localPkgs ./treefmt.nix;
        in
        {
          # Formatter for `nix fmt`
          formatter = treefmt.config.build.wrapper;

          # Checker for `nix flake check`
          checks = {
            formatting = treefmt.config.build.check self;
          };

          packages = rec {
            # Main installer
            sd-image = (pkgs.nixos {
              imports = [
                ./sd-images/sd-image-orangepi-rv2-installer.nix
              ];
            }).config.system.build.sdImage;

            # Export individual packages
            linux-orangepi-ky = pkgs.linux-orangepi-ky;
            ap6256-firmware = pkgs.ap6256-firmware;
            esos-elf-firmware = pkgs.esos-elf-firmware;

            default = sd-image;
          };
        }
      ) // {
      # Export overlay for use in other projects
      overlays.default = overlay;
    };
}
