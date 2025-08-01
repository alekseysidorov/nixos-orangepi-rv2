{
  description = "NixOS installer for Orange Pi RV2";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
          crossSystem = { system = "riscv64-linux"; };
          # Use the host system to cross-compile to riscv64
          pkgsCross = import nixpkgs {
            inherit localSystem crossSystem;
            config.allowUnfree = true;
            overlays = [ overlay ];
          };
          # Add treefmt formatter.
          pkgsLocal = import nixpkgs { inherit localSystem; };
          treefmt = treefmt-nix.lib.evalModule pkgsLocal ./treefmt.nix;

        in
        {
          # Formatter for `nix fmt`
          formatter = treefmt.config.build.wrapper;
          # Checker for `nix flake check`
          checks = {
            formatting = treefmt.config.build.check self;
          };

          packages = rec {
            # Main installer in cross compile mode
            sd-image-installer = pkgsCross.sdImageUtils.makeImage ./sd-images/sd-image-orangepi-rv2-installer.nix;
            # Flash script for the cross-compiled image
            flash-sd-image-installer = pkgsCross.sdImageUtils.makeFlashCommand sd-image-installer;
            default = sd-image-installer;
          };
        }
      )
    # System independent modules.
    // {
      # Export overlay for use in other projects
      overlays.default = overlay;
      # All nixOS modules are kept here
      nixosModules = {
        boot = import ./modules/boot.nix;
      };
    };
}
