{
  description = "NixOS installer for Orange Pi RV2";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    nix-devtools = {
      url = "github:alekseysidorov/nix-devtools";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
      inputs.treefmt-nix.follows = "treefmt-nix";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # Nix configuration is passed via CLI arguments
  # to avoid security and trust issues
  outputs =
    {
      self,
      flake-parts,
      ...
    }@inputs:
    let
      localOverlay = import ./pkgs;
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      # Declared systems that your flake supports. These will be enumerated in perSystem
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
        "riscv64-linux"
      ];
      imports = [
        inputs.treefmt-nix.flakeModule
        inputs.nix-devtools.flakeModule
      ];

      flake = {
        overlays.default = localOverlay;
      };

      perSystem =
        {
          config,
          system,
          ...
        }:
        let
          pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [
              localOverlay
              inputs.nix-devtools.overlays.default
            ];
          };
          patchedNixpkgs = pkgs.applyPatches {
            # Keep the qemu change local to the Darwin builder. The regular
            # nixpkgs used by the image and cross-package checks stays intact.
            name = "nixpkgs-qemu-riscv64-darwin";
            src = inputs.nixpkgs;
            patches = [ ./patches/qemu-riscv64-darwin.patch ];
          };
          patchedPkgs = import patchedNixpkgs {
            inherit system;
            overlays = [
              localOverlay
              inputs.nix-devtools.overlays.default
            ];
          };
        in
        {
          # Use the common overlay in all per-system modules.
          _module.args.pkgs = pkgs;

          # Expose build artifacts and project commands through `nix build` / `nix run`.
          packages = {
            sd-image-installer =
              (pkgs.nixos {
                imports = [
                  ./sd-image-installer.nix
                ];
              }).config.system.build.sdImage;

            flash-sd-image = pkgs.makeFlashCommand { sdImage = config.packages.sd-image-installer; };
          }
          // pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
            # Linux hosts build the generic RISC-V NixOS VM directly through
            # pkgs.nixos, so the current Linux system is its build platform.
            linux-builder-riscv64 = pkgs.linux-builder-riscv64;
          }
          // pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
            # Darwin needs nixpkgs' macOS launcher and the local QEMU patch;
            # keep this implementation separate from the generic Linux VM.
            linux-builder-riscv64 = patchedPkgs.darwin.linux-builder.override {
              modules = [
                {
                  nixpkgs.buildPlatform = "aarch64-linux";
                  nixpkgs.hostPlatform = "riscv64-linux";

                  virtualisation.useBootLoader = false;
                  boot.loader.grub.enable = false;
                }
              ];
            };
          };

          # Share formatting rules between `nix fmt` and CI.
          treefmt = {
            projectRootFile = "flake.nix";
            programs = {
              nixfmt = {
                enable = true;
                package = pkgs.nixfmt-rs;
              };
              taplo.enable = true;
            };
          };

          checks = {
            # Curated list of cross-compiled packages.
            inherit (pkgs.pkgsCross.riscv64)
              # Basic utilities
              coreutils
              findutils
              perl

              # Minimal needed stuff
              nftables
              iproute2
              wireguard-tools
              curl
              openssl
              python3
              tcpdump
              ethtool
              nmap
              tmux
              ssh-to-age
              rage

              # Some transitive stuff
              bcachefs-tools

              # Other packages for convenient development.
              fish
              nushell
              git
              vim-full

              # singbox-dependencies
              sing-box
              ;
            amneziawg = pkgs.linuxPackages_testing.amneziawg;
          };

          # Install explicitly with `nix run .#install-git-hooks`.
          gitHooks = {
            pre-commit = pkgs.writeNushellScript "pre-commit" ''
              print "⚡️ Running pre-commit checks..."
              nix build .#checks.${system}.treefmt -L
            '';
            pre-push = pkgs.writeNushellScript "pre-push" ''
              print "⚡️ Running pre-push checks..."
              nix flake check -L
            '';
          };
        };
    };
}
