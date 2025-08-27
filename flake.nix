{
  description = "NixOS installer for Orange Pi RV2";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/94def634a20494ee057c76998843c015909d6311";
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
          # Use the emulated riscv64 system to build packages
          pkgsNative = import nixpkgs {
            localSystem = crossSystem;
            config.allowUnfree = true;
            overlays = [ overlay ];
          };

          # Build all packages for the cross-compiled system.
          buildPackagesAll = pkgs:
            pkgs.writeShellApplication {
              name = "build-packages-all";

              runtimeInputs = with pkgs; [
                esos-elf-firmware
                orangepi-xunlong-firmware
                guitarix
                westonLite
              ];

              text = '''';
            };

          pkgsLocal = import nixpkgs { inherit localSystem; };
          # Utilities to create SD images.
          sdImageUtils = {
            makeImage = configuration:
              let
                sdImage = (pkgsCross.nixos {
                  imports = [
                    configuration
                  ];
                }).config.system.build.sdImage;
              in
              pkgsLocal.stdenv.mkDerivation {
                name = "sd-image-orangepi-rv2.img.zst";
                version = "1.0.0";
                src = sdImage;

                phases = [ "installPhase" ];
                noAuditTmpdir = true;
                preferLocalBuild = true;

                installPhase = "ln -s $src/sd-image/*.img.zst $out";
              };
            # Utilites to flash SD images to devices.
            makeFlashCommand = sdImage:
              pkgsLocal.writeShellScriptBin "flash-sd-image-cross" ''
                #!/${pkgsLocal.runtimeShell}
                set -euo pipefail
                "${pkgsLocal.caligula}/bin/caligula" burn -z zst -s none "${sdImage}"
              '';
          };
          # Create treefmt configuration for formatting Nix code.
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
            default = sd-image-installer;
            # Main installer in cross compile mode.
            sd-image-installer = sdImageUtils.makeImage ./sd-images/sd-image-orangepi-rv2-installer.nix;
            # Flash script for the cross-compiled image.
            flash-sd-image-installer = sdImageUtils.makeFlashCommand sd-image-installer;
            # Build all packages for cahining.
            pkgs-all-cross = buildPackagesAll pkgsCross;
            pkgs-all-native = buildPackagesAll pkgsNative;
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
