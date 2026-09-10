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
              # Minimal needed stuff
              nftables
              tcpdump
              ethtool
              nmap
              tmux

              # Other packages for convenient development.
              fish
              nushell
              git
              vim-full
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
