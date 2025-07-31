{
  description = "NixOS installer for Orange Pi RV2";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
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
          # Use native riscv64-linux system for building packages.
          pkgsNative = import nixpkgs {
            system = "riscv64-linux";
            config.allowUnfree = true;
            overlays = [ overlay ];
          };

          # Add treefmt formatter.
          pkgsLocal = import nixpkgs { inherit localSystem; };
          treefmt = treefmt-nix.lib.evalModule pkgsLocal ./treefmt.nix;

          mkSdImageInstallerFor = pkgs:
            let
              sdImage = (pkgs.nixos {
                imports = [
                  ./sd-images/sd-image-orangepi-rv2-installer.nix
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

          mkFlashCommandFor = sdImage:
            pkgsLocal.writeShellScriptBin "flash-sd-image-cross" ''
              #!/${pkgsCross.runtimeShell}
              set -euo pipefail
              "${pkgsLocal.caligula}/bin/caligula" burn -z zst -s none "${sdImage}"
            '';
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
            sd-image-installer = mkSdImageInstallerFor pkgsCross;
            # Flash script for the cross-compiled image
            flash-sd-image-installer = mkFlashCommandFor sd-image-installer;
            # Main installer in native compile mode
            sd-image-native = mkSdImageInstallerFor pkgsNative;

            # Simple script for pushing to Attic dev cache (filters out nixos paths)
            attic-cache-push = pkgsLocal.writeScriptBin "attic-push-dev" ''
              #!/${pkgsLocal.runtimeShell}

              DERIVATION="./result"
              CACHE="riscv64"

              if [ ! -e "$DERIVATION" ]; then
                echo "Error: Path $DERIVATION does not exist" >&2
                exit 1
              fi

              echo "Pushing $DERIVATION to dev cache (excluding nixos paths)..."
              nix-store -qR --include-outputs "$DERIVATION" | grep -v "nixos" | attic push "$CACHE" --stdin
              echo "Done!"
            '';

            default = sd-image-installer;
          };
        }
      ) // {
      # Export overlay for use in other projects
      overlays.default = overlay;
    };
}
