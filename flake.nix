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
      # Systems that can be used to build
      supportedSystems = [ "x86_64-linux" "aarch64-darwin" "aarch64-linux" ];
      # Always cross-compile to riscv64, regardless of host system
      crossSystem = "riscv64-linux";
      nixpkgsFor = localSystem: import nixpkgs {
        inherit localSystem crossSystem;

        overlays = [ overlay ];
      };
    in
    flake-utils.lib.eachSystem supportedSystems
      (system:
        let
          # Use the host system to cross-compile to riscv64
          pkgs = nixpkgsFor system;
          # Add treefmt formatter
          treefmt = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
        in
        {
          # Formatter for `nix fmt`
          formatter = treefmt.config.build.wrapper;

          # Checker for `nix flake check`
          checks = {
            formatting = treefmt.config.build.check self;
          };

          packages = {
            # Main installer
            installer = (pkgs.nixos ({
              imports = [
                ./sd-images/sd-image-orangepi-rv2-installer.nix
              ];
            })).config.system.build.sdImage;

            # Export individual packages
            linux-orangepi-ky = pkgs.linux-orangepi-ky;
            ap6256-firmware = pkgs.ap6256-firmware;
            esos-elf-firmware = pkgs.esos-elf-firmware;

            default = self.packages.${system}.installer;
          };
        }
      ) // {
      # Export overlay for use in other projects
      overlays.default = overlay;
    };
}
