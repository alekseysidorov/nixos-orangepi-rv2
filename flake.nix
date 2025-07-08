{
  description = "NixOS installer for Orange Pi RV2";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  # Nix configuration is passed via CLI arguments
  # to avoid security and trust issues

  outputs = { self, nixpkgs, flake-utils, ... }:
    let
      # Export overlay for use in other flakes
      overlay = import ./pkgs/overlay.nix;
    in
    {
      # Export overlay for use in other projects
      overlays.default = overlay;
    } //
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
          # Apply our overlay with custom packages
          overlays = [ overlay ];
        };

        lib = pkgs.lib;
      in
      {
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
    );
}
